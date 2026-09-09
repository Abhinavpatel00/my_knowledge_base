# Shader Breakdown 8 — Triplanar Mapping, Higher-Dimensional SDFs, and Ray Differentials

This breakdown covers three showpieces of advanced shader construction: **triplanar mapping** (a projection-based texture technique with a clean mathematical justification), **higher-dimensional SDFs** (rendering objects embedded in 4D+), and **ray differentials** for filtering. These are the tools that make procedural surfaces *look* finished.

## 8.1 Triplanar mapping

**The problem.** A normal 3D position $(x,y,z)$ cannot be mapped to a single UV without distortion and seams. Triplanar solves this by blending three axis-aligned planar projections.

**The mathematics.** For a point $\mathbf p$ and a procedural pattern $g:\mathbb R^2\to\mathbb R$, evaluate three projections and blend by the *normal's axis weights*:

$$
\text{color}(\mathbf p)=
w_x\,g(p_y,p_z)+w_y\,g(p_x,p_z)+w_z\,g(p_x,p_y),
$$

where the weights are
$$
w_i=\frac{|n_i|^k}{|n_x|^k+|n_y|^k+|n_z|^k},\qquad k\ge1 .
$$

**Interpretation.** $w_i$ is the fraction of the surface's "facing direction" along axis $i$. A surface whose normal points mostly along $+x$ is sampled with the $x$-projection; where the normal is diagonal, all three blend. The weight exponent $k$ tightens the blend (higher $k$ = sharper transition between the three projections).

**Why it avoids seams.** The function $g$ is evaluated in a *local* 2D frame (the tangent plane projection for each axis). Because $g$ is periodic/lattice-based, the projections are continuous, and the blended result is continuous across the "cube corners" where the axis switches. The key normalization: $\sum_i w_i=1$, so it's a convex combination — no over-brightening.

**The field-class point.** Triplanar is purely a *shading/texturing* technique. It does not touch the distance field or the geometry. The point is textured by a procedural pattern; the SDF that defines the surface is unchanged. So triplanar mapping is orthogonal to the distance machinery.

**Cost.** Three pattern evaluations per pixel (one per axis) instead of one. The weights cost a couple of divisions. This is a common, acceptable price for seam-free procedural texturing.

### 8.1.1 Extensions
- **Derivative triplanar.** Evaluate $g$ with its gradient (via analytic derivative noise, Ch. 17) and blend the *gradients* too, so the normal perturbation of the texture is blended consistently.
- **Warped triplanar.** Warp the three projection planes with fBm before sampling (Ch. 16), so the texture "flows" over the surface — the goo/marble extension.
- **Triplanar for displacement.** Displace the *surface* along the normal using the triplanar pattern (a displacement, Ch. 16) → a "carved"/sculpted surface.

## 8.2 Higher-dimensional SDFs

**The idea.** Render an object defined by an implicit field in $\mathbb R^4$ (or higher) by *slicing* it — i.e. fixing an extra coordinate. If $d:\mathbb R^4\to\mathbb R$ is a distance field, then for a fixed "slice parameter" $w$ we get a 3D field $\mathbf p\mapsto d(\mathbf p,w)$, whose zero-set is the 3D cross-section of the 4D object.

**Why it's mathematically clean.** The 4D distance field, restricted to a 3D "slice," is exactly the distance to the cross-section *in that 3D hyperplane* — because the restriction of an SDF to an affine subspace of one lower dimension is a valid SDF of the slice (the metric is inherited). So we can ray-march a 4D object's cross-section with no additional machinery.

**Applications.**
- **4D Julia sets.** A quaternion Julia set is 4D; slicing gives stunning 3D cross-sections (Chapter 19). The quaternion power $z\mapsto z^2+c$ is evaluated in $\mathbb H$; the slice at a fixed `w` (or a fixed quaternion component) gives a 3D fractal.
- **Time as a 4th dimension.** Treat time $t$ as the 4th coordinate of a 4D SDF and slice at the current $t$. This *is* the clean way to do certain (topology-changing) animations: the object's evolution is a 4D object, and the current frame is a slice. The motion is automatically smooth if the 4D field is.
- **Morphing / topology change.** A 4D shape interpolating between two topologies, sliced in time, gives a continuous morph that may change topology — the rigorous mathematical setting for "a blob splits into two."

### 8.2.1 The "how do I get an extra dimension" question
The distance field's value is already $d(\mathbf p)\in\mathbb R$; the *independent* variable is the domain. To add a dimension, make the field depend on a parameter that you then slice:

$$
d_4(\mathbf p,\mathbf w),\qquad \text{slice at }\mathbf w=\mathbf w_0.
$$

For animation, $\mathbf w$ is time. For a quaternion Julia, $\mathbf w$ is a quaternion component. For a "4D crystals," $\mathbf w$ is a rotation/orientation parameter.

### 8.2.2 Extensions
- **Hyper-polyhedra.** Render the 3D cross-sections of 4D polytopes (hypercube, 24-cell, etc.) by slicing their 4D distance fields.
- **Warping in 4D.** Warp the 4D field before slicing for high-complexity morphs.
- **Higher than 4.** The machinery generalizes; only the interpretation of the "extra" dimensions changes (e.g. multiple animation parameters as extra coordinates).

## 8.3 Ray differentials for filtering

**The idea.** A ray differential $\partial\mathbf r/\partial x$ (and $\partial/\partial y$) tells us how the ray changes as we move one pixel. This gives the **footprint** of the ray on the surface, which is exactly the region a pixel covers.

**The perspective-camera case.** For a pinhole camera, $\mathbf o$ is fixed and $\mathbf d$ varies linearly with the pixel coordinate, so $\partial\mathbf o/\partial x=0$ and $\partial\mathbf d/\partial x\propto\mathbf r$ (constant). Hence the surface footprint grows with distance — a distant surface covers a large screen footprint.

**Why it matters for filtering.** A high-frequency procedural texture on a distant surface produces **aliasing** (the "sparkle"/moiré). If we know the footprint size, we can **band-limit** the texture to that size — i.e. sample the pattern at a scale matched to the footprint instead of the raw pixel, so no pixel-frequency information is aliased. This is the "ray differential" filtering technique of Quilez and classic applied graphics.

**Implementation sketch.** At the hit point, compute $\partial\mathbf p/\partial x$ and $\partial\mathbf p/\partial y$ from the ray differentials; then, when evaluating the procedural pattern, use the *footprint* (max of the two) as the texture frequency / the noise's base scale:
$$
\text{footprint}\approx\max\big(\lVert\partial\mathbf p/\partial x\rVert,\lVert\partial\mathbf p/\partial y\rVert\big).
$$
Then, e.g., for a lattice/periodic pattern, choose the number of octaves (for FBM) or the filter width so that frequencies above $1/\text{footprint}$ are suppressed.

### 8.3.1 The relationship to mipmapping / aniso
This is the SDF analogue of choosing a mip level by the texture footprint. It is the principled way to anti-alias a *procedural* (not sampled) texture, which has no mip chain. The "best" filter is to integrate the pattern over the footprint; since that's expensive, band-limiting via band-limited noise / choosing octave count is the practical approximation.

### 8.3.2 Extensions
- **Analytic footprint.** For a periodic $\sin$ pattern, filter analytically (the sinc/the quadratic aperture) for a clean result.
- **FBM with footprint.** At each octave, stop adding octaves once the octave frequency exceeds $1/\text{footprint}$. This gives *distance-adaptive* detail — high detail near, low detail far. This removes the classic "noise shimmer" in raymarched scenes.

## Exercises

1. **(Derivation)** Derive the triplanar weights and show $\sum_i w_i=1$; explain the role of the exponent $k$.
2. **(Analytic)** Explain why triplanar is a *shading* technique that does not affect the SDF/field class.
3. **(Derivation)** Show that restricting a 4D SDF to a 3D slice gives a valid 3D SDF (the metric is inherited).
4. **(Design)** Use a 4D field with time as the 4th coordinate to produce a smooth, topology-changing morph; explain the rigor.
5. **(Derivation)** Derive the ray differential for a pinhole camera and the surface footprint.
6. **(Analytic)** Explain why band-limiting procedural texture via the footprint reduces aliasing, and why this is the analogue of mipmapping.
7. **(Implementation)** Implement an FBM whose octave count is capped by the footprint; describe the reduction in shimmer.
