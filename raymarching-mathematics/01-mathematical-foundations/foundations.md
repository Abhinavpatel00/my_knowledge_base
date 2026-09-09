# Chapter 01 — Mathematical Foundations

This chapter assembles the precise mathematical objects the rest of the book uses. It is terse on purpose: every object here is used later, and every definition here is the *right* one. Do not skim.

## 1.1 Point spaces and the Euclidean metric

The stage on which all raymarching happens is the set of points in space. We work in $\mathbb R^3$ and, when convenient, in $\mathbb R^2$ (for screen/tecture domains) or $\mathbb R^4$ (for homogeneous coordinates).

A **point** is a member of the space; a **vector** is a displacement. In an affine space a point and a vector are different objects, but once we fix an origin the two are identified by coordinates. This book uses the standard abuse: a point $\mathbf p$ is written as its coordinate triple, and the difference of two points is a vector.

The space carries the **Euclidean inner product**

$$
\mathbf a\cdot\mathbf b=\sum_{i}a_ib_i=a_1b_1+a_2b_2+a_3b_3 .
$$

The associated **Euclidean norm** is

$$
\lVert\mathbf a\rVert=\sqrt{\mathbf a\cdot\mathbf a}.
$$

The norm induces the **Euclidean metric (distance)**

$$
\operatorname{dist}(\mathbf p,\mathbf q)=\lVert\mathbf p-\mathbf q\rVert.
$$

> Note on notation: $\mathbf p$ is almost always a *point* (a spatial location) and $\mathbf d$, $\mathbf n$, $\mathbf v$ are almost always *directions* (unit vectors). To say $\lVert\mathbf d\rVert=1$ is to say the ray parameter is arclength. We will see in Chapter 07 why this matters enormously.

**Key facts we use constantly:**

1. **Cauchy–Schwarz.** $\lvert\mathbf a\cdot\mathbf b\rvert\le\lVert\mathbf a\rVert\lVert\mathbf b\rVert$, with equality iff $\mathbf a,\mathbf b$ are parallel.
2. **Triangle inequality.** $\lVert\mathbf a+\mathbf b\rVert\le\lVert\mathbf a\rVert+\lVert\mathbf b\rVert$.
3. **Reverse triangle inequality.** $\big\lvert\lVert\mathbf a\rVert-\lVert\mathbf b\rVert\big\rvert\le\lVert\mathbf a-\mathbf b\rVert$. (This is what makes distance fields work — see Chapter 06.)

## 1.2 Distance to a set

Let $S\subseteq\mathbb R^3$ be nonempty. The **distance from a point to a set** is

$$
d(\mathbf p,S)=\inf_{\mathbf q\in S}\lVert\mathbf p-\mathbf q\rVert .
$$

The $\inf$ (infimum, greatest lower bound) is used rather than $\min$ because $S$ may be open or unbounded and the closest point may not exist. For the closed, compact, or at least closed-and-correct geometry we raymarch, the $\inf$ is attained and equals the $\min$.

**Interpretation.** $d(\mathbf p,S)$ is the radius of the largest open ball centered at $\mathbf p$ that does not intersect $S$. Equivalently, $d(\mathbf p,S)$ is the real distance from $\mathbf p$ to the closest point of $S$. This is *not* the same as "how far to the boundary" for a point *inside* a solid; that needs a sign (Chapter 06).

## 1.3 Open and closed sets, boundary

For raymarching we care about the **boundary** $\partial S$ of a solid $S$. A point $\mathbf p$ is on the boundary if every ball around $\mathbf p$ contains both points of $S$ and points not in $S$. A solid in most of this book is the closed set of points "inside or on" an object; its boundary is the visible surface.

The interior is the set of points around which a ball lies entirely in $S$; the exterior is the complement of the closure of $S$. A **signed** field distinguishes interior from exterior by sign (Chapter 06).

## 1.4 Continuity, differentiability

Let $f:\mathbb R^3\to\mathbb R$. $f$ is **continuous** at $\mathbf p$ if $\lim_{\mathbf h\to0}f(\mathbf p+\mathbf h)=f(\mathbf p)$. $f$ is **differentiable** at $\mathbf p$ if there exists a linear map $\mathbf g$ (the gradient) such that

$$
f(\mathbf p+\mathbf h)=f(\mathbf p)+\mathbf g\cdot\mathbf h+o(\lVert\mathbf h\rVert).
$$

The gradient $\nabla f(\mathbf p)=\mathbf g$ is the vector of partial derivatives. For a scalar field,

$$
\nabla f=\left(\tfrac{\partial f}{\partial x},\tfrac{\partial f}{\partial y},\tfrac{\partial f}{\partial z}\right).
$$

The **directional derivative** of $f$ at $\mathbf p$ in the unit direction $\mathbf u$ is

$$
D_{\mathbf u}f(\mathbf p)=\nabla f(\mathbf p)\cdot\mathbf u .
$$

This is the rate of change of $f$ as you move in direction $\mathbf u$. It is maximized exactly when $\mathbf u$ is parallel to $\nabla f$. **That is the geometric meaning of the gradient: it points in the direction of steepest increase, and its magnitude is the rate of that increase.**

A field is $\mathcal C^1$ if it has continuous first partial derivatives, $\mathcal C^2$ if its second partials are continuous, and so on. $\mathcal C^\infty$ means smooth. Much of the geometry we build is only piecewise smooth (boxes, cones, booleans), and the non-differentiability at edges is not a defect to be hidden but a fact to be handled (Chapter 24).

## 1.5 Lipschitz continuity

This is *the single most important concept* for raymarching, so we treat it carefully.

**Definition.** $f:\mathbb R^n\to\mathbb R$ is **Lipschitz continuous with constant $L$** (or $L$-Lipschitz) on a set $U$ if, for all $\mathbf p,\mathbf q\in U$,

$$
\lvert f(\mathbf p)-f(\mathbf q)\rvert\le L\,\lVert\mathbf p-\mathbf q\rVert .
$$

The smallest such $L$ is the **Lipschitz constant** of $f$ on $U$.

**Interpretation.** $L$ bounds how fast $f$ can change as a function of how far you move. If $L=1$, the function cannot grow faster than the distance you travel. A **1-Lipschitz** function is exactly what a distance function is (Chapter 06).

**Equivalent characterization.** For a differentiable $f$, if $\lVert\nabla f\rVert\le L$ everywhere on $U$, then by the mean-value inequality `[ref: MVT]`

$$
\lvert f(\mathbf p)-f(\mathbf q)\rvert\le\sup_{\mathbf u\in[\mathbf p,\mathbf q]}\lVert\nabla f(\mathbf u)\rVert\cdot\lVert\mathbf p-\mathbf q\rVert\le L\lVert\mathbf p-\mathbf q\rVert.
$$

So bounding the gradient bounds the Lipschitz constant. The converse is not literally fine-grained but the two are equivalent for the purpose of "how fast can this function change."

**Why this matters.** Sphere tracing (Chapter 07) needs this: if $f$ is the signed distance to a surface and $f$ is $1$-Lipschitz, then *at any point the value of $f$ is a safe step length.* We will prove this precisely in Chapter 07.

**The subtlety.** Many procedural fields (noise-displaced SDFs, smooth booleans, distance *estimators*) are **not** exactly 1-Lipschitz. When $L>1$, the function can change faster than the step you take, so a "distance" may not be a safe step. The field then becomes a *bound* or an *estimator* (Chapters 06, 10, 20). Recognizing that an object is, or is not, 1-Lipschitz is the recurring analytic task.

## 1.6 Classes of functions we distinguish

We collect the terminology the book enforces:

| Term | Symbol | Defining property |
|------|--------|-------------------|
| Scalar field | $f$ | Any $f:\mathbb R^3\to\mathbb R$. |
| Potential / density field | $\rho$ | Nonnegative, no metric meaning. |
| Implicit surface | $f(\mathbf p)=0$ | Zero level set (Chapter 05). |
| Level set | $f^{-1}(c)$ | Preimage of a level. |
| Unsigned distance | $d(\mathbf p,S)$ | $\inf_{\mathbf q\in S}\lVert\mathbf p-\mathbf q\rVert$. |
| Signed distance | $d(\mathbf p)$ | Signed version, $\nabla d$ unit. (Chapter 06) |
| Distance bound | $\hat d(\mathbf p)$ | $\hat d(\mathbf p)\le d(\mathbf p)$, often signed. |
| Distance estimator | $D(\mathbf p)$ | Approximate distance. |
| Height field | $h(x,y)$ | Graph of $z=h(x,y)$ — not a distance field. |
| Occupancy field | $\chi(\mathbf p)$ | 0/1 indicator. |

The distinctions are not pedantry. A height field does not give you a step size; an occupancy field does not give you a step size; a potential field does not give you a step size. Only an SDF or a distance *bound* does. See Chapter 20 for the engineering consequences.

## 1.7 The preimage / fibers for surfaces

For a smooth $f:\mathbb R^3\to\mathbb R$, the **level set** at level $c$ is

$$
\mathcal L_c=\{\mathbf p:f(\mathbf p)=c\}.
$$

For a regular value $c$ (a value where $\nabla f\neq\mathbf 0$ on $\mathcal L_c$), the implicit function theorem guarantees $\mathcal L_c$ is a $\mathcal C^1$ **surface** — a smooth 2-manifold inside $\mathbb R^3$.

**Definition.** The zero level set $f^{-1}(0)$ is an **implicit surface**. The solid (closed region) is the set $f\le 0$ (using the "outside positive" convention).

**The fundamental fact of implicit geometry** (proved in Chapter 05): the gradient $\nabla f(\mathbf p)$ is **perpendicular to the level set** through $\mathbf p$. Concretely, if $\mathbf u$ is tangent to the level set, then $D_{\mathbf u}f=\nabla f\cdot\mathbf u=0$ because $f$ is constant along the level set. Hence $\nabla f$ is normal to the surface. This single fact gives us normals, and therefore lighting, for free.

## 1.8 Convexity (occasionally needed)

A set $S$ is **convex** if for any two points in $S$, the segment between them lies in $S$. Convex sets have unique nearest points (the projection is well-defined). Many primitives — spheres, boxes, capsules, cones, polyhedra — are convex, which lets us derive *exact* SDFs by a geometric "nearest point" argument (Chapter 08).

For a convex $S$, the SDF is

$$
d_S(\mathbf p)=\lVert\mathbf p-\operatorname{proj}_S(\mathbf p)\rVert
$$

with an appropriate sign. The projection $\operatorname{proj}_S(\mathbf p)$ is the closest point; for convex $S$ it is unique. This is the working definition behind every exact primitive.

## 1.9 Complexity and "cost" as a mathematical quantity

We will use a simple cost model (Chapter 25):

$$
\text{cost}\approx \text{pixels}\times\text{steps}\times\text{(scene evaluation cost)}.
$$

Each of these is a number we can reason about. The first and third factors are fixed by resolution and scene design; the second (step count) is the product of the *distance function's quality* and the *termination logic*. Early chapters give us the machinery; Chapter 25 makes the running time a quantifiable quantity.

## Exercises

1. **(Calculation)** Show that the Euclidean norm satisfies the triangle inequality, and that the reverse triangle inequality $\big\lvert\lVert\mathbf a\rVert-\lVert\mathbf b\rVert\big\rvert\le\lVert\mathbf a-\mathbf b\rVert$ follows from it.
2. **(Derivation)** Let $f(\mathbf p)=\lVert\mathbf p\rVert$. Compute $\nabla f$ away from the origin. What is $\lVert\nabla f\rVert$? Conclude that $f$ is $1$-Lipschitz.
3. **(Derivation)** Let $S$ be a unit sphere centered at the origin. Compute $d(\mathbf p,S)$ for (a) an interior point, (b) a boundary point, (c) an exterior point, using the $\inf$ definition. Where does the $\inf$ fail to be attained if you instead required $\min$?
4. **(Geometric)** Show $\nabla f$ is orthogonal to the level set $f=c$ by differentiating $f(\boldsymbol\gamma(t))=c$ along a curve $\boldsymbol\gamma(t)$ lying in the level set.
5. **(Analytic)** Prove that a differ-entiable $f$ with $\lVert\nabla f\rVert\le L$ everywhere is $L$-Lipschitz, using the mean-value inequality.
6. **(Design)** Which of the following would you trust as a *step length* for a ray marcher: an exact signed distance, a 2-Lipschitz bound, a smooth-boolean output, a potential, a height field? Justify each in one sentence using 1-Lipschitz reasoning.
