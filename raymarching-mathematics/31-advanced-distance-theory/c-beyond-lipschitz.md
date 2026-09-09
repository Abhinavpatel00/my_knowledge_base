# Chapter 31c — Beyond Lipschitz: Harnack, Curved Rays, and Generalized Tracing

1-Lipschitz bounds are not the only way to march safely. This chapter covers two graduate-level generalizations: **Harnack tracing** (march harmonic functions) and **curved-ray sphere tracing** (march deformed distance fields). Both follow from *different* conservative bounds and both extend the universe of rays we can safely cast.

## 31c.1 The general conservative-step framework

All safe marching can be unified as:

> Given a scalar field $h$ and a desired level set $h=c$, find a *pointwise* radius $\rho(\mathbf p)$ such that the open ball $B(\mathbf p,\rho)$ contains no point of the level set. Then the safe step is $\rho$ (or a conservative fraction of it).

For an SDF, $\rho=d$ (the value itself gives the radius, because $d$ is the distance). For a 1-Lipschitz bound, $\rho=d/L$. For a harmonic function, $\rho$ comes from a **Harnack inequality**. For a deformed SDF, $\rho$ comes from the Jacobian of the deformation *along the curved ray*.

## 31c.2 Harnack tracing of harmonic functions

A **harmonic function** $h$ satisfies $\Delta h=0$ (Laplace's equation). Harmonic functions arise from interpolation problems, Poisson surface reconstruction, generalized winding numbers, and many areas of geometry. They do *not* satisfy the eikonal/Lipschitz condition in general, so classical sphere tracing does not apply.

**The key observation (Gillespie, Yang, Botsch, Crane, 2024).** For a harmonic function, a conservative radius about a point is provided by **Harnack's inequality**. A quantitative version states: if $h$ is positive and harmonic, and $\mathbf p$ is a point with $h(\mathbf p)=v>0$, then there is a computable radius $\rho$ such that $h$ does not vanish within $B(\mathbf p,\rho)$. This gives a *value-only* bound (like SDF's!) that does not require Lipschitz information.

**The Harnack empty-ball principle.** For a positive harmonic function with value $v>0$ at $\mathbf p$, the set $\{h\le0\}$ does not intersect the ball of radius proportional to $v/\lVert\nabla h\rVert$ (heuristic) — but the rigorous Harnack bound gives a radius with no need for the gradient. In practice one also has a **gradient-sensitive termination condition** $|h|<\alpha\lVert\nabla h\rVert$ for declaring a hit.

**Why this is a different class.** The Harnack bound uses only the *value* of $h$ at a point and a global constant (like the Harnack constant / the geometry), analogous to how an SDF uses its value as the bound. This lets us trace level sets of harmonic functions — including *angle-valued* harmonic functions with jump discontinuities (e.g. winding-number fields surrounding a closed curve) — which is not possible with Lipschitz reasoning.

**Rendering implications.** Harnack tracing lets us visualize, in real time, surfaces from:

- Poisson surface reconstruction (no mesh extraction),
- Generalized winding numbers (polygon soup, possibly with holes),
- Non-planar polygons and mathematical objects (knots, links, spherical harmonics, Riemann surfaces).

This is a genuinely advanced, current research technique, and it is in the same "family" as sphere tracing at the level of the *conservative-empty-ball* abstraction.

## 31c.3 Curved-ray (nonlinear) sphere tracing

When a scene is defined as a *deformation* of an SDF — a squash-and-stretch, a bend, a skinning, a nonlinear warp — the relationship between object space and world space is a map $D$. The whole "inverse transform" trick (Chapter 10) assumes $D$ is invertible and globally well-defined. For many modern deformations (linear blend skinning, hard deformations, non-injective warps), the inverse is unavailable or multi-valued.

**The problem.** We want to march a *straight* ray in world space, but the object lives in "undeformed" space. The straight world ray, pulled back through $D^{-1}$, becomes a *curved* path through object space. So the image-space ray is a curve.

**The formulation (Seyb et al., 2019).** Pose the deformed ray as an initial-value problem for an ODE. Let $\hat{\mathbf x}(s)$ be the curve in undeformed space. Its derivative is
$$
\hat{\mathbf x}'(s)=\hat{\boldsymbol\omega}(\hat{\mathbf x}(s)),
$$
where the velocity field
$$
\hat{\boldsymbol\omega}(\hat{\mathbf x})=J_{D}^{-1}(\hat{\mathbf x})\,\boldsymbol\omega
$$
is the inverse-Jacobian-transformed world ray direction $\boldsymbol\omega$. This is exactly the parametric-curve deformation of Barr (1984), written as an IVP.

**The marching algorithm.** Instead of a single sphere-tracing leap, each step integrates the ODE with an integrator, then uses the SDF value in *undeformed space* to determine a conservative step along the *curve*. Crucially, the algorithm **decouples the trajectory integration (the ODE solver, cheaper per substep, no SDF evaluation) from the SDF root-finding (the sphere-tracing step, expensive)**. The result:

```
for each substep:
    integrate the curved ray with an ODE solver (e.g. RK), no SDF calls   # cheap
    evaluate the SDF at the new point                                      # expensive
    take a conservative sphere-tracing step along the curve based on SDF   # safe
```

**The guarantee.** The key statement: even under error in the trajectory, the algorithm is *guaranteed to never step into the surface*. This is because each step is a *sphere-tracing* step in undeformed space along the (approximate) curve — the "unbounding sphere" argument still applies locally to the deformed SDF. The two sources of error are (1) numerical integration of the trajectory and (2) linearization of the inverse map; neither introduces tunneling because sphere tracing is conservative.

**Why it matters.** It lets us render **linear blend skinning** and modern forward deformations directly on SDFs without computing or storing the inverse deformation — a real extension of the "transform space instead of the object" philosophy to the case where the transform is non-invertible and time-varying.

**Consequence for the practitioner.** This is the mathematically correct answer to "how do I render a bend/squash/skinning without breaking the SDF?" It is more expensive than the naive inverse-transform (extra ODE integration), but it is *safe* and *general*, and it is the rigorous foundation behind the "curved ray" tricks seen in advanced raymarchers.

## 31c.4 Segment tracing (local Lipschitz)

Between the extremes of a global constant and a full curved-ray solve lies **Segment Tracing** (Keinert et al.), discussed in Chapter 31a. It computes a *local Lipschitz bound over a segment* of the ray and uses it to enlarge the step. This is a "better bound, same march" approach and is the most broadly practical of the three methods.

## 31c.5 The unified taxonomy of safe marching

| Method | Bound used | Field class | Requires | Cost |
|--------|-----------|-------------|----------|------|
| Sphere tracing (Hart) | $d$ itself | exact SDF / 1-Lipschitz | value | Low |
| Bounded marching | $d/L$ | Lipschitz with known $L$ | value + $L$ | Low |
| Gradient estimate | $f/\lVert\nabla f\rVert$ | generic implicit | value + gradient | Med |
| Segment tracing | local $L$ over segment | Lipschitz, local const | value + local bound | Med |
| Harnack tracing | Harnack radius | harmonic (positive) | value | Med |
| Curved-ray (nonlinear) | SDF along a curve | deformed SDF | value + Jacobian | High |

All are instances of the single principle: **find a conservative empty-ball radius at each point, then step.** The differences are (a) which *a-priori* property of the field supplies the radius, and (b) whether the ray is straight or curved.

## Exercises

1. **(Derivation)** State Harnack's inequality for a positive harmonic function and explain how it yields a conservative empty-ball radius.
2. **(Analytic)** Explain why Lipschitz reasoning cannot handle angle-valued harmonic functions (jump discontinuities), and how Harnack's inequality can.
3. **(Derivation)** Derive the DE-formulation of a deformed ray: $\hat{\mathbf x}'=J_D^{-1}\boldsymbol\omega$, via the chain rule.
4. **(Analytic)** Argue why the curved-ray method is guaranteed not to tunnel, even with integration error (use the local sphere-tracing bound).
5. **(Implementation)** Implement a single-step curved-ray sphere tracer for a simple bend, and compare against the naive inverse-transform.
6. **(Design)** Catalogue which rendering tasks call for each method: a rigid scene, a heavily warped/deformed body, a harmonic level set, a fractal.
