# Chapter 05 — Implicit Surfaces

A surface can be defined explicitly (as a graph $z=h(x,y)$), parametrically (as $\mathbf x(u,v)$), or **implicitly**, as the zero set of a scalar function. Implicit form is what raymarching uses. This chapter establishes the mathematics of implicit surfaces: how a function defines a surface, what the gradient tells us, and what can go wrong.

## 5.1 Definition

An **implicit surface** is the level set

$$
\mathcal S=\{\mathbf p\in\mathbb R^3\,:\,f(\mathbf p)=0\}
$$

for a scalar function $f:\mathbb R^3\to\mathbb R$. The companion **solid** (for a closed surface) is conventionally

$$
\Omega=\{\mathbf p\,:\,f(\mathbf p)\le 0\},
$$

so the surface is $\partial\Omega=\{\mathbf p:f(\mathbf p)=0\}$. This "outside positive" convention is standard in raymarching.

**Important distinction.** $f$ is a *real-valued function*, not a distance. Its zero level set is the surface. But $f$'s values away from the zero set are arbitrary unless we impose more structure (Chapter 06 adds the distance structure). This is the crux of the whole book: **an implicit surface and a signed distance field are different objects.** The former only needs a zero level set; the latter needs the value at every point to carry metric meaning.

## 5.2 The gradient is normal to the level set

This is the foundational theorem for everything in the rendering chapters.

**Theorem.** If $f$ is differentiable at $\mathbf p$ with $\nabla f(\mathbf p)\neq\mathbf 0$, then $\nabla f(\mathbf p)$ is perpendicular to the level set of $f$ through $\mathbf p$.

**Proof sketch.** Take any $\mathcal C^1$ curve $\boldsymbol\gamma(t)$ lying in the level set $f^{-1}(c)$ with $\boldsymbol\gamma(0)=\mathbf p$. Then $f(\boldsymbol\gamma(t))=c$ identically, so differentiating and applying the chain rule:

$$
0=\frac{d}{dt}f(\boldsymbol\gamma(t))\big|_{t=0}=\nabla f(\mathbf p)\cdot\boldsymbol\gamma'(0).
$$

This holds for the tangent vector $\boldsymbol\gamma'(0)$ of *every* curve through $\mathbf p$ in the level set, so $\nabla f(\mathbf p)$ is orthogonal to the full tangent plane. Hence it is normal to the surface. $\blacksquare$

**Corollary.** If $f$ is a signed *distance* (Chapter 06), then $\lVert\nabla f\rVert=1$ away from singularities, and the unit normal is

$$
\mathbf n=\frac{\nabla f}{\lVert\nabla f\rVert}.
$$

Since the gradient is normal anyway, and for a distance function it already has unit length, for an exact SDF the normal is simply $\mathbf n=\nabla f$.

## 5.3 Regular values and submanifolds

The **implicit function theorem** says: if $\mathbf p$ is on the level set $f=c$ and $\nabla f(\mathbf p)\neq\mathbf 0$, then near $\mathbf p$ the level set is a smooth $\mathcal C^1$ **surface** (a 2-manifold). Such values $c$ are called **regular values**. If $\nabla f$ fails to be nonzero, the level set can be a self-intersection, a cusp, a corner, or have a different dimension.

**Non-regular points are exactly where implicit surfaces become interesting and problematic.** Consider

- $f(x)=x^2$: the zero set is a single point, $\nabla f(0)=0$. Degenerate.
- $f(x,y)=x^2-y^2$: the zero set is two crossing lines; at the origin $\nabla f=0$ (a self-intersection).
- $f(x,y,z)=x^2+y^2-z^2$: the zero set is a double cone; at the apex the gradient vanishes.

For distance fields, the gradient can be discontinuous or vanish at the **medial axis** or along **edges** and **corners** (Chapter 06). Recognizing that an SDF is *not differentiable everywhere* is essential: it is what causes the marching algorithm to need an epsilon band (Chapter 07) and what produces sharp highlights and hard edges in the image.

## 5.4 Inside/outside and orientation

The sign of $f$ determines which side is inside. With the "outside positive" convention, $f<0$ is interior, $f>0$ exterior, $f=0$ the boundary. When we negate $f$ (a reflection/inside-out), orientation flips. This matters for **boolean differences** ($A\setminus B = A\cap\bar B$) where we use $f_B$ negated (Chapter 09).

## 5.5 Smoothness classes and their visual consequences

| Class | Definition | Visual consequence |
|-------|------------|--------------------|
| $\mathcal C^0$ | Continuous; geometry may have sharp edges | Hard facets, but no crack/gap |
| $\mathcal C^1$ | Continuous first derivative | Smooth shading but possible curvature discontinuities |
| $\mathcal C^2$ | Continuous second derivative | Smooth, no specular "kinks" |

Most exact SDF primitives are piecewise $\mathcal C^1$ or smoother (e.g. a sphere is $\mathcal C^\infty$, a box is $\mathcal C^0$ across its edges but $\mathcal C^1$ on faces). Smooth boolean operations (Chapter 09) are designed precisely to raise these to $\mathcal C^1$ (or higher) so that normals vary continuously.

## 5.6 The role of $f$'s magnitude in raymarching

To raymarch we need to know, at a point on a ray, *how far we can safely step.* That information is **not** in a generic implicit function. It appears only when $f$ is a distance (or distance bound). This is the essential reason the book separates implicit surfaces (Chapter 5) from distance fields (Chapter 6). A pure implicit surface gives it no step information; a signed distance field gives an exact safe step.

## 5.7 From implicit to distance: the "reparameterization" insight

For any implicit surface $f=0$, one can construct a related distance function by *raycasting along the normal* or by the eikonal equation. But in practice we build distance fields *directly* by design, choosing $f$ to already be a signed distance. The cleanest way to think about the difference:

$$
\text{implicit surface}: f=0 \quad\text{(only the zero set matters)}
$$

$$
\text{SDF}: f=\text{signed distance}\quad\text{(values carry metric meaning, }\lVert\nabla f\rVert=1\text{ a.e.)}
$$

A signed distance field *is* an implicit surface with the extra 1-Lipschitz (eikonal) structure. All the power of raymarching follows from that extra structure.

## Exercises

1. **(Derivation)** Prove that $\nabla f$ is orthogonal to the level set using the chain rule along a curve.
2. **(Derivation)** Show that the gradient points in the direction of steepest increase and that $\lVert\nabla f\rVert$ is the maximal directional derivative.
3. **(Geometric)** Classify the zero level sets and regularity of $f=x^2+y^2-z^2$, $f=x^2-y^2$, $f=x^2$. Identify the degenerate points.
4. **(Analytic)** For $f(\mathbf p)=\lVert\mathbf p\rVert-r$, compute $\nabla f$ and $\lVert\nabla f\rVert$ everywhere except the origin, and at the origin. This is the sphere's gradient — an SDF.
5. **(Derivation)** Show that if $\lVert\nabla f\rVert=1$ almost everywhere and $f$ is continuous, then $f$ is a signed distance to its zero set (sketch: integrate along the normal from a point to the surface). Discuss the "almost everywhere" caveat at the medial axis.
6. **(Design)** Give an implicit surface that is *not* an SDF (e.g. a high-contrast nonlinear function) and explain why it cannot be safely raymarched with sphere tracing.
