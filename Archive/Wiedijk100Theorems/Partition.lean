/-
Copyright (c) 2020 Bhavik Mehta, Aaron Anderson. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta, Aaron Anderson
-/
import Mathlib.Algebra.Order.Antidiag.Finsupp
import Mathlib.Algebra.Order.Ring.Abs
import Mathlib.Combinatorics.Enumerative.Partition
import Mathlib.Data.Finset.NatAntidiagonal
import Mathlib.Data.Fin.Tuple.NatAntidiagonal
import Mathlib.RingTheory.PowerSeries.Inverse
import Mathlib.RingTheory.PowerSeries.Order
import Mathlib.Tactic.ApplyFun
import Mathlib.Tactic.IntervalCases

/-!
# Euler's Partition Theorem

This file proves Theorem 45 from the [100 Theorems List](https://www.cs.ru.nl/~freek/100/).

The theorem concerns the counting of integer partitions -- ways of
writing a positive integer `n` as a sum of positive integer parts.

Specifically, Euler proved that the number of integer partitions of `n`
into *distinct* parts equals the number of partitions of `n` into *odd*
parts.

## Proof outline

The proof is based on the generating functions for odd and distinct partitions, which turn out to be
equal:

$$\prod_{i=0}^\infty \frac {1}{1-X^{2i+1}} = \prod_{i=0}^\infty (1+X^{i+1})$$

In fact, we do not take a limit: it turns out that comparing the `n`'th coefficients of the partial
products up to `m := n + 1` is sufficient.

In particular, we

1. define the partial product for the generating function for odd partitions `partialOddGF m` :=
  $$\prod_{i=0}^m \frac {1}{1-X^{2i+1}}$$;
2. prove `oddGF_prop`: if `m` is big enough (`m * 2 > n`), the partial product's coefficient counts
  the number of odd partitions;
3. define the partial product for the generating function for distinct partitions
  `partialDistinctGF m` := $$\prod_{i=0}^m (1+X^{i+1})$$;
4. prove `distinctGF_prop`: if `m` is big enough (`m + 1 > n`), the `n`th coefficient of the
  partial product counts the number of distinct partitions of `n`;
5. prove `same_coeffs`: if m is big enough (`m ≥ n`), the `n`th coefficient of the partial products
  are equal;
6. combine the above in `partition_theorem`.

## References
https://en.wikipedia.org/wiki/Partition_(number_theory)#Odd_parts_and_distinct_parts
-/


open PowerSeries

namespace Theorems100

noncomputable section

variable {α : Type*}

open Finset

/-- The partial product for the generating function for odd partitions.
TODO: As `m` tends to infinity, this converges (in the `X`-adic topology).

If `m` is sufficiently large, the `i`th coefficient gives the number of odd partitions of the
natural number `i`: proved in `oddGF_prop`.
It is stated for an arbitrary field `α`, though it usually suffices to use `ℚ` or `ℝ`.
-/
def partialOddGF (m : ℕ) [Field α] :=
  ∏ i ∈ range m, (1 - (X : PowerSeries α) ^ (2 * i + 1))⁻¹

/-- The partial product for the generating function for distinct partitions.
TODO: As `m` tends to infinity, this converges (in the `X`-adic topology).

If `m` is sufficiently large, the `i`th coefficient gives the number of distinct partitions of the
natural number `i`: proved in `distinctGF_prop`.
It is stated for an arbitrary commutative semiring `α`, though it usually suffices to use `ℕ`, `ℚ`
or `ℝ`.
-/
def partialDistinctGF (m : ℕ) [CommSemiring α] :=
  ∏ i ∈ range m, (1 + (X : PowerSeries α) ^ (i + 1))

open Finset.HasAntidiagonal

universe u
variable {ι : Type u}

open scoped Classical in
/-- A convenience constructor for the power series whose coefficients indicate a subset. -/
def indicatorSeries (α : Type*) [Semiring α] (s : Set ℕ) : PowerSeries α :=
  PowerSeries.mk fun n => if n ∈ s then 1 else 0

theorem coeff_indicator (s : Set ℕ) [Semiring α] (n : ℕ) [Decidable (n ∈ s)] :
    coeff α n (indicatorSeries _ s) = if n ∈ s then 1 else 0 := by
  convert coeff_mk _ _

theorem coeff_indicator_pos (s : Set ℕ) [Semiring α] (n : ℕ) (h : n ∈ s) [Decidable (n ∈ s)] :
    coeff α n (indicatorSeries _ s) = 1 := by rw [coeff_indicator, if_pos h]

theorem coeff_indicator_neg (s : Set ℕ) [Semiring α] (n : ℕ) (h : n ∉ s) [Decidable (n ∈ s)] :
    coeff α n (indicatorSeries _ s) = 0 := by rw [coeff_indicator, if_neg h]

theorem constantCoeff_indicator (s : Set ℕ) [Semiring α] [Decidable (0 ∈ s)] :
    constantCoeff α (indicatorSeries _ s) = if 0 ∈ s then 1 else 0 := by
  simp [indicatorSeries]

theorem two_series (i : ℕ) [Semiring α] :
    1 + (X : PowerSeries α) ^ i.succ = indicatorSeries α {0, i.succ} := by
  ext n
  simp only [coeff_indicator, coeff_one, coeff_X_pow, Set.mem_insert_iff, Set.mem_singleton_iff,
    map_add]
  rcases n with - | d
  · simp
  · simp

theorem num_series' [Field α] (i : ℕ) :
    (1 - (X : PowerSeries α) ^ (i + 1))⁻¹ = indicatorSeries α {k | i + 1 ∣ k} := by
  rw [PowerSeries.inv_eq_iff_mul_eq_one]
  · ext n
    cases n with
    | zero => simp [mul_sub, zero_pow, constantCoeff_indicator]
    | succ n =>
      simp only [coeff_one, if_false, mul_sub, mul_one, coeff_indicator,
        LinearMap.map_sub, reduceCtorEq]
      simp_rw [coeff_mul, coeff_X_pow, coeff_indicator, @boole_mul _ _ _ _]
      rw [sum_ite, sum_ite]
      simp_rw [@filter_filter _ _ _ _ _, sum_const_zero, add_zero, sum_const, nsmul_eq_mul, mul_one,
        sub_eq_iff_eq_add, zero_add]
      symm
      split_ifs with h
      · suffices #{a ∈ antidiagonal (n + 1) | i + 1 ∣ a.fst ∧ a.snd = i + 1} = 1 by
          simp only [Set.mem_setOf_eq]; convert congr_arg ((↑) : ℕ → α) this; norm_cast
        rw [card_eq_one]
        obtain ⟨p, hp⟩ := h
        refine ⟨((i + 1) * (p - 1), i + 1), ?_⟩
        ext ⟨a₁, a₂⟩
        simp only [mem_filter, Prod.mk_inj, mem_antidiagonal, mem_singleton]
        constructor
        · rintro ⟨a_left, ⟨a, rfl⟩, rfl⟩
          refine ⟨?_, rfl⟩
          rw [Nat.mul_sub_left_distrib, ← hp, ← a_left, mul_one, Nat.add_sub_cancel]
        · rintro ⟨rfl, rfl⟩
          match p with
          | 0 => rw [mul_zero] at hp; cases hp
          | p + 1 => rw [hp]; simp [mul_add]
      · suffices #{a ∈ antidiagonal (n + 1) | i + 1 ∣ a.fst ∧ a.snd = i + 1} = 0 by
          simp only [Set.mem_setOf_eq]; convert congr_arg ((↑) : ℕ → α) this; norm_cast
        rw [card_eq_zero]
        apply eq_empty_of_forall_notMem
        simp only [Prod.forall, mem_filter, not_and, mem_antidiagonal]
        rintro _ h₁ h₂ ⟨a, rfl⟩ rfl
        apply h
        simp [← h₂]
  · simp [zero_pow]

def mkOdd : ℕ ↪ ℕ :=
  ⟨fun i => 2 * i + 1, fun x y h => by linarith⟩

open scoped Classical in
-- The main workhorse of the partition theorem proof.
theorem partialGF_prop (α : Type*) [CommSemiring α] (n : ℕ) (s : Finset ℕ) (hs : ∀ i ∈ s, 0 < i)
    (c : ℕ → Set ℕ) (hc : ∀ i, i ∉ s → 0 ∈ c i) :
    #{p : n.Partition | (∀ j, p.parts.count j ∈ c j) ∧ ∀ j ∈ p.parts, j ∈ s} =
      coeff α n (∏ i ∈ s, indicatorSeries α ((· * i) '' c i)) := by
  simp_rw [coeff_prod, coeff_indicator, prod_boole, sum_boole]
  apply congr_arg
  simp only [Set.mem_image]
  set φ : (a : Nat.Partition n) →
    a ∈ filter (fun p ↦ (∀ (j : ℕ), Multiset.count j p.parts ∈ c j) ∧ ∀ j ∈ p.parts, j ∈ s) univ →
    ℕ →₀ ℕ := fun p _ => {
      toFun := fun i => Multiset.count i p.parts • i
      support := Finset.filter (fun i => i ≠ 0) p.parts.toFinset
      mem_support_toFun := fun a => by
        simp only [smul_eq_mul, ne_eq, mul_eq_zero, Multiset.count_eq_zero]
        rw [not_or, not_not]
        simp only [Multiset.mem_toFinset, mem_filter] }
  refine Finset.card_bij φ ?_ ?_ ?_
  · intro a ha
    simp only [φ, mem_filter]
    rw [mem_finsuppAntidiag]
    dsimp only [ne_eq, smul_eq_mul, id_eq, eq_mpr_eq_cast, le_eq_subset, Finsupp.coe_mk]
    simp only [mem_univ, mem_filter, true_and] at ha
    refine ⟨⟨?_, fun i ↦ ?_⟩, fun i _ ↦ ⟨a.parts.count i, ha.1 i, rfl⟩⟩
    · conv_rhs => simp [← a.parts_sum]
      rw [sum_multiset_count_of_subset _ s]
      · simp only [smul_eq_mul]
      · intro i
        simp only [Multiset.mem_toFinset]
        apply ha.2
    · simp only [Multiset.mem_toFinset, mem_filter, and_imp]
      exact fun hi _ ↦ ha.2 i hi
  · dsimp only
    intro p₁ hp₁ p₂ hp₂ h
    apply Nat.Partition.ext
    simp only [true_and, mem_univ, mem_filter] at hp₁ hp₂
    ext i
    simp only [φ, ne_eq, smul_eq_mul, Finsupp.mk.injEq] at h
    by_cases hi : i = 0
    · rw [hi]
      rw [Multiset.count_eq_zero_of_notMem]
      · rw [Multiset.count_eq_zero_of_notMem]
        intro a; exact Nat.lt_irrefl 0 (hs 0 (hp₂.2 0 a))
      intro a; exact Nat.lt_irrefl 0 (hs 0 (hp₁.2 0 a))
    · rw [← mul_left_inj' hi]
      rw [funext_iff] at h
      exact h.2 i
  · simp only [φ, mem_filter, mem_finsuppAntidiag, mem_univ, exists_prop, true_and, and_assoc]
    rintro f ⟨hf, hf₃, hf₄⟩
    have hf' : f ∈ finsuppAntidiag s n := mem_finsuppAntidiag.mpr ⟨hf, hf₃⟩
    simp only [mem_finsuppAntidiag] at hf'
    refine ⟨⟨∑ i ∈ s, Multiset.replicate (f i / i) i, ?_, ?_⟩, ?_, ?_, ?_⟩
    · intro i hi
      simp only [mem_sum] at hi
      rcases hi with ⟨t, ht, z⟩
      apply hs
      rwa [Multiset.eq_of_mem_replicate z]
    · simp_rw [Multiset.sum_sum, Multiset.sum_replicate, Nat.nsmul_eq_mul]
      rw [← hf'.1]
      refine sum_congr rfl fun i hi => Nat.div_mul_cancel ?_
      rcases hf₄ i hi with ⟨w, _, hw₂⟩
      rw [← hw₂]
      exact dvd_mul_left _ _
    · intro i
      simp_rw [Multiset.count_sum', Multiset.count_replicate, sum_ite_eq']
      split_ifs with h
      · rcases hf₄ i h with ⟨w, hw₁, hw₂⟩
        rwa [← hw₂, Nat.mul_div_cancel _ (hs i h)]
      · exact hc _ h
    · intro i hi
      rw [mem_sum] at hi
      rcases hi with ⟨j, hj₁, hj₂⟩
      rwa [Multiset.eq_of_mem_replicate hj₂]
    · ext i
      simp_rw [Multiset.count_sum', Multiset.count_replicate, sum_ite_eq']
      simp only [ne_eq, smul_eq_mul, ite_mul, zero_mul, Finsupp.coe_mk]
      split_ifs with h
      · apply Nat.div_mul_cancel
        rcases hf₄ i h with ⟨w, _, hw₂⟩
        apply Dvd.intro_left _ hw₂
      · apply symm
        rw [← Finsupp.notMem_support_iff]
        exact notMem_mono hf'.2 h

theorem partialOddGF_prop [Field α] (n m : ℕ) :
    #{p : n.Partition | ∀ j ∈ p.parts, j ∈ (range m).map mkOdd} = coeff α n (partialOddGF m) := by
  rw [partialOddGF]
  convert partialGF_prop α n
    ((range m).map mkOdd) _ (fun _ => Set.univ) (fun _ _ => trivial) using 2
  · congr
    simp only [true_and, forall_const, Set.mem_univ]
  · rw [Finset.prod_map]
    simp_rw [num_series']
    congr! 2 with x
    ext k
    constructor
    · rintro ⟨p, rfl⟩
      refine ⟨p, ⟨⟩, ?_⟩
      apply mul_comm
    rintro ⟨a_w, -, rfl⟩
    apply Dvd.intro_left a_w rfl
  · intro i
    rw [mem_map]
    rintro ⟨a, -, rfl⟩
    exact Nat.succ_pos _

/-- If m is big enough, the partial product's coefficient counts the number of odd partitions -/
theorem oddGF_prop [Field α] (n m : ℕ) (h : n < m * 2) :
    #(Nat.Partition.odds n) = coeff α n (partialOddGF m) := by
  rw [← partialOddGF_prop, Nat.Partition.odds]
  congr with p
  apply forall₂_congr
  intro i hi
  have hin : i ≤ n := by
    simpa [p.parts_sum] using Multiset.single_le_sum (fun _ _ => Nat.zero_le _) _ hi
  simp only [mkOdd, mem_range, Function.Embedding.coeFn_mk, mem_map]
  constructor
  · intro hi₂
    have := Nat.mod_add_div i 2
    rw [Nat.not_even_iff] at hi₂
    rw [hi₂, add_comm] at this
    refine ⟨i / 2, ?_, this⟩
    rw [Nat.div_lt_iff_lt_mul zero_lt_two]
    exact lt_of_le_of_lt hin h
  · rintro ⟨a, -, rfl⟩
    rw [even_iff_two_dvd]
    apply Nat.two_not_dvd_two_mul_add_one

theorem partialDistinctGF_prop [CommSemiring α] (n m : ℕ) :
    #{p : n.Partition |
        p.parts.Nodup ∧ ∀ j ∈ p.parts, j ∈ (range m).map ⟨Nat.succ, Nat.succ_injective⟩} =
      coeff α n (partialDistinctGF m) := by
  rw [partialDistinctGF]
  convert partialGF_prop α n
    ((range m).map ⟨Nat.succ, Nat.succ_injective⟩) _ (fun _ => {0, 1}) (fun _ _ => Or.inl rfl)
    using 2
  · congr! with p
    rw [Multiset.nodup_iff_count_le_one]
    congr! 1 with i
    rcases Multiset.count i p.parts with (_ | _ | ms) <;> simp
  · simp_rw [Finset.prod_map, two_series]
    congr with i
    simp [Set.image_pair]
  · simp only [mem_map, Function.Embedding.coeFn_mk]
    rintro i ⟨_, _, rfl⟩
    apply Nat.succ_pos

/-- If m is big enough, the partial product's coefficient counts the number of distinct partitions
-/
theorem distinctGF_prop [CommSemiring α] (n m : ℕ) (h : n < m + 1) :
    #(Nat.Partition.distincts n) = coeff α n (partialDistinctGF m) := by
  rw [← partialDistinctGF_prop, Nat.Partition.distincts]
  congr with p
  apply (and_iff_left _).symm
  intro i hi
  have : i ≤ n := by
    simpa [p.parts_sum] using Multiset.single_le_sum (fun _ _ => Nat.zero_le _) _ hi
  simp only [mem_range, Function.Embedding.coeFn_mk, mem_map]
  refine ⟨i - 1, ?_, Nat.succ_pred_eq_of_pos (p.parts_pos hi)⟩
  rw [tsub_lt_iff_right (Nat.one_le_iff_ne_zero.mpr (p.parts_pos hi).ne')]
  exact lt_of_le_of_lt this h

/-- The key proof idea for the partition theorem, showing that the generating functions for both
sequences are ultimately the same (since the factor converges to 0 as m tends to infinity).
It's enough to not take the limit though, and just consider large enough `m`.
-/
theorem same_gf [Field α] (m : ℕ) :
    (partialOddGF m * (range m).prod fun i => 1 - (X : PowerSeries α) ^ (m + i + 1)) =
      partialDistinctGF m := by
  rw [partialOddGF, partialDistinctGF]
  induction m with
  | zero => simp
  | succ m ih => ?_
  set! π₀ : PowerSeries α := ∏ i ∈ range m, (1 - X ^ (m + 1 + i + 1)) with hπ₀
  set! π₁ : PowerSeries α := ∏ i ∈ range m, (1 - X ^ (2 * i + 1))⁻¹ with hπ₁
  set! π₂ : PowerSeries α := ∏ i ∈ range m, (1 - X ^ (m + i + 1)) with hπ₂
  set! π₃ : PowerSeries α := ∏ i ∈ range m, (1 + X ^ (i + 1)) with hπ₃
  rw [← hπ₃] at ih
  have h : constantCoeff α (1 - X ^ (2 * m + 1)) ≠ 0 := by
    rw [RingHom.map_sub, RingHom.map_pow, constantCoeff_one, constantCoeff_X,
      zero_pow (2 * m).succ_ne_zero, sub_zero]
    exact one_ne_zero
  calc
    (∏ i ∈ range (m + 1), (1 - X ^ (2 * i + 1))⁻¹) *
          ∏ i ∈ range (m + 1), (1 - X ^ (m + 1 + i + 1)) =
        π₁ * (1 - X ^ (2 * m + 1))⁻¹ * (π₀ * (1 - X ^ (m + 1 + m + 1))) := by
      rw [prod_range_succ _ m, ← hπ₁, prod_range_succ _ m, ← hπ₀]
    _ = π₁ * (1 - X ^ (2 * m + 1))⁻¹ * (π₀ * ((1 + X ^ (m + 1)) * (1 - X ^ (m + 1)))) := by
      rw [← sq_sub_sq, one_pow, add_assoc _ m 1, ← two_mul (m + 1), pow_mul']
    _ = π₀ * (1 - X ^ (m + 1)) * (1 - X ^ (2 * m + 1))⁻¹ * (π₁ * (1 + X ^ (m + 1))) := by ring
    _ =
        (∏ i ∈ range (m + 1), (1 - X ^ (m + 1 + i))) * (1 - X ^ (2 * m + 1))⁻¹ *
          (π₁ * (1 + X ^ (m + 1))) := by
      rw [prod_range_succ', add_zero, hπ₀]; simp_rw [← add_assoc]
    _ = π₂ * (1 - X ^ (m + 1 + m)) * (1 - X ^ (2 * m + 1))⁻¹ * (π₁ * (1 + X ^ (m + 1))) := by
      rw [add_right_comm, hπ₂, ← prod_range_succ]; simp_rw [add_right_comm]
    _ = π₂ * (1 - X ^ (2 * m + 1)) * (1 - X ^ (2 * m + 1))⁻¹ * (π₁ * (1 + X ^ (m + 1))) := by
      rw [two_mul, add_right_comm _ m 1]
    _ = (1 - X ^ (2 * m + 1)) * (1 - X ^ (2 * m + 1))⁻¹ * π₂ * (π₁ * (1 + X ^ (m + 1))) := by ring
    _ = π₂ * (π₁ * (1 + X ^ (m + 1))) := by rw [PowerSeries.mul_inv_cancel _ h, one_mul]
    _ = π₁ * π₂ * (1 + X ^ (m + 1)) := by ring
    _ = π₃ * (1 + X ^ (m + 1)) := by rw [ih]
    _ = _ := by rw [prod_range_succ]

theorem same_coeffs [Field α] (m n : ℕ) (h : n ≤ m) :
    coeff α n (partialOddGF m) = coeff α n (partialDistinctGF m) := by
  rw [← same_gf, coeff_mul_prod_one_sub_of_lt_order]
  rintro i -
  rw [order_X_pow]
  exact mod_cast Nat.lt_succ_of_le (le_add_right h)

theorem partition_theorem (n : ℕ) : #(Nat.Partition.odds n) = #(Nat.Partition.distincts n) := by
  -- We need the counts to live in some field (which contains ℕ), so let's just use ℚ
  suffices (#(Nat.Partition.odds n) : ℚ) = #(Nat.Partition.distincts n) from
    mod_cast this
  rw [distinctGF_prop n (n + 1) (by linarith)]
  rw [oddGF_prop n (n + 1) (by linarith)]
  apply same_coeffs (n + 1) n n.le_succ

end

end Theorems100
