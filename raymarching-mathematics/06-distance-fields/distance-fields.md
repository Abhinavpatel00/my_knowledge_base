# Chapter 06 — Distance Fields

This chapter constructs the mathematical theory of signed distance fields (SDFs), and — just as important — the theory of *what they are not*. The taxonomy of exact SDF, distance bound, distance estimator, and arbitrary scalar field is the backbone of safe raymarching.

## 6.1 Unsigned distance

**Definition.** Let $S\subset\mathbb R^3$ be nonempty. The **unsigned distance** to $S$ is

$$
d(\mathbf p,S)=\inf_{\mathbf q\in S}\lVert\mathbf p-\mathbf q\rVert .
$$

This is always nonnegative, symmetric, and 1-Lipschitz in $\mathbf p$ (by the reverse triangle inequality). It is the *unsigned* version because it gives no information about whether $\mathbf p$ is inside or outside a solid.

## 6.2 Signed distance

For a solid $\Omega$ with surface $\partial\Omega$, define

$$
d(\mathbf p)=
\begin{cases}
-\operatorname{dist}(\mathbf p,\partial\Omega), & \mathbf p\in\Omega \text{ (inside)},\\
+\operatorname{dist}(\mathbf p,\partial\Omega), & \mathbf p\notin\Omega \text{ (outside)}.
\end{cases}
$$

**Convention.** Negative is inside, positive is outside, zero is the boundary. The sign is a *choice*; it must be set consistently, and it must be consistent with the boolean algebra (Chapter 09) and the normal orientation (Chapter 12).

**Interpretation.** $d(\mathbf p)$ is the radius of the largest open ball centered at $\mathbf p$ that does not cross the surface, with the sign telling you which side of the surface you are on. On the boundary itself, $d=0$.

## 6.3 The eikonal property

**Theorem (eikonal).** For a signed distance function, away from the set of points where the nearest-surface point is non-unique,

$$
\lVert\nabla d\rVert=1 .
$$

**Why.** $\nabla d$ points in the direction of steepest increase of $d$. Consider the point $\mathbf q\in S$ nearest to $\mathbf p$, and the unit vector $\mathbf u=(\mathbf p-\mathbf q)/\lVert\mathbf p-\mathbf q\rVert$ pointing *away* from the surface. Moving from $\mathbf p$ a tiny distance $\epsilon$ further away along $\mathbf u$ increases $d$ by exactly $\epsilon$ (the nearest point is still $\mathbf q$, approximately). Moving in *any other direction* increases $d$ by less. Therefore the directional derivative in direction $\mathbf u$ is $1$, and it is the maximum directional derivative, so $\lVert\nabla d\rVert=1$. $\blacksquare$

This is the single most important property for raymarching: **the gradient of an SDF has unit length**, so SDFs are exactly 1-Lipschitz, so their values are safe step lengths.

## 6.4 The 1-Lipschitz guarantee

**Corollary.** A signed distance function satisfies, for all $\mathbf p,\mathbf q$,

$$
\lvert d(\mathbf p)-d(\mathbf q)\rvert\le\lVert\mathbf p-\mathbf q\rVert .
$$

(Follows from the reverse triangle inequality applied to the nearest points.) This bound is what makes sphere tracing safe — see Chapter 07.

## 6.5 Non-differentiability: medial axes, edges, corners

Do not pretend every SDF is smooth. The eikonal property $\lVert\nabla d\rVert=1$ holds only **almost everywhere**. The exceptions are the points where the nearest surface point is not unique.

**Definition (medial axis).** The **medial axis** of $S$ is the set of points whose distance to $S$ is realized by *more than one* nearest point. At a medial-axis point the gradient of $d$ is discontinuous (there is a "ridge" in the field).

**Examples.**

1. **A box.** Near an edge, the nearest point on the surface jumps from one face to another; on the plane of symmetry the gradient is discontinuous. The standard box SDF (Chapter 08) is a piecewise construction that handles this.
2. **Two-point distance (a line segment).** Above the midpoint of a segment, the field has a medial axis (the perpendicular bisector). The capsule SDF is $\mathcal C^0$ across it but not $\mathcal C^1$.
3. **A sphere.** The origin is the only medial-axis point (interior); outside the sphere $d$ is smooth, inside it is smooth except at the center.

**Consequence for normals.** At edge/corner/medial-axis points, the *analytical* gradient does not exist or is set-valued; the *numerical* gradient (central differences, Chapter 12) returns some average direction. This is the source of the small, controlled artifacts we accept in practice — but it is a *mathematical fact*, not a bug.

## 6.6 The taxonomy the book enforces (repeat of the crucial table)

| Object | Symbol | Property | Safe to step by? |
|--------|--------|----------|------------------|
| Exact SDF | $d$ | $\lVert\nabla d\rVert=1$ a.e. | Yes, by the value. |
| Distance bound | $\hat d$ | $\hat d(\mathbf p)\le d(\mathbf p)$ | Yes (it is conservative). |
| Distance estimator | $D$ | $D\approx d$ | Only if it's a true bound; otherwise "almost." |
| Arbitrary scalar field | $f$ | — | No, unless you know a Lipschitz constant. |

The whole craft of *safe* raymarching is the art of producing fields in the first two rows while the *aesthetics* of many effects comes from the third and fourth.

## 6.7 Why scale factors break exactness

If we scale an SDF by a constant $\lambda$, the result is *not* an SDF; it is a distance bound scaled by $\lvert\lambda\rvert$. Because a *nonuniform* scale changes the metric, an anisotropic transform generally destroys the SDF property. For a **uniform** scale by $s$, we have

$$
d'( \mathbf p)=s\,d(\mathbf p/s),
$$

which is still a signed distance (the identity of the sphere shows this). For a **nonuniform** scale, the result is at best a distance bound with a known Lipschitz constant for each coordinate axis (see Chapter 10 for the exact rescaling factors).

## 6.8 Signed distance as a "potential" — and why it's different

Do not equate an SDF with a *potential* or *density* field. A scalar function $\rho$ that represents density or potential does **not** satisfy $\lVert\nabla\rho\rVert=1$ and does **not** give a safe step. The smooth boolean output, a noise field, an electrostatic potential — these are not distances. Only the distance structure (eikonal/1-Lipschitz) carries safety.

## 6.9 Representing SDFs procedurally

The reason raymarched scenes are so rich is that an SDF can be defined by *an algorithm*, not just a closed formula. Composition (Chapter 09), domain transformation (Chapter 10), repetition (Chapter 11), and iteration (Chapters 19–20) let us build distance fields whose complexity rivals explicit geometry — but from a handful of primitive ingredients. Each of these operations must be checked against the exactness taxonomy: some preserve it exactly (isometries, `min` for union of exact SDFs), some preserve it as a *bound* (smooth union, scaling of a bound), and some only give an *estimator* (fractal DEs).

## Exercises

1. **(Calculation)** For the unit sphere centered at the origin, write $d(\mathbf p)$ for interior and exterior points, and verify $\lVert\nabla d\rVert=1$ away from the origin.
2. **(Derivation)** Prove the 1-Lipschitz property of the unsigned distance using the reverse triangle inequality.
3. **(Derivation)** Show that for a uniform scale $s$, $d'(\mathbf p)=s\,d(\mathbf p/s)$ is a signed distance.
4. **(Geometric)** Sketch the medial axis of a line segment, a box, and a letter "L" (union of two boxes). Where is $\nabla d$ discontinuous?
5. **(Analytic)** Show that $\hat d(\mathbf p)=\lambda d(\mathbf p)$ with $\lambda<1$ is a distance *bound* (not exact), and that with $\lambda>1$ it is *not* a safe bound because it can overshoot the surface.
6. **(Design)** Which row of the taxonomy does a "smooth union" output belong to, and why? Which row does a Mandelbulb distance estimator belong to, and what does that imply about safety?
