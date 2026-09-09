# Chapter 12 — Differential Geometry

Once we have a hit point on a surface, everything about lighting depends on **local differential information**: the normal, and to a lesser extent the curvature. For an implicit surface $f=0$ (and especially for an SDF), all of this flows from the gradient. This chapter derives the theory and then the numerical recipes.

## 12.1 The normal of an implicit surface

For a smooth implicit surface $f(\mathbf p)=0$ with $\nabla f\neq \mathbf 0$, the **outward unit normal** is

$$
\mathbf n=\frac{\nabla f}{\lVert\nabla f\rVert}.
$$

**Why.** From Chapter 05, $\nabla f$ is orthogonal to the level set, so it is the normal direction. Normalizing gives the unit normal. The sign convention ("outside positive" field) means $\nabla f$ points away from the solid, i.e. out, so this $\mathbf n$ is the *outward* normal.

**Special case for an exact SDF.** Since $\lVert\nabla d\rVert=1$ almost everywhere, $\mathbf n=\nabla d$ directly (no normalization needed — the normalization becomes a no-op, but we keep it for robustness on non-exact fields).

**Orientation.** If a field is inside-out (e.g. $f$ negated), $\nabla f$ points inward; we must flip the sign for lighting. Difference operations (Chapter 09) can create such inverted regions.

## 12.2 The tangent plane and tangent vectors

The tangent plane at $\mathbf p$ is

$$
T_{\mathbf p}\mathcal S=\{\mathbf v:\mathbf n\cdot\mathbf v=0\}.
$$

A basis of tangent vectors $\{\mathbf t_1,\mathbf t_2\}$ spans the plane; any vector in it is "along the surface." The normal is perpendicular, completing the **local frame** $\{\mathbf n,\mathbf t_1,\mathbf t_2\}$.

**Relevance.** This frame is used to build the tangent-space coordinate system for normal maps, for ray differentials (Chapter 23), and for "curvature-flow" effects (Chapter 16).

## 12.3 Directional derivative and gradient's meaning

Recall

$$
D_{\mathbf u}f=\nabla f\cdot\mathbf u .
$$

Because $\lVert\nabla f\rVert=\max_{\lVert\mathbf u\rVert=1}D_{\mathbf u}f$, the gradient is the direction of steepest ascent and its magnitude is the rate. This is precisely why the normal is the gradient direction.

## 12.4 Curvature of an implicit surface

For a surface oriented by normal $\mathbf n$, the **shape operator** (Weingarten map) captures how the normal changes as you move along the surface. Its eigenvalues are the **principal curvatures** $\kappa_1,\kappa_2$; the **mean curvature** is $H=\tfrac12(\kappa_1+\kappa_2)$ and the **Gaussian curvature** is $K=\kappa_1\kappa_2$.

For an implicit surface, the **mean curvature** has a closed formula in terms of the gradient and Hessian:

$$
H=\frac{\nabla f^T H_f \nabla f - \lVert\nabla f\rVert^2\,\operatorname{tr}H_f}{2\lVert\nabla f\rVert^3}.
$$

For an SDF ($\lVert\nabla d\rVert=1$), this simplifies to

$$
H=\tfrac12\nabla d^T H_d\nabla d-\tfrac12\operatorname{tr}H_d.
$$

**Why curvature matters in rendering.** Curvature drives:

- the size of specular highlights (tight curvature → small, points of high curvature → bright "caustic" bands),
- the AO and normal-filtering behavior,
- the "rounded vs. sharp" feel of an object,
- the volume/subsurface look (a mean-curvature-based approximation, Chapter 16).

**Numerical curvature from a sampled field.** Because the Hessian is expensive and noisy to estimate from a differentiable field numerically, most raymarchers estimate curvature from a few SDF samples rather than from analytic second derivatives.

## 12.5 Numerical normal estimation

In a shader we rarely have an analytic gradient; we estimate the normal by **finite differences**. Given the hit point $\mathbf p$ and a small stroke $\varepsilon$, sample the field at nearby points.

### 12.5.1 Forward/backward differences

$$
\mathbf n_x=\frac{f(\mathbf p+\varepsilon\mathbf e_x)-f(\mathbf p)}{\varepsilon},\quad\text{etc.},
$$

Taking all three gives $\nabla f\approx(n_x,n_y,n_z)$, then normalize. This uses 4 field evaluations (1 center + 3 axis) and is $O(\varepsilon)$ accurate (first order). It is the least accurate but cheapest.

### 12.5.2 Central differences

$$
\mathbf n_x=\frac{f(\mathbf p+\varepsilon\mathbf e_x)-f(\mathbf p-\varepsilon\mathbf e_x)}{2\varepsilon},\quad\text{etc.}
$$

This uses 6 field evaluations and is $O(\varepsilon^2)$ accurate. It is the standard quality/performance balance. It is symmetric and, for a 1-Lipschitz field, gives a reasonable average gradient even near edges/corners (it "smooths" the crease).

### 12.5.3 Tetrahedral sampling (skewed, 4 samples)

Sample at four points forming a tetrahedron:

```
p + e0
p + e1
p + e2
p - (e0+e1+e2)
```

where $e0,e1,e2$ are a set of orthogonal-ish vectors scaled by $\varepsilon$. The normal is estimated from the values at these 4 points. This gets 4 evaluations (one fewer than central, and no duplicated center) but loses a bit of symmetry; it's a middle ground. A common choice (iq) is:

```glsl
vec3 calcNormal(vec3 p, float e){
    const vec2 k = vec2(1.0, -1.0);
    return normalize(
        k.xyy * d(p + k.xyy*e) +
        k.yyx * d(p + k.yyx*e) +
        k.yxy * d(p + k.yxy*e) +
        k.xxx * d(p + k.xxx*e) );
}
```

This uses 4 samples in a tetrahedral configuration.

## 12.6 The epsilon question

The finite-difference $\varepsilon$ must be large enough that the field differences are above floating-point noise, but small enough to resolve the local geometry. The tension:

- Too small → the differences vanish into float rounding; the normal is noisy/garbage.
- Too large → the normal averages over the true curvature, blurring it; sharp features get rounded.

The standard practice: set $\varepsilon$ proportional to a small fraction of the *local scale* (e.g. a fixed value like $1e-3$ to $1e-4$ in scene units, or adaptive). Because the field is 1-Lipschitz, the difference of two samples $\varepsilon$ apart is bounded by $\varepsilon$ times the curvature scale. The optimal $\varepsilon$ is $\mathcal O(\sqrt{\text{float-epsilon}})$ for a central difference if noise dominates, but for graphics we use a visually tuned value.

## 12.7 Adaptive epsilon

For deep scenes, the "surface accuracy" required near the camera is much finer than far away, and the *scale* of the field varies (e.g. after many scale folds). A **relative epsilon** normalizes by the field's local scale. One approach: estimate the local scale by $\epsilon_{\text{rel}}=\epsilon_0 \cdot \max(\lVert\mathbf p\rVert,\ 1)$, or by a per-level factor for fractals. This keeps the normal crisp at all scales.

## 12.8 Analytic gradients

Where the field has a closed form and is differentiable, the **analytic gradient** is exact and precise. Examples:

- Sphere: $\nabla d=\hat{\mathbf p}$.
- Plane: $\nabla d=\mathbf n$.
- Box (on faces): one of the coordinate axes.
- Torus: computable from the chain rule.
- Boolean expressions: use the chain rule through `min`/`max`.

**Applying the chain rule.** For $d'(\mathbf p)=d(T\mathbf p)$, $\nabla d'=J_T^T\nabla d$. For a composition of many maps, multiply Jacobians. For a repetition, the derivative of `mod` is piecewise $\pm1$; for an `abs` fold it's $\operatorname{sign}$; for a translation it's identity.

**Why analytic gradients are best.** They are exact, require fewer samples (no numerical stroking), and give clean normals even on thin/smooth structures. The cost is that they require *deriving* the derivative per scene, which is exactly what a rigorous pipeline lets us do. However, analytic gradients are *not* always cheaper numerically (a single closed-form derivative can be more operations than 4 field calls, depending on the scene).

## 12.9 Comparison of normal methods

| Method | Field calls | Accuracy | Cost | Notes |
|--------|-------------|----------|------|-------|
| Forward diff | 4 | $O(\varepsilon)$ | Low | Cheapest |
| Central diff | 6 | $O(\varepsilon^2)$ | Med | Standard |
| Tetrahedral | 4 | $O(\varepsilon^2)$-ish | Low-med | Good balance |
| Analytic | 1 (derived) | exact | Varies | Best accuracy, requires derivation |

## 12.10 Curvature via sampled normals

To estimate curvature at a hit point, compute the normal at $\mathbf p$ and at a point slightly displaced along a tangent direction, then compare. The **curvature** along a tangent $\mathbf t$ can be estimated from the change in the normal:

$$
\kappa_{\mathbf t}\approx\frac{\lVert\mathbf n(\mathbf p+\epsilon \mathbf t)-\mathbf n(\mathbf p)\rVert}{\epsilon}.
$$

This is used for curvature-driven effects like the height-based normal banding "bevel" shading.

## Exercises

1. **(Derivation)** Derive the normal formula for an implicit surface, using the gradient-orthogonal-to-level-set theorem.
2. **(Derivation)** Using the chain rule, derive the analytic gradient of a translated and rotated sphere, and of the twist-mapped box.
3. **(Geometric)** Construct the tangent basis for the sphere and the torus at a given point.
4. **(Derivation)** Write the mean curvature formula for an implicit surface and simplify for an SDF.
5. **(Implementation)** Implement central-difference and tetrahedral normals; compare the visual and the call count.
6. **(Analytic)** Explain how to choose $\varepsilon$ for a finite-difference normal, and why it's a trade-off between noise and blur.
7. **(Design)** Use the mean-curvature approximation as a material/shading term to enhance "bevels" and edges; explain the math.
