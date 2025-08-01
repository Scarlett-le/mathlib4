/-
Copyright (c) 2018 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Chris Hughes
-/
import Mathlib.Algebra.Algebra.Defs
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.FieldTheory.Minpoly.Basic
import Mathlib.RingTheory.Adjoin.Basic
import Mathlib.RingTheory.FinitePresentation
import Mathlib.RingTheory.FiniteType
import Mathlib.RingTheory.Ideal.Quotient.Noetherian
import Mathlib.RingTheory.PowerBasis
import Mathlib.RingTheory.PrincipalIdealDomain
import Mathlib.RingTheory.Polynomial.Quotient

/-!
# Adjoining roots of polynomials

This file defines the commutative ring `AdjoinRoot f`, the ring R[X]/(f) obtained from a
commutative ring `R` and a polynomial `f : R[X]`. If furthermore `R` is a field and `f` is
irreducible, the field structure on `AdjoinRoot f` is constructed.

We suggest stating results on `IsAdjoinRoot` instead of `AdjoinRoot` to achieve higher
generality, since `IsAdjoinRoot` works for all different constructions of `R[α]`
including `AdjoinRoot f = R[X]/(f)` itself.

## Main definitions and results

The main definitions are in the `AdjoinRoot` namespace.

*  `mk f : R[X] →+* AdjoinRoot f`, the natural ring homomorphism.

*  `of f : R →+* AdjoinRoot f`, the natural ring homomorphism.

* `root f : AdjoinRoot f`, the image of X in R[X]/(f).

* `lift (i : R →+* S) (x : S) (h : f.eval₂ i x = 0) : (AdjoinRoot f) →+* S`, the ring
  homomorphism from R[X]/(f) to S extending `i : R →+* S` and sending `X` to `x`.

* `lift_hom (x : S) (hfx : aeval x f = 0) : AdjoinRoot f →ₐ[R] S`, the algebra
  homomorphism from R[X]/(f) to S extending `algebraMap R S` and sending `X` to `x`

* `equiv : (AdjoinRoot f →ₐ[F] E) ≃ {x // x ∈ f.aroots E}` a
  bijection between algebra homomorphisms from `AdjoinRoot` and roots of `f` in `S`

-/

noncomputable section

open Ideal Module Polynomial

universe u v w

variable {R : Type u} {S : Type v} {K : Type w}

/-- Adjoin a root of a polynomial `f` to a commutative ring `R`. We define the new ring
as the quotient of `R[X]` by the principal ideal generated by `f`. -/
def AdjoinRoot [CommRing R] (f : R[X]) : Type u :=
  Polynomial R ⧸ (span {f} : Ideal R[X])

namespace AdjoinRoot

section CommRing

variable [CommRing R] (f : R[X])

instance instCommRing : CommRing (AdjoinRoot f) :=
  Ideal.Quotient.commRing _

instance : Inhabited (AdjoinRoot f) :=
  ⟨0⟩

instance : DecidableEq (AdjoinRoot f) :=
  Classical.decEq _

protected theorem nontrivial [IsDomain R] (h : degree f ≠ 0) : Nontrivial (AdjoinRoot f) :=
  Ideal.Quotient.nontrivial
    (by
      simp_rw [Ne, span_singleton_eq_top, Polynomial.isUnit_iff, not_exists, not_and]
      rintro x hx rfl
      exact h (degree_C hx.ne_zero))

/-- Ring homomorphism from `R[x]` to `AdjoinRoot f` sending `X` to the `root`. -/
def mk : R[X] →+* AdjoinRoot f :=
  Ideal.Quotient.mk _

@[elab_as_elim]
theorem induction_on {C : AdjoinRoot f → Prop} (x : AdjoinRoot f) (ih : ∀ p : R[X], C (mk f p)) :
    C x :=
  Quotient.inductionOn' x ih

/-- Embedding of the original ring `R` into `AdjoinRoot f`. -/
def of : R →+* AdjoinRoot f :=
  (mk f).comp C

instance instSMulAdjoinRoot [DistribSMul S R] [IsScalarTower S R R] : SMul S (AdjoinRoot f) :=
  Submodule.Quotient.instSMul' _

instance [DistribSMul S R] [IsScalarTower S R R] : DistribSMul S (AdjoinRoot f) :=
  Submodule.Quotient.distribSMul' _

@[simp]
theorem smul_mk [DistribSMul S R] [IsScalarTower S R R] (a : S) (x : R[X]) :
    a • mk f x = mk f (a • x) :=
  rfl

theorem smul_of [DistribSMul S R] [IsScalarTower S R R] (a : S) (x : R) :
    a • of f x = of f (a • x) := by rw [of, RingHom.comp_apply, RingHom.comp_apply, smul_mk, smul_C]

instance (R₁ R₂ : Type*) [SMul R₁ R₂] [DistribSMul R₁ R] [DistribSMul R₂ R] [IsScalarTower R₁ R R]
    [IsScalarTower R₂ R R] [IsScalarTower R₁ R₂ R] (f : R[X]) :
    IsScalarTower R₁ R₂ (AdjoinRoot f) :=
  Submodule.Quotient.isScalarTower _ _

instance (R₁ R₂ : Type*) [DistribSMul R₁ R] [DistribSMul R₂ R] [IsScalarTower R₁ R R]
    [IsScalarTower R₂ R R] [SMulCommClass R₁ R₂ R] (f : R[X]) :
    SMulCommClass R₁ R₂ (AdjoinRoot f) :=
  Submodule.Quotient.smulCommClass _ _

instance isScalarTower_right [DistribSMul S R] [IsScalarTower S R R] :
    IsScalarTower S (AdjoinRoot f) (AdjoinRoot f) :=
  Ideal.Quotient.isScalarTower_right

instance [Monoid S] [DistribMulAction S R] [IsScalarTower S R R] (f : R[X]) :
    DistribMulAction S (AdjoinRoot f) :=
  Submodule.Quotient.distribMulAction' _

/-- `R[x]/(f)` is `R`-algebra -/
@[stacks 09FX "second part"]
instance [CommSemiring S] [Algebra S R] : Algebra S (AdjoinRoot f) :=
  Ideal.Quotient.algebra S

@[simp]
theorem algebraMap_eq : algebraMap R (AdjoinRoot f) = of f :=
  rfl

variable (S) in
theorem algebraMap_eq' [CommSemiring S] [Algebra S R] :
    algebraMap S (AdjoinRoot f) = (of f).comp (algebraMap S R) :=
  rfl

theorem finiteType : Algebra.FiniteType R (AdjoinRoot f) :=
  (Algebra.FiniteType.polynomial R).of_surjective _ (Ideal.Quotient.mkₐ_surjective R _)

theorem finitePresentation : Algebra.FinitePresentation R (AdjoinRoot f) :=
  (Algebra.FinitePresentation.polynomial R).quotient (Submodule.fg_span_singleton f)

/-- The adjoined root. -/
def root : AdjoinRoot f :=
  mk f X

variable {f}

instance hasCoeT : CoeTC R (AdjoinRoot f) :=
  ⟨of f⟩

/-- Two `R`-`AlgHom` from `AdjoinRoot f` to the same `R`-algebra are the same iff
    they agree on `root f`. -/
@[ext]
theorem algHom_ext [Semiring S] [Algebra R S] {g₁ g₂ : AdjoinRoot f →ₐ[R] S}
    (h : g₁ (root f) = g₂ (root f)) : g₁ = g₂ :=
  Ideal.Quotient.algHom_ext R <| Polynomial.algHom_ext h

@[simp]
theorem mk_eq_mk {g h : R[X]} : mk f g = mk f h ↔ f ∣ g - h :=
  Ideal.Quotient.eq.trans Ideal.mem_span_singleton

@[simp]
theorem mk_eq_zero {g : R[X]} : mk f g = 0 ↔ f ∣ g :=
  mk_eq_mk.trans <| by rw [sub_zero]

@[simp]
theorem mk_self : mk f f = 0 :=
  Quotient.sound' <| QuotientAddGroup.leftRel_apply.mpr (mem_span_singleton.2 <| by simp)

@[simp]
theorem mk_C (x : R) : mk f (C x) = x :=
  rfl

@[simp]
theorem mk_X : mk f X = root f :=
  rfl

theorem mk_ne_zero_of_degree_lt (hf : Monic f) {g : R[X]} (h0 : g ≠ 0) (hd : degree g < degree f) :
    mk f g ≠ 0 :=
  mk_eq_zero.not.2 <| hf.not_dvd_of_degree_lt h0 hd

theorem mk_ne_zero_of_natDegree_lt (hf : Monic f) {g : R[X]} (h0 : g ≠ 0)
    (hd : natDegree g < natDegree f) : mk f g ≠ 0 :=
  mk_eq_zero.not.2 <| hf.not_dvd_of_natDegree_lt h0 hd

@[simp]
theorem aeval_eq (p : R[X]) : aeval (root f) p = mk f p :=
  Polynomial.induction_on p
    (fun x => by
      rw [aeval_C]
      rfl)
    (fun p q ihp ihq => by rw [map_add, RingHom.map_add, ihp, ihq]) fun n x _ => by
    rw [map_mul, aeval_C, map_pow, aeval_X, RingHom.map_mul, mk_C, RingHom.map_pow, mk_X]
    rfl

theorem adjoinRoot_eq_top : Algebra.adjoin R ({root f} : Set (AdjoinRoot f)) = ⊤ := by
  refine Algebra.eq_top_iff.2 fun x => ?_
  induction x using AdjoinRoot.induction_on with
    | ih p => exact (Algebra.adjoin_singleton_eq_range_aeval R (root f)).symm ▸ ⟨p, aeval_eq p⟩

@[simp]
theorem eval₂_root (f : R[X]) : f.eval₂ (of f) (root f) = 0 := by
  rw [← algebraMap_eq, ← aeval_def, aeval_eq, mk_self]

theorem isRoot_root (f : R[X]) : IsRoot (f.map (of f)) (root f) := by
  rw [IsRoot, eval_map, eval₂_root]

theorem isAlgebraic_root (hf : f ≠ 0) : IsAlgebraic R (root f) :=
  ⟨f, hf, eval₂_root f⟩

theorem of.injective_of_degree_ne_zero [IsDomain R] (hf : f.degree ≠ 0) :
    Function.Injective (AdjoinRoot.of f) := by
  rw [injective_iff_map_eq_zero]
  intro p hp
  rw [AdjoinRoot.of, RingHom.comp_apply, AdjoinRoot.mk_eq_zero] at hp
  by_cases h : f = 0
  · exact C_eq_zero.mp (eq_zero_of_zero_dvd (by rwa [h] at hp))
  · contrapose! hf with h_contra
    rw [← degree_C h_contra]
    apply le_antisymm (degree_le_of_dvd hp (by rwa [Ne, C_eq_zero])) _
    rwa [degree_C h_contra, zero_le_degree_iff]

variable [CommRing S]

/-- Lift a ring homomorphism `i : R →+* S` to `AdjoinRoot f →+* S`. -/
def lift (i : R →+* S) (x : S) (h : f.eval₂ i x = 0) : AdjoinRoot f →+* S := by
  apply Ideal.Quotient.lift _ (eval₂RingHom i x)
  intro g H
  rcases mem_span_singleton.1 H with ⟨y, hy⟩
  rw [hy, RingHom.map_mul, coe_eval₂RingHom, h, zero_mul]

variable {i : R →+* S} {a : S} (h : f.eval₂ i a = 0)

@[simp]
theorem lift_mk (g : R[X]) : lift i a h (mk f g) = g.eval₂ i a :=
  Ideal.Quotient.lift_mk _ _ _

@[simp]
theorem lift_root : lift i a h (root f) = a := by rw [root, lift_mk, eval₂_X]

@[simp]
theorem lift_of {x : R} : lift i a h x = i x := by rw [← mk_C x, lift_mk, eval₂_C]

@[simp]
theorem lift_comp_of : (lift i a h).comp (of f) = i :=
  RingHom.ext fun _ => @lift_of _ _ _ _ _ _ _ h _

variable (f) [Algebra R S]

/-- Produce an algebra homomorphism `AdjoinRoot f →ₐ[R] S` sending `root f` to
a root of `f` in `S`. -/
def liftHom (x : S) (hfx : aeval x f = 0) : AdjoinRoot f →ₐ[R] S :=
  { lift (algebraMap R S) x hfx with
    commutes' := fun r => show lift _ _ hfx r = _ from lift_of hfx }

@[simp]
theorem coe_liftHom (x : S) (hfx : aeval x f = 0) :
    (liftHom f x hfx : AdjoinRoot f →+* S) = lift (algebraMap R S) x hfx :=
  rfl

@[simp]
theorem aeval_algHom_eq_zero (ϕ : AdjoinRoot f →ₐ[R] S) : aeval (ϕ (root f)) f = 0 := by
  have h : ϕ.toRingHom.comp (of f) = algebraMap R S := RingHom.ext_iff.mpr ϕ.commutes
  rw [aeval_def, ← h, ← RingHom.map_zero ϕ.toRingHom, ← eval₂_root f, hom_eval₂]
  rfl

@[simp]
theorem liftHom_eq_algHom (f : R[X]) (ϕ : AdjoinRoot f →ₐ[R] S) :
    liftHom f (ϕ (root f)) (aeval_algHom_eq_zero f ϕ) = ϕ := by
  suffices AlgHom.equalizer ϕ (liftHom f (ϕ (root f)) (aeval_algHom_eq_zero f ϕ)) = ⊤ by
    exact (AlgHom.ext fun x => (SetLike.ext_iff.mp this x).mpr Algebra.mem_top).symm
  rw [eq_top_iff, ← adjoinRoot_eq_top, Algebra.adjoin_le_iff, Set.singleton_subset_iff]
  exact (@lift_root _ _ _ _ _ _ _ (aeval_algHom_eq_zero f ϕ)).symm

variable (hfx : aeval a f = 0)

@[simp]
theorem liftHom_mk {g : R[X]} : liftHom f a hfx (mk f g) = aeval a g :=
  lift_mk hfx g

@[simp]
theorem liftHom_root : liftHom f a hfx (root f) = a :=
  lift_root hfx

@[simp]
theorem liftHom_of {x : R} : liftHom f a hfx (of f x) = algebraMap _ _ x :=
  lift_of hfx

section AdjoinInv

@[simp]
theorem root_isInv (r : R) : of _ r * root (C r * X - 1) = 1 := by
  convert sub_eq_zero.1 ((eval₂_sub _).symm.trans <| eval₂_root <| C r * X - 1) <;>
    simp only [eval₂_mul, eval₂_C, eval₂_X, eval₂_one]

theorem algHom_subsingleton {S : Type*} [CommRing S] [Algebra R S] {r : R} :
    Subsingleton (AdjoinRoot (C r * X - 1) →ₐ[R] S) :=
  ⟨fun f g =>
    algHom_ext
      (@inv_unique _ _ (algebraMap R S r) _ _
        (by rw [← f.commutes, ← map_mul, algebraMap_eq, root_isInv, map_one])
        (by rw [← g.commutes, ← map_mul, algebraMap_eq, root_isInv, map_one]))⟩

end AdjoinInv

section Prime

variable {f}

theorem isDomain_of_prime (hf : Prime f) : IsDomain (AdjoinRoot f) :=
  (Ideal.Quotient.isDomain_iff_prime (span {f} : Ideal R[X])).mpr <|
    (Ideal.span_singleton_prime hf.ne_zero).mpr hf

theorem noZeroSMulDivisors_of_prime_of_degree_ne_zero [IsDomain R] (hf : Prime f)
    (hf' : f.degree ≠ 0) : NoZeroSMulDivisors R (AdjoinRoot f) :=
  haveI := isDomain_of_prime hf
  NoZeroSMulDivisors.iff_algebraMap_injective.mpr (of.injective_of_degree_ne_zero hf')

end Prime

end CommRing

section Irreducible

variable [Field K] {f : K[X]}

instance span_maximal_of_irreducible [Fact (Irreducible f)] : (span {f}).IsMaximal :=
  PrincipalIdealRing.isMaximal_of_irreducible <| Fact.out

noncomputable instance instGroupWithZero [Fact (Irreducible f)] : GroupWithZero (AdjoinRoot f) :=
  Quotient.groupWithZero (span {f} : Ideal K[X])

/-- If `R` is a field and `f` is irreducible, then `AdjoinRoot f` is a field -/
@[stacks 09FX "first part, see also 09FI"]
noncomputable instance instField [Fact (Irreducible f)] : Field (AdjoinRoot f) where
  __ := instCommRing _
  __ := instGroupWithZero
  nnqsmul := (· • ·)
  qsmul := (· • ·)
  nnratCast_def q := by
    rw [← map_natCast (of f), ← map_natCast (of f), ← map_div₀, ← NNRat.cast_def]; rfl
  ratCast_def q := by
    rw [← map_natCast (of f), ← map_intCast (of f), ← map_div₀, ← Rat.cast_def]; rfl
  nnqsmul_def q x :=
    AdjoinRoot.induction_on f (C := fun y ↦ q • y = (of f) q * y) x fun p ↦ by
      simp only [smul_mk, of, RingHom.comp_apply, ← (mk f).map_mul, Polynomial.nnqsmul_eq_C_mul]
  qsmul_def q x :=
    -- Porting note: I gave the explicit motive and changed `rw` to `simp`.
    AdjoinRoot.induction_on f (C := fun y ↦ q • y = (of f) q * y) x fun p ↦ by
      simp only [smul_mk, of, RingHom.comp_apply, ← (mk f).map_mul, Polynomial.qsmul_eq_C_mul]

theorem coe_injective (h : degree f ≠ 0) : Function.Injective ((↑) : K → AdjoinRoot f) :=
  have := AdjoinRoot.nontrivial f h
  (of f).injective

theorem coe_injective' [Fact (Irreducible f)] : Function.Injective ((↑) : K → AdjoinRoot f) :=
  (of f).injective

variable (f)

theorem mul_div_root_cancel [Fact (Irreducible f)] :
    (X - C (root f)) * ((f.map (of f)) / (X - C (root f))) = f.map (of f) :=
  mul_div_eq_iff_isRoot.2 <| isRoot_root _

end Irreducible

section IsNoetherianRing

instance [CommRing R] [IsNoetherianRing R] {f : R[X]} : IsNoetherianRing (AdjoinRoot f) :=
  Ideal.Quotient.isNoetherianRing _

end IsNoetherianRing

section PowerBasis

variable [CommRing R] {g : R[X]}

theorem isIntegral_root' (hg : g.Monic) : IsIntegral R (root g) :=
  ⟨g, hg, eval₂_root g⟩

/-- `AdjoinRoot.modByMonicHom` sends the equivalence class of `f` mod `g` to `f %ₘ g`.

This is a well-defined right inverse to `AdjoinRoot.mk`, see `AdjoinRoot.mk_leftInverse`. -/
def modByMonicHom (hg : g.Monic) : AdjoinRoot g →ₗ[R] R[X] :=
  (Submodule.liftQ _ (Polynomial.modByMonicHom g)
        fun f (hf : f ∈ (Ideal.span {g}).restrictScalars R) =>
        (mem_ker_modByMonic hg).mpr (Ideal.mem_span_singleton.mp hf)).comp <|
    (Submodule.Quotient.restrictScalarsEquiv R (Ideal.span {g} : Ideal R[X])).symm.toLinearMap

@[simp]
theorem modByMonicHom_mk (hg : g.Monic) (f : R[X]) : modByMonicHom hg (mk g f) = f %ₘ g :=
  rfl

theorem mk_leftInverse (hg : g.Monic) : Function.LeftInverse (mk g) (modByMonicHom hg) := by
  intro f
  induction f using AdjoinRoot.induction_on
  rw [modByMonicHom_mk hg, mk_eq_mk, modByMonic_eq_sub_mul_div _ hg, sub_sub_cancel_left,
    dvd_neg]
  apply dvd_mul_right

theorem mk_surjective : Function.Surjective (mk g) :=
  Ideal.Quotient.mk_surjective

/-- The elements `1, root g, ..., root g ^ (d - 1)` form a basis for `AdjoinRoot g`,
where `g` is a monic polynomial of degree `d`. -/
def powerBasisAux' (hg : g.Monic) : Basis (Fin g.natDegree) R (AdjoinRoot g) :=
  .ofEquivFun
    { toFun := fun f i => (modByMonicHom hg f).coeff i
      invFun := fun c => mk g <| ∑ i : Fin g.natDegree, monomial i (c i)
      map_add' := fun f₁ f₂ =>
        funext fun i => by simp only [(modByMonicHom hg).map_add, coeff_add, Pi.add_apply]
      map_smul' := fun f₁ f₂ =>
        funext fun i => by
          simp only [(modByMonicHom hg).map_smul, coeff_smul, Pi.smul_apply, RingHom.id_apply]
      -- Porting note: another proof that I converted to tactic mode
      left_inv := by
        intro f
        induction f using AdjoinRoot.induction_on
        simp only [modByMonicHom_mk, sum_modByMonic_coeff hg degree_le_natDegree]
        refine (mk_eq_mk.mpr ?_).symm
        rw [modByMonic_eq_sub_mul_div _ hg, sub_sub_cancel]
        exact dvd_mul_right _ _
      right_inv := fun x =>
        funext fun i => by
          nontriviality R
          simp only [modByMonicHom_mk]
          rw [(modByMonic_eq_self_iff hg).mpr, finset_sum_coeff]
          · simp_rw [coeff_monomial, Fin.val_eq_val, Finset.sum_ite_eq', if_pos (Finset.mem_univ _)]
          · simp_rw [← C_mul_X_pow_eq_monomial]
            exact (degree_eq_natDegree <| hg.ne_zero).symm ▸ degree_sum_fin_lt _ }

-- This lemma could be autogenerated by `@[simps]` but unfortunately that would require
-- unfolding that causes a timeout.
-- This lemma should have the simp tag but this causes a lint issue.
theorem powerBasisAux'_repr_symm_apply (hg : g.Monic) (c : Fin g.natDegree →₀ R) :
    (powerBasisAux' hg).repr.symm c = mk g (∑ i : Fin _, monomial i (c i)) :=
  rfl

-- This lemma could be autogenerated by `@[simps]` but unfortunately that would require
-- unfolding that causes a timeout.
@[simp]
theorem powerBasisAux'_repr_apply_to_fun (hg : g.Monic) (f : AdjoinRoot g) (i : Fin g.natDegree) :
    (powerBasisAux' hg).repr f i = (modByMonicHom hg f).coeff ↑i :=
  rfl

/-- The power basis `1, root g, ..., root g ^ (d - 1)` for `AdjoinRoot g`,
where `g` is a monic polynomial of degree `d`. -/
@[simps]
def powerBasis' (hg : g.Monic) : PowerBasis R (AdjoinRoot g) where
  gen := root g
  dim := g.natDegree
  basis := powerBasisAux' hg
  basis_eq_pow i := by
    simp only [powerBasisAux', Basis.coe_ofEquivFun, LinearEquiv.coe_symm_mk]
    rw [Finset.sum_eq_single i]
    · rw [Pi.single_eq_same, monomial_one_right_eq_X_pow, (mk g).map_pow, mk_X]
    · intro j _ hj
      rw [← monomial_zero_right _, Pi.single_eq_of_ne hj]
    -- Fix `DecidableEq` mismatch
    · intros
      have := Finset.mem_univ i
      contradiction

lemma _root_.Polynomial.Monic.free_adjoinRoot (hg : g.Monic) : Module.Free R (AdjoinRoot g) :=
  .of_basis (powerBasis' hg).basis

lemma _root_.Polynomial.Monic.finite_adjoinRoot (hg : g.Monic) : Module.Finite R (AdjoinRoot g) :=
  .of_basis (powerBasis' hg).basis

/-- An unwrapped version of `AdjoinRoot.free_of_monic` for better discoverability. -/
lemma _root_.Polynomial.Monic.free_quotient (hg : g.Monic) :
    Module.Free R (R[X] ⧸ Ideal.span {g}) :=
  hg.free_adjoinRoot

/-- An unwrapped version of `AdjoinRoot.finite_of_monic` for better discoverability. -/
lemma _root_.Polynomial.Monic.finite_quotient (hg : g.Monic) :
    Module.Finite R (R[X] ⧸ Ideal.span {g}) :=
  hg.finite_adjoinRoot

variable [Field K] {f : K[X]}

theorem isIntegral_root (hf : f ≠ 0) : IsIntegral K (root f) :=
  (isAlgebraic_root hf).isIntegral

theorem minpoly_root (hf : f ≠ 0) : minpoly K (root f) = f * C f.leadingCoeff⁻¹ := by
  have f'_monic : Monic _ := monic_mul_leadingCoeff_inv hf
  refine (minpoly.unique K _ f'_monic ?_ ?_).symm
  · rw [map_mul, aeval_eq, mk_self, zero_mul]
  intro q q_monic q_aeval
  have commutes : (lift (algebraMap K (AdjoinRoot f)) (root f) q_aeval).comp (mk q) = mk f := by
    ext
    · simp only [RingHom.comp_apply, mk_C, lift_of]
      rfl
    · simp only [RingHom.comp_apply, mk_X, lift_root]
  rw [degree_eq_natDegree f'_monic.ne_zero, degree_eq_natDegree q_monic.ne_zero,
    Nat.cast_le, natDegree_mul hf, natDegree_C, add_zero]
  · apply natDegree_le_of_dvd
    · have : mk f q = 0 := by rw [← commutes, RingHom.comp_apply, mk_self, RingHom.map_zero]
      exact mk_eq_zero.1 this
    · exact q_monic.ne_zero
  · rwa [Ne, C_eq_zero, inv_eq_zero, leadingCoeff_eq_zero]

/-- The elements `1, root f, ..., root f ^ (d - 1)` form a basis for `AdjoinRoot f`,
where `f` is an irreducible polynomial over a field of degree `d`. -/
def powerBasisAux (hf : f ≠ 0) : Basis (Fin f.natDegree) K (AdjoinRoot f) := by
  let f' := f * C f.leadingCoeff⁻¹
  have deg_f' : f'.natDegree = f.natDegree := by
    rw [natDegree_mul hf, natDegree_C, add_zero]
    · rwa [Ne, C_eq_zero, inv_eq_zero, leadingCoeff_eq_zero]
  have minpoly_eq : minpoly K (root f) = f' := minpoly_root hf
  apply Basis.mk (v := fun i : Fin f.natDegree ↦ root f ^ i.val)
  · rw [← deg_f', ← minpoly_eq]
    exact linearIndependent_pow (root f)
  · rintro y -
    rw [← deg_f', ← minpoly_eq]
    apply (isIntegral_root hf).mem_span_pow
    obtain ⟨g⟩ := y
    use g
    rw [aeval_eq]
    rfl

/-- The power basis `1, root f, ..., root f ^ (d - 1)` for `AdjoinRoot f`,
where `f` is an irreducible polynomial over a field of degree `d`. -/
@[simps!]
def powerBasis (hf : f ≠ 0) : PowerBasis K (AdjoinRoot f) where
  gen := root f
  dim := f.natDegree
  basis := powerBasisAux hf
  basis_eq_pow := by simp [powerBasisAux]

theorem minpoly_powerBasis_gen (hf : f ≠ 0) :
    minpoly K (powerBasis hf).gen = f * C f.leadingCoeff⁻¹ := by
  rw [powerBasis_gen, minpoly_root hf]

theorem minpoly_powerBasis_gen_of_monic (hf : f.Monic) (hf' : f ≠ 0 := hf.ne_zero) :
    minpoly K (powerBasis hf').gen = f := by
  rw [minpoly_powerBasis_gen hf', hf.leadingCoeff, inv_one, C.map_one, mul_one]

end PowerBasis

section Equiv

section minpoly

variable [CommRing R] [CommRing S] [Algebra R S] (x : S) (R)

open Algebra Polynomial

/-- The surjective algebra morphism `R[X]/(minpoly R x) → R[x]`.
If `R` is a integrally closed domain and `x` is integral, this is an isomorphism,
see `minpoly.equivAdjoin`. -/
def Minpoly.toAdjoin : AdjoinRoot (minpoly R x) →ₐ[R] adjoin R ({x} : Set S) :=
  liftHom _ ⟨x, self_mem_adjoin_singleton R x⟩
    (by simp [← Subalgebra.coe_eq_zero, aeval_subalgebra_coe])

variable {R x}

@[simp]
theorem Minpoly.coe_toAdjoin :
    ⇑(Minpoly.toAdjoin R x) = liftHom (minpoly R x) ⟨x, self_mem_adjoin_singleton R x⟩
      (by simp [← Subalgebra.coe_eq_zero, aeval_subalgebra_coe]) := rfl

@[deprecated (since := "2025-07-21")] alias Minpoly.toAdjoin_apply := Minpoly.coe_toAdjoin
@[deprecated (since := "2025-07-21")] alias Minpoly.toAdjoin_apply' := Minpoly.coe_toAdjoin

theorem Minpoly.coe_toAdjoin_mk_X : Minpoly.toAdjoin R x (mk (minpoly R x) X) = x := by simp

@[deprecated (since := "2025-07-21")] alias Minpoly.toAdjoin.apply_X := Minpoly.coe_toAdjoin_mk_X

variable (R x)

theorem Minpoly.toAdjoin.surjective : Function.Surjective (Minpoly.toAdjoin R x) := by
  rw [← AlgHom.range_eq_top, _root_.eq_top_iff, ← adjoin_adjoin_coe_preimage]
  exact adjoin_le fun ⟨y₁, y₂⟩ h ↦ ⟨mk (minpoly R x) X, by simpa using h.symm⟩

end minpoly

section Equiv'

variable [CommRing R] [CommRing S] [Algebra R S]
variable (g : R[X]) (pb : PowerBasis R S)

/-- If `S` is an extension of `R` with power basis `pb` and `g` is a monic polynomial over `R`
such that `pb.gen` has a minimal polynomial `g`, then `S` is isomorphic to `AdjoinRoot g`.

Compare `PowerBasis.equivOfRoot`, which would require
`h₂ : aeval pb.gen (minpoly R (root g)) = 0`; that minimal polynomial is not
guaranteed to be identical to `g`. -/
@[simps -fullyApplied]
def equiv' (h₁ : aeval (root g) (minpoly R pb.gen) = 0) (h₂ : aeval pb.gen g = 0) :
    AdjoinRoot g ≃ₐ[R] S :=
  { AdjoinRoot.liftHom g pb.gen h₂ with
    toFun := AdjoinRoot.liftHom g pb.gen h₂
    invFun := pb.lift (root g) h₁
    -- Porting note: another term-mode proof converted to tactic-mode.
    left_inv := fun x => by
      induction x using AdjoinRoot.induction_on
      rw [liftHom_mk, pb.lift_aeval, aeval_eq]
    right_inv := fun x => by
      nontriviality S
      obtain ⟨f, _hf, rfl⟩ := pb.exists_eq_aeval x
      rw [pb.lift_aeval, aeval_eq, liftHom_mk] }

-- This lemma should have the simp tag but this causes a lint issue.
theorem equiv'_toAlgHom (h₁ : aeval (root g) (minpoly R pb.gen) = 0) (h₂ : aeval pb.gen g = 0) :
    (equiv' g pb h₁ h₂).toAlgHom = AdjoinRoot.liftHom g pb.gen h₂ :=
  rfl

-- This lemma should have the simp tag but this causes a lint issue.
theorem equiv'_symm_toAlgHom (h₁ : aeval (root g) (minpoly R pb.gen) = 0)
    (h₂ : aeval pb.gen g = 0) : (equiv' g pb h₁ h₂).symm.toAlgHom = pb.lift (root g) h₁ :=
  rfl

end Equiv'

section Field

variable (L F : Type*) [Field F] [CommRing L] [IsDomain L] [Algebra F L]

/-- If `L` is a field extension of `F` and `f` is a polynomial over `F` then the set
of maps from `F[x]/(f)` into `L` is in bijection with the set of roots of `f` in `L`. -/
def equiv (f : F[X]) (hf : f ≠ 0) :
    (AdjoinRoot f →ₐ[F] L) ≃ { x // x ∈ f.aroots L } :=
  (powerBasis hf).liftEquiv'.trans
    ((Equiv.refl _).subtypeEquiv fun x => by
      rw [powerBasis_gen, minpoly_root hf, aroots_mul, aroots_C, add_zero, Equiv.refl_apply]
      exact (monic_mul_leadingCoeff_inv hf).ne_zero)

end Field

end Equiv

-- Porting note: consider splitting the file here.  In the current mathlib3, the only result
-- that depends any of these lemmas was
-- `normalizedFactorsMapEquivNormalizedFactorsMinPolyMk` in `NumberTheory.KummerDedekind`
-- that uses
-- `PowerBasis.quotientEquivQuotientMinpolyMap == PowerBasis.quotientEquivQuotientMinpolyMap`
section

open Ideal DoubleQuot Polynomial

variable [CommRing R] (I : Ideal R) (f : R[X])

/-- The natural isomorphism `R[α]/(I[α]) ≅ R[α]/((I[x] ⊔ (f)) / (f))` for `α` a root of
`f : R[X]` and `I : Ideal R`.

See `adjoin_root.quot_map_of_equiv` for the isomorphism with `(R/I)[X] / (f mod I)`. -/
def quotMapOfEquivQuotMapCMapSpanMk :
    AdjoinRoot f ⧸ I.map (of f) ≃+*
      AdjoinRoot f ⧸ (I.map (C : R →+* R[X])).map (Ideal.Quotient.mk (span {f})) :=
  Ideal.quotEquivOfEq (by rw [of, AdjoinRoot.mk, Ideal.map_map])

@[simp]
theorem quotMapOfEquivQuotMapCMapSpanMk_mk (x : AdjoinRoot f) :
    quotMapOfEquivQuotMapCMapSpanMk I f (Ideal.Quotient.mk (I.map (of f)) x) =
      Ideal.Quotient.mk (Ideal.map (Ideal.Quotient.mk (span {f})) (I.map (C : R →+* R[X]))) x := rfl

--this lemma should have the simp tag but this causes a lint issue
theorem quotMapOfEquivQuotMapCMapSpanMk_symm_mk (x : AdjoinRoot f) :
    (quotMapOfEquivQuotMapCMapSpanMk I f).symm
        (Ideal.Quotient.mk ((I.map (C : R →+* R[X])).map (Ideal.Quotient.mk (span {f}))) x) =
      Ideal.Quotient.mk (I.map (of f)) x := by
  rw [quotMapOfEquivQuotMapCMapSpanMk, Ideal.quotEquivOfEq_symm]
  exact Ideal.quotEquivOfEq_mk _ _

/-- The natural isomorphism `R[α]/((I[x] ⊔ (f)) / (f)) ≅ (R[x]/I[x])/((f) ⊔ I[x] / I[x])`
  for `α` a root of `f : R[X]` and `I : Ideal R` -/
def quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk :
    AdjoinRoot f ⧸ (I.map (C : R →+* R[X])).map (Ideal.Quotient.mk (span ({f} : Set R[X]))) ≃+*
      (R[X] ⧸ I.map (C : R →+* R[X])) ⧸
        (span ({f} : Set R[X])).map (Ideal.Quotient.mk (I.map (C : R →+* R[X]))) :=
  quotQuotEquivComm (Ideal.span ({f} : Set R[X])) (I.map (C : R →+* R[X]))

-- This lemma should have the simp tag but this causes a lint issue.
theorem quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk_mk (p : R[X]) :
    quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk I f (Ideal.Quotient.mk _ (mk f p)) =
      quotQuotMk (I.map C) (span {f}) p :=
  rfl

@[simp]
theorem quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk_symm_quotQuotMk (p : R[X]) :
    (quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk I f).symm (quotQuotMk (I.map C) (span {f}) p) =
      Ideal.Quotient.mk (Ideal.map (Ideal.Quotient.mk (span {f})) (I.map (C : R →+* R[X])))
        (mk f p) :=
  rfl

/-- The natural isomorphism `(R/I)[x]/(f mod I) ≅ (R[x]/I*R[x])/(f mod I[x])` where
  `f : R[X]` and `I : Ideal R` -/
def Polynomial.quotQuotEquivComm :
    (R ⧸ I)[X] ⧸ span ({f.map (Ideal.Quotient.mk I)} : Set (Polynomial (R ⧸ I))) ≃+*
      (R[X] ⧸ (I.map C)) ⧸ span ({(Ideal.Quotient.mk (I.map C)) f} : Set (R[X] ⧸ (I.map C))) :=
  quotientEquiv (span ({f.map (Ideal.Quotient.mk I)} : Set (Polynomial (R ⧸ I))))
    (span {Ideal.Quotient.mk (I.map Polynomial.C) f}) (polynomialQuotientEquivQuotientPolynomial I)
    (by
      rw [map_span, Set.image_singleton, RingEquiv.coe_toRingHom,
        polynomialQuotientEquivQuotientPolynomial_map_mk I f])

@[simp]
theorem Polynomial.quotQuotEquivComm_mk (p : R[X]) :
    (Polynomial.quotQuotEquivComm I f) (Ideal.Quotient.mk _ (p.map (Ideal.Quotient.mk I))) =
      Ideal.Quotient.mk (span ({(Ideal.Quotient.mk (I.map C)) f} : Set (R[X] ⧸ (I.map C))))
      (Ideal.Quotient.mk (I.map C) p) := by
  simp only [Polynomial.quotQuotEquivComm, quotientEquiv_mk,
    polynomialQuotientEquivQuotientPolynomial_map_mk]

@[simp]
theorem Polynomial.quotQuotEquivComm_symm_mk_mk (p : R[X]) :
    (Polynomial.quotQuotEquivComm I f).symm (Ideal.Quotient.mk (span
    ({(Ideal.Quotient.mk (I.map C)) f} : Set (R[X] ⧸ (I.map C)))) (Ideal.Quotient.mk (I.map C) p)) =
      Ideal.Quotient.mk (span {f.map (Ideal.Quotient.mk I)}) (p.map (Ideal.Quotient.mk I)) := by
  simp only [Polynomial.quotQuotEquivComm, quotientEquiv_symm_mk,
    polynomialQuotientEquivQuotientPolynomial_symm_mk]

/-- The natural isomorphism `R[α]/I[α] ≅ (R/I)[X]/(f mod I)` for `α` a root of `f : R[X]`
  and `I : Ideal R`. -/
def quotAdjoinRootEquivQuotPolynomialQuot :
    AdjoinRoot f ⧸ I.map (of f) ≃+*
    (R ⧸ I)[X] ⧸ span ({f.map (Ideal.Quotient.mk I)} : Set (R ⧸ I)[X]) :=
  (quotMapOfEquivQuotMapCMapSpanMk I f).trans
    ((quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk I f).trans
      ((Ideal.quotEquivOfEq (by rw [map_span, Set.image_singleton])).trans
        (Polynomial.quotQuotEquivComm I f).symm))

@[simp]
theorem quotAdjoinRootEquivQuotPolynomialQuot_mk_of (p : R[X]) :
    quotAdjoinRootEquivQuotPolynomialQuot I f (Ideal.Quotient.mk (I.map (of f)) (mk f p)) =
      Ideal.Quotient.mk (span ({f.map (Ideal.Quotient.mk I)} : Set (R ⧸ I)[X]))
      (p.map (Ideal.Quotient.mk I)) := rfl

@[simp]
theorem quotAdjoinRootEquivQuotPolynomialQuot_symm_mk_mk (p : R[X]) :
    (quotAdjoinRootEquivQuotPolynomialQuot I f).symm
        (Ideal.Quotient.mk (span ({f.map (Ideal.Quotient.mk I)} : Set (R ⧸ I)[X]))
        (p.map (Ideal.Quotient.mk I))) =
      Ideal.Quotient.mk (I.map (of f)) (mk f p) := by
  rw [quotAdjoinRootEquivQuotPolynomialQuot, RingEquiv.symm_trans_apply,
    RingEquiv.symm_trans_apply, RingEquiv.symm_trans_apply, RingEquiv.symm_symm,
    Polynomial.quotQuotEquivComm_mk, Ideal.quotEquivOfEq_symm, Ideal.quotEquivOfEq_mk, ←
    RingHom.comp_apply, ← DoubleQuot.quotQuotMk,
    quotMapCMapSpanMkEquivQuotMapCQuotMapSpanMk_symm_quotQuotMk,
    quotMapOfEquivQuotMapCMapSpanMk_symm_mk]

/-- Promote `AdjoinRoot.quotAdjoinRootEquivQuotPolynomialQuot` to an alg_equiv. -/
@[simps!]
noncomputable def quotEquivQuotMap (f : R[X]) (I : Ideal R) :
    (AdjoinRoot f ⧸ Ideal.map (of f) I) ≃ₐ[R]
      (R ⧸ I)[X] ⧸ Ideal.span ({Polynomial.map (Ideal.Quotient.mk I) f} : Set (R ⧸ I)[X]) :=
  AlgEquiv.ofRingEquiv
    (show ∀ x, (quotAdjoinRootEquivQuotPolynomialQuot I f) (algebraMap R _ x) = algebraMap R _ x
      from fun x => by
      have :
        algebraMap R (AdjoinRoot f ⧸ Ideal.map (of f) I) x =
          Ideal.Quotient.mk (Ideal.map (AdjoinRoot.of f) I) ((mk f) (C x)) :=
        rfl
      rw [this, quotAdjoinRootEquivQuotPolynomialQuot_mk_of, map_C]
      -- Porting note: the following `rfl` was not needed
      rfl)

@[simp]
theorem quotEquivQuotMap_apply_mk (f g : R[X]) (I : Ideal R) :
    AdjoinRoot.quotEquivQuotMap f I (Ideal.Quotient.mk (Ideal.map (of f) I) (AdjoinRoot.mk f g)) =
      Ideal.Quotient.mk (Ideal.span ({Polynomial.map (Ideal.Quotient.mk I) f} : Set (R ⧸ I)[X]))
      (g.map (Ideal.Quotient.mk I)) := by
  rw [AdjoinRoot.quotEquivQuotMap_apply, AdjoinRoot.quotAdjoinRootEquivQuotPolynomialQuot_mk_of]

theorem quotEquivQuotMap_symm_apply_mk (f g : R[X]) (I : Ideal R) :
    (AdjoinRoot.quotEquivQuotMap f I).symm (Ideal.Quotient.mk _
      (Polynomial.map (Ideal.Quotient.mk I) g)) =
        Ideal.Quotient.mk (Ideal.map (of f) I) (AdjoinRoot.mk f g) := by
  rw [AdjoinRoot.quotEquivQuotMap_symm_apply,
    AdjoinRoot.quotAdjoinRootEquivQuotPolynomialQuot_symm_mk_mk]

end

end AdjoinRoot

namespace PowerBasis

open AdjoinRoot AlgEquiv

variable [CommRing R] [CommRing S] [Algebra R S]

/-- Let `α` have minimal polynomial `f` over `R` and `I` be an ideal of `R`,
then `R[α] / (I) = (R[x] / (f)) / pS = (R/p)[x] / (f mod p)`. -/
@[simps!]
noncomputable def quotientEquivQuotientMinpolyMap (pb : PowerBasis R S) (I : Ideal R) :
    (S ⧸ I.map (algebraMap R S)) ≃ₐ[R]
      Polynomial (R ⧸ I) ⧸
        Ideal.span ({(minpoly R pb.gen).map (Ideal.Quotient.mk I)} : Set (Polynomial (R ⧸ I))) :=
  (ofRingEquiv
        (show ∀ x,
            (Ideal.quotientEquiv _ (Ideal.map (AdjoinRoot.of (minpoly R pb.gen)) I)
                  (AdjoinRoot.equiv' (minpoly R pb.gen) pb
                        (by rw [AdjoinRoot.aeval_eq, AdjoinRoot.mk_self])
                        (minpoly.aeval _ _)).symm.toRingEquiv
                  (by rw [Ideal.map_map, AlgEquiv.toRingEquiv_eq_coe,
                      ← AlgEquiv.coe_ringHom_commutes, ← AdjoinRoot.algebraMap_eq,
                      AlgHom.comp_algebraMap]))
                (algebraMap R (S ⧸ I.map (algebraMap R S)) x) = algebraMap R _ x from fun x => by
                  rw [← Ideal.Quotient.mk_algebraMap, Ideal.quotientEquiv_apply,
                    RingHom.toFun_eq_coe, Ideal.quotientMap_mk, AlgEquiv.toRingEquiv_eq_coe,
                    RingEquiv.coe_toRingHom, AlgEquiv.coe_ringEquiv, AlgEquiv.commutes,
                    Quotient.mk_algebraMap])).trans (AdjoinRoot.quotEquivQuotMap _ _)

-- This lemma should have the simp tag but this causes a lint issue.
theorem quotientEquivQuotientMinpolyMap_apply_mk (pb : PowerBasis R S) (I : Ideal R) (g : R[X]) :
    pb.quotientEquivQuotientMinpolyMap I (Ideal.Quotient.mk (I.map (algebraMap R S))
      (aeval pb.gen g)) = Ideal.Quotient.mk
        (Ideal.span ({(minpoly R pb.gen).map (Ideal.Quotient.mk I)} : Set (Polynomial (R ⧸ I))))
          (g.map (Ideal.Quotient.mk I)) := by
  rw [PowerBasis.quotientEquivQuotientMinpolyMap, AlgEquiv.trans_apply, AlgEquiv.ofRingEquiv_apply,
    quotientEquiv_mk, AlgEquiv.coe_ringEquiv', AdjoinRoot.equiv'_symm_apply, PowerBasis.lift_aeval,
    AdjoinRoot.aeval_eq, AdjoinRoot.quotEquivQuotMap_apply_mk]

-- This lemma should have the simp tag but this causes a lint issue.
theorem quotientEquivQuotientMinpolyMap_symm_apply_mk (pb : PowerBasis R S) (I : Ideal R)
    (g : R[X]) :
    (pb.quotientEquivQuotientMinpolyMap I).symm (Ideal.Quotient.mk (Ideal.span
      ({(minpoly R pb.gen).map (Ideal.Quotient.mk I)} : Set (Polynomial (R ⧸ I))))
        (g.map (Ideal.Quotient.mk I))) = Ideal.Quotient.mk (I.map (algebraMap R S))
          (aeval pb.gen g) := by
  simp only [quotientEquivQuotientMinpolyMap, toRingEquiv_eq_coe, symm_trans_apply,
    quotEquivQuotMap_symm_apply_mk, ofRingEquiv_symm_apply, quotientEquiv_symm_mk,
    RingEquiv.symm_symm, AdjoinRoot.equiv'_apply, coe_ringEquiv, liftHom_mk,
    symm_toRingEquiv]

end PowerBasis

/-- If `L / K` is an integral extension, `K` is a domain, `L` is a field, then any irreducible
polynomial over `L` divides some monic irreducible polynomial over `K`. -/
theorem Irreducible.exists_dvd_monic_irreducible_of_isIntegral {K L : Type*}
    [CommRing K] [IsDomain K] [Field L] [Algebra K L] [Algebra.IsIntegral K L] {f : L[X]}
    (hf : Irreducible f) : ∃ g : K[X], g.Monic ∧ Irreducible g ∧ f ∣ g.map (algebraMap K L) := by
  haveI := Fact.mk hf
  have h := hf.ne_zero
  have h2 := isIntegral_trans (R := K) _ (AdjoinRoot.isIntegral_root h)
  have h3 := (AdjoinRoot.minpoly_root h) ▸ minpoly.dvd_map_of_isScalarTower K L (AdjoinRoot.root f)
  exact ⟨_, minpoly.monic h2, minpoly.irreducible h2, dvd_of_mul_right_dvd h3⟩
