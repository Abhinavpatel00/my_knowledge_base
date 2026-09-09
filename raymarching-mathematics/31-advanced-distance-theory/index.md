# Section 31 — Advanced Distance Theory

This section is the graduate-level companion to the core text. It goes beyond the "practical bound" treatment of Chapters 06, 10, and 20 and gives the *rigorous* foundation: convergence certificates, the eikonal equation, and the two major generalizations of sphere tracing (Harnack tracing and curved-ray marching).

It is intended for a reader who is comfortable with the material through Level 14 and who wants to understand *why* the algorithms are correct and *how far* they generalize.

| Chapter | File | Topic |
|---------|------|-------|
| 31a | `a-convergence-certified-bounds.md` | Hart's convergence theorem, SDFE closure, operator-theoretic Lipschitz bounds, forward certification, segment tracing |
| 31b | `b-eikonal-reconstruction.md` | The eikonal PDE, Hopf–Lax solution, gradient distance estimate $f/\lVert\nabla f\rVert$, uniform-thickness, cut locus |
| 31c | `c-beyond-lipschitz.md` | Harnack tracing, curved-ray (nonlinear) sphere tracing, the unified conservative-step framework |

## Prerequisites

- Chapters 01 (Lipschitz continuity), 06 (taxonomy), 07 (sphere tracing), 10 (domain transforms), 12 (differential geometry), 20 (DE).
- Graduate-level real analysis and ODE/PDE basics: the mean-value inequality, operator (spectral) norms, and a passing familiarity with first-order PDEs (eikonal = Hamilton–Jacobi type) and harmonic functions.

## The unifying idea

Every safe marching algorithm is this:

> **Find a pointwise conservative radius that certifies an empty ball around the current point; step by that radius; stop when within tolerance of the level set.**

The three chapters differ only in *which a-priori property* supplies the radius:

- **31a:** the metric/Lipschitz property (distance bounds, certified via the Jacobian's spectral norm).
- **31b:** the eikonal structure (a first-order distance *reconstruction* for implicit fields).
- **31c:** the harmonic structure (Harnack) and the Jacobian of a deformation (curved rays).

Together they answer "how far can this generalize?" — and they point to current research directions (segment tracing, Harnack tracing, curved-ray/nonlinear sphere tracing).
