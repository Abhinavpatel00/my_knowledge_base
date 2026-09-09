# Chapter 10 — Domain Transformations

The most far-reaching idea in procedural geometry is this: **instead of changing the object, transform the space in which the object is evaluated.** Given a field $d$ and a map $T$, define

$$
d'(\mathbf p)=d\big(T(\mathbf p)\big).
$$

This chapter is about what $T$ can be, which $T$ preserve the distance property (and therefore the safety of sphere tracing), and which do not. The classification of the resulting field — exact SDF, bounded distance field, distance estimator, or arbitrary scalar field — is the whole point.

## 10.1 The master principle

Think of the field as "a function on space." The set $\{d'\le0\}$ is the preimage under $T$ of the set $\{d\le0\}$. In other words, the object in the *new* space is exactly the object that, under $T$, maps onto the *old* object. This is a *space deformation*: we bend, fold, stretch, repeat, and twist space, and the object bends with it.

The algebraic consequence we use constantly:

> To place a primitive at the $T$-image of its canonical position, evaluate the primitive at the inverse-transformed sample: $d'( \mathbf p)=d(T^{-1}\mathbf p)$.

This "inverse transform trick" is the standard implementation.

## 10.2 Which transformations are isometries?

$T$ is an **isometry** if it preserves distances: $\lVert T(\mathbf p)-T(\mathbf q)\rVert=\lVert\mathbf p-\mathbf q\rVert$ for all $\mathbf p,\mathbf q$. For such $T$,

$$
d'( \mathbf p)=d(T(\mathbf p))
$$

is an **exact SDF** (because composing an SDF with a distance-preserving map preserves the 1-Lipschitz property and the zero set correspondence).

The isometries of Euclidean 3-space are exactly the *translations, rotations, and reflections* (and their compositions). These are **safe to use unconditionally** — they preserve the distance property exactly.

### Translation

$T(\mathbf p)=\mathbf p-\mathbf c$. Then $d'(\mathbf p)=d(\mathbf p-\mathbf c)$. Exact SDF.

### Rotation

$T(\mathbf p)=R\mathbf p$ with $R$ orthogonal ($R^TR=I$). Exact SDF. (See Chapter 02 for rotation matrices.)

### Reflection

$T(\mathbf p)=F\mathbf p$ with $F$ an orthogonal reflection. Exact SDF. Reflection is how we build symmetric scenes and how we implement *mirror repetition* and *box folding*.

## 10.3 Uniform scaling

$T(\mathbf p)=s\mathbf p$ for a scalar $s>0$. The map scales all distances by $s$, so the distance field transforms as

$$
d'(\mathbf p)=s\,d(\mathbf p/s).
$$

**This is an exact SDF**, because $d$ is 1-Lipschitz and the composition scales the field by $s$ but also scales the spatial measure by $s$. The key identity: if $d$ is exact, then $d'$ is exact (you can verify $\lVert\nabla d'\rVert=1$). This is used to scale scenes and to implement "scale folds" in KIFS.

## 10.4 Non-uniform scaling and the Jacobian

$T(\mathbf p)=D\mathbf p$ with $D=\operatorname{diag}(d_1,d_2,d_3)$, not all equal. Then

$$
d'(\mathbf p)=d(D\mathbf p),
$$

and $\nabla d'=D\nabla d$, so $\lVert\nabla d'\rVert$ is *not* 1 in general. The result is an **anisotropic distance bound** — it overestimates or underestimates distance depending on the axis. Specifically, if $D$ has entries $d_i$, then

$$
\rVert\nabla d'\rVert\le \max_i d_i ,
$$

so $d'$ is Lipschitz with constant $M=\max_i d_i$; the *safe* step is $d'/M$. This is the classic "box" problem: an ellipsoid built by scaling a sphere is not an exact SDF.

**The correction.** To get an exact distance to an ellipsoid, one cannot simply use `length(p*s)-r`. The exact ellipsoid SDF requires an iterative or polynomial solution. In practice, raymarchers use the scale-with-bound approach (a scaled sphere as a distance *bound*, then rely on the marcher being conservative) or a dedicated ellipsoid SDF.

## 10.5 Shearing

$T(\mathbf p)=\begin{pmatrix}1&\lambda&0\\0&1&0\\0&0&1\end{pmatrix}\mathbf p$. This is a linear map, not orthogonal; it does not preserve the metric. The result is a **distance bound**; the safe step must be scaled by the operator norm of the shear matrix (its largest singular value).

## 10.6 Repetition: the modulus transform

Repetition is a domain transform that maps space into an infinite tiling. Define, along one axis,

$$
T_1(\mathbf p)=\operatorname{mod}(\mathbf p,\ a)\ -\ \tfrac{a}{2}
$$

or, better, the *centered* repetition:

$$
T_1(\mathbf p)=\operatorname{mod}\!\left(\mathbf p+\tfrac a2,\ a\right)-\tfrac a2 .
$$

Then $d'(\mathbf p)=d(T_1(\mathbf p))$ is periodic with period $a$; the field in the central tile is the primitive, and the tiles repeat infinitely. This is an **exact SDF** (because `mod` with a centering shift is a translation-fold, and translation is an isometry) — but only along the axis. The modulus map is "distance preserving up to the fold," and along the repetition dimension the field is exactly periodic.

**Full 3D repetition** applies this on all three axes. This is the source of grilles, lattices, cities, and tiled surfaces (Chapter 11).

## 10.7 Folding (mirror repetition)

Mirror folding is an isometry applied per-cell:

$$
T(\mathbf p)=\lvert\mathbf p\rvert
$$

in one coordinate — but that's a reflection only if the primitive is symmetric about the fold plane. Let $p_i'=\lvert p_i\rvert-c$ for a fold at $c$. This reflects the coordinate so that the primitive is mirrored across the plane $p_i=c$. Such folding is an isometry (reflection) and thus **preserves exact SDF**: $d'(\mathbf p)=d(\lvert p_i\rvert-c)$ is exact for a primitive symmetric under $p_i\mapsto-p_i$.

Folding is the mechanism behind *box folding* (the Mandelbox, Chapter 19), *mirror repetition*, and *kaleidoscopic symmetry*.

## 10.8 Twisting

Twist about the $y$-axis by an angle proportional to height:

$$
\theta=k\,p_y,
\qquad
\begin{pmatrix}x'\\y'\\z'\end{pmatrix}
=
\begin{pmatrix}
x\cos\theta-z\sin\theta\\ y\\ x\sin\theta+z\cos\theta
\end{pmatrix}.
$$

**Interpretation.** Each height slices through a progressively rotated copy, so a prism or box becomes a helical column. The transformation couples rotation angle to position, so it is **not isometric** — it is a distance-deforming map. The resulting field is a **distance bound**, but typically a *conformal* one, and in practice it is used as a bound/estimator, sometimes scaled by a Jacobian-derived factor.

**Why it's a bound.** The Jacobian of the twist has operator norm $>1$ away from the axis, so gradients can exceed 1, so the raw field may overestimate distance and overshoot. Raymarchers compensate with a scale factor (a conservative shrinkage) or accept the bound.

## 10.9 Bending

Bend a "column" along an axis into an arc:

```
   |         |         \
   |   →     |   →      )
   |         |        /
```

A common bending map takes a point in terms of its distance from a line and maps it by a rotation whose angle is proportional to the arc-length coordinate. For bending the $y$-axis,

$$
\theta = \frac{p_y}{s},\qquad
\begin{pmatrix}x'\\y'\\z'\end{pmatrix}
=
\begin{pmatrix}
\sin\theta\,(c-x)+x\\ \cos\theta\,(c-x)-c\\ z
\end{pmatrix},
$$

with center-of-curvature parameter $c$. Bending is **not isometric**; it is a re-folding of space that preserves lengths *along* the bend but distorts across the bend, so the field is a **distance bound/estimator**. Used to create organic arcs, roads, and "bent" architecture.

## 10.10 Tapering

Taper a shape so its cross-section shrinks with height:

$$
T(\mathbf p)=\begin{pmatrix}p_x\,f(p_y)\\ p_y\\ p_z\,f(p_y)\end{pmatrix},
$$

$f$ a taper function (e.g. linear or a smooth profile). This is a non-uniform scaling that varies with height, hence **not isometric**; it's a distance bound. It creates vases, fins, and organic tapering.

## 10.11 Nonlinear coordinate changes: polar, spherical, cylindrical warping

Wrapping space in polar/spherical coordinates produces vortices, spirals, and radial structures. Two main families:

1. **Radial fold / polar fold.** Work in the $(r,\theta)$ plane and fold or wrap $\theta$: `angle = atan2(p.y,p.x)`, then apply a fold, e.g. intersect the wedge, or map angle outward. This produces *radial repetition* and *spiral arms*.
2. **Vortex / spiral.** Add a phase to the angle proportional to radius or height: $\theta'=\theta+k r$. In Cartesian terms this is a shear in polar coordinates — **not isometric**, a distance bound.

The key mathematical point: **using polar coordinates to *describe* an object is an isometry (it's just a re-labeling of Euclidean space); using the polar map to *deform* space is generally not.** We must be explicit about which we are doing.

## 10.12 The four-level classification (repeat of the critical table)

| Category | Defined by | What the marcher may do |
|----------|-----------|-------------------------|
| **Exact SDF** | $\lVert\nabla d\rVert=1$ a.e. | Step by the full value. |
| **Bounded distance field** | $\lVert\nabla d\rVert\le1$ (a true bound) | Step by the value (conservative). |
| **Distance estimator** | approximately $d$, may exceed | "Almost" — only safe with a scale factor or a known bound. |
| **Arbitrary scalar field** | no metric meaning | Nothing safe. |

Every transformation in this chapter lands in one of these four buckets. The engineering skill is to know which bucket you are in and to compensate accordingly (scale the step by the field's Lipschitz constant, or shrink the field).

## 10.13 The general rule for distance properties

For a map $T$ with Jacobian $J_T$,

$$
\lVert\nabla d'\rVert=\lVert J_T^T\nabla d\rVert\le\sigma_{\max}(J_T)\ ,\qquad \sigma_{\max}=\text{largest singular value}.
$$

So:

- If $\sigma_{\max}(J_T)\le1$ everywhere (a contraction / isometry), $d'$ is a **bound**.
- If $T$ is an isometry, $\sigma_{\max}=1$ everywhere, and $d'$ is **exact**.
- If $\sigma_{\max}>1$ somewhere, $d'$ can overestimate distance; the safe step is $d'/\sigma_{\max}$.
- If $T$ is not even a contraction, the field is just an **estimator**.

This single inequality tells us, for any transform, whether we have safety and how much speed we lose.

## 10.14 Worked example: scaling a sphere into an ellipsoid

$d(\mathbf p)=\lVert\mathbf p\rVert-1$ (unit sphere). Let $T(\mathbf p)=D\mathbf p$ with $D=\operatorname{diag}(1,2,3)$. Then $\lVert\nabla d'\rVert\le3$, so the safe step is $d'/3$, and $d'$ is a **bound**, not exact. The ellipsoid's surface is the image $D(S^2)$ — correct as a shape, but the field is not a true distance. This is the classic trade-off that makes ellipsoids slightly "mushy" in naive raymarchers.

## Exercises

1. **(Derivation)** Prove that a translation composes with an exact SDF to give an exact SDF.
2. **(Derivation)** Show that uniform scaling $d'(\mathbf p)=s\,d(\mathbf p/s)$ yields $\lVert\nabla d'\rVert=1$.
3. **(Derivation)** For non-uniform scaling by $D$, derive the Lipschitz constant $\max_i d_i$ and the safe-scaling factor.
4. **(Analytic)** Compute the Jacobian of the twist and its largest singular value; state the safe-step factor along the axis vs. off-axis.
5. **(Implement)** Implement centered repetition along one axis and use it to build an infinite row of spheres; verify the field period.
6. **(Analytic)** Classify each of these as exact SDF / bound / estimator and justify: (a) translated sphere, (b) scaled-ellipsoid, (c) twisted box, (d) `abs` fold, (e) repeated torus.
7. **(Design)** Using only a sphere, a twist, and repetition, build a helical column. Explain whether the field is exact and what you would do to keep it safe.
