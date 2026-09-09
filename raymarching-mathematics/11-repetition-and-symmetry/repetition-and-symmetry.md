# Chapter 11 — Repetition and Symmetry

The single most productive idea in procedural modeling is:

$$
\text{primitive} + \text{coordinate transformation} + \text{repetition} = \text{complex procedural structure}.
$$

Repetition is a *domain transform* (Chapter 10) that maps space into a lattice of identical tiles. Because it reuses a single primitive SDF, the cost per field evaluation stays small even though the visible structure is enormous. This chapter develops the mathematics of repetition rigorously.

## 11.1 The modulus function

The one-dimensional periodization of a scalar uses the modulo function

$$
\operatorname{mod}(x,a)=\big\lfloor x/a\big\rfloor\text{-based remainder},
$$

specifically $\operatorname{mod}(x,a)=x-a\lfloor x/a\rfloor\in[0,a)$. In GLSL, `mod(x,a)` for positive $a$ returns a value in $[0,a)$. For negative $x$, GLSL's `mod` is defined as $x - a\cdot\text{floor}(x/a)$, which always lies in $[0,a)$ (unlike some languages' remainder). This sign behavior is what makes centered repetition work.

## 11.2 Centered repetition

Naive repetition places the tiling at $[0,a)$. To tile about the origin, use the **centered form**:

$$
x'=\operatorname{mod}\!\left(x+\tfrac a2,\ a\right)-\tfrac a2 .
$$

**Derivation.** Shift $x$ by $+a/2$ so that the origin lands at the center of a tile, take modulus, then shift back. The result lies in $[-a/2,a/2)$, centered on $0$, and is period-$a$ in $x$. Then

$$
d'(\mathbf p)=d\left(\operatorname{mod}(\mathbf p+\tfrac a2,a)-\tfrac a2\right)
$$

is the field of an infinite repetition of the object along the axis. Because `mod` is "translation followed by a cut," and translation is an isometry, the centered repetition is an **exact SDF** along the repeating axis — it is exactly periodic and, within each cell, is the primitive.

## 11.3 Finite repetition

To repeat only a finite number of tiles (say $N$), clamp the index:

$$
x'=x-a\cdot\operatorname{clamp}\big(\operatorname{round}(x/a), -\tfrac N2,\tfrac N2\big) .
$$

Here `round(x/a)` selects the nearest tile, and clamping the tile index gives $N$ tiles with your object in each. This is used for fences, arrays, and "finite lattices."

## 11.4 2D and 3D repetition

Apply the modular repetition on all the spatial axes:

$$
d'(\mathbf p)=d\big(\operatorname{mod}(\mathbf p+\tfrac a2,a)-\tfrac a2\big)
$$

component-wise for the relevant axes. This tiles in 2D (planes, grids) or 3D (lattices, cities). So a single box primitive repeated on three axes becomes a full lattice — the basis of "infinite corridor," "grid tunnels," "city blocks," and architectural arrays.

## 11.5 Radial and rotational repetition

Rotational repetition repeats an object around an axis $n$ times. In the plane perpendicular to the axis, work in polar coordinates:

$$
\theta=\operatorname{atan2}(p_y,p_x),\qquad r=\lVert\mathbf p_{x z}\rVert .
$$

Then wrap the angle into an $n$-fold sector and use the folded angle to evaluate a single "arm":

$$
\theta'=\operatorname{atan2}(p_y,p_x),\qquad
\varphi=\theta'-\tfrac{2\pi}{n}\operatorname{round}\!\left(\tfrac{n\theta'}{2\pi}\right)
$$

so that $\varphi\in[-\pi/n,\pi/n]$, and the arm is at angle $\varphi$. This produces $n$ arms (e.g. a gear, a flower, an $n$-blade fan). 

**About the fold distance.** If the primitive is constructed so that the arm is placed at angle $0$ in canonical coords, rotating back by the wrapped angle gives an **exact SDF** for the single arm; the multi-arm object is then the *union* over arms, which for $n$ identical arms is equivalent to evaluating the single-arm SDF at the wrapped angle (since the object is invariant under the $n$-fold rotation, wrapping the angle and applying the single-arm field gives the correct signed distance to the *rotationally-periodic* object exactly — this is an isometry in the angular coordinate).

## 11.6 Mirrored repetition

Combining modulus with an absolute-value fold produces **mirror repetition** — the object is repeated and mirrored, giving odd/even symmetry:

$$
f(p)=\lvert p\rvert-c .
$$

If the primitive is symmetric under the mirror, then `abs(p)-c` gives a reflected copy with **exact SDF** (reflection is an isometry). Mirror repetition is used to fold a shape into a symmetric lattice and is the backbone of the *Mandelbox box fold* (Chapters 19) and of kaleidoscopic symmetry.

## 11.7 Hierarchical and nested repetition

Repetition is composite. You can repeat a primitive, then repeat the *result*, creating **hierarchical repetition**:

$$
d'( \mathbf p)=d\Big(T\big(T(\mathbf p)\big)\Big).
$$

More interesting, you can repeat at *different scales* along different levels. The classic **KIFS** (Kaleidoscopic Iterated Function System) uses scale-and-repeat to build self-similar structures: scale space (uniform scaling is an exact-SDF-preserving isometry), then fold, then repeat, iteratively:

```
p = p * s + offset
p = fold(p)       # reflect into a fundamental domain
p = abs(p) - c    # mirror fold
d = boxfold-like(p)  # ...
```

At each level the offsets produce detail at a coarser-to-finer scale, so the final field is a **fractal**. Because scaling is exact SDF-preserving (uniform) but folding+offset is not always exactly 1-Lipschitz, KIFS fields are generally **distance bounds / estimators** — which is fine, and we scale the output by the per-level scale factor to keep it safe.

## 11.8 Symmetry as a design principle

The deepest use of repetition is **symmetry-guided design**. Every natural or man-made structure has a symmetry group, and expressing the object in a coordinate system adapted to that group makes the description tiny. The framework is:

> Identify the symmetry group. Pick coordinates in which the group's action is simple (e.g. polar for rotational symmetry). Build a *fundamental domain* (a single copy of the object). Apply the group to repeat it.

This is why so much procedural art reduces to a few lines: the complexity is carried by the *repetition*, not by explicit modeling.

## 11.9 The cost trade-off

Repetition is nearly free: evaluating one primitive per field call, regardless of how many visible copies. The cost is bounded by the number of *transform operations* per call, not by the number of objects. That is the whole reason procedural worlds can look infinite with a trivial cost model (Chapter 25).

## 11.10 Summary of repetition operations and their distance classes

| Operation | Transform | Exact SDF? | Notes |
|-----------|-----------|------------|-------|
| Centered repetition (axis) | `mod(p+a/2,a)-a/2` | Yes | Period-perfect, isometry per cell |
| Full 3D repetition | component-wise mod | Yes | Lattices, cities |
| Finite repetition | clamped tile index | Yes | Fences, arrays |
| Radial repetition | wrapped angle in polar | Yes (per arm) | Gears, flowers |
| Mirror repetition | `abs(p)-c` | Yes (if symmetric) | Kaleidoscope, box fold |
| Hierarchical (KIFS) | scale+fold+repeat | Usually bound | Fractals |

## Exercises

1. **(Derivation)** Derive the centered repetition formula and verify it is period $a$ and lies in $[-a/2,a/2)$.
2. **(Derivation)** Show that repetition along an axis is an exact SDF (translate, cut, translate back).
3. **(Design)** Build a gear with $n$ teeth using a single arm and radial repetition. Explain why the field is exact along the arm.
4. **(Analytic)** Explain how mirror repetition via `abs(p)-c` can create odd/even symmetry and why it's an isometry.
5. **(Implementation)** Implement a 3D lattice (repeat a box on all axes) and an infinite corridor; discuss the field class and the two scenes' difference.
6. **(Design)** Use scale+fold+repeat to build a self-similar (KIFS) structure. State whether the result is an exact SDF, and what you would scale it by to keep it safe.
