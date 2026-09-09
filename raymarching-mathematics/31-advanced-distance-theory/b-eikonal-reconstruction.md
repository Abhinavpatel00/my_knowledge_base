# Chapter 31b — The Eikonal Equation and Distance Reconstruction

A generic implicit surface $f=0$ is *not* a distance field. Yet we can turn it into one — approximately or exactly — by solving the **eikonal equation**. This chapter explains the eikonal equation, its Hopf–Lax solution, the gradient-based distance estimate, and how these underpin both practical shaders and modern implicit-surface reconstruction.

## 31b.1 The eikonal equation

The **eikonal equation** is the first-order PDE

$$
\lVert\nabla u\rVert=1\quad\text{in }\Omega,\qquad u=0\quad\text{on }\partial\Omega.
$$

A solution $u$ is (locally) the signed distance to $\partial\Omega$. For an *exact* SDF we have $\lVert\nabla d\rVert=1$ (almost everywhere), so exact distance fields are precisely the "gradient magnitude is 1" solutions. This is a first-order Hamilton–Jacobi equation whose solution can be obtained by the method of characteristics.

**Definition.** The exact signed distance to a set $S$ is the unique viscosity solution of the eikonal equation with boundary condition $u=0$ on $\partial S$ (with the appropriate sign convention).

**Why "viscosity."** The eikonal equation is genuinely nonlinear and its solutions generally fail to be differentiable at the medial axis. The viscosity-solution formalism gives the correct (weak, but well-posed) notion of solution precisely there — a rigorous reason why SDFs are only differ-entiable "almost everywhere."

## 31b.2 The Hopf–Lax solution

For the eikonal equation the viscosity solution has the **Hopf–Lax** representation

$$
u(\mathbf p)=\min_{\mathbf q\in\partial S}\ \lVert\mathbf p-\mathbf q\rVert .
$$

That is, the solution is literally the infimum over boundary points of the Euclidean distance — which is exactly the definition of distance to the set (Chapter 06). The Hopf–Lax formula makes the "distance is the viscosity solution of eikonal" statement concrete, and it is the bridge between the geometric definition and the PDE.

**Interpretation.** The characteristics of the eikonal equation are straight lines (geodesics) along which $u$ increases at rate 1 — these are the normal rays. The level sets are the "wavefronts" propagating from the boundary at unit speed. This is why distance fields look like a set of expanding wavefronts, and why the medial axis appears where two wavefronts collide.

## 31b.3 The gradient-based distance estimate (iq)

For a generic implicit field $f$ (not a distance), the first-order estimate of the distance to the $f=0$ isosurface at a point where $f(\mathbf p)>0$ is

$$
\hat d(\mathbf p)=\frac{f(\mathbf p)}{\lVert\nabla f(\mathbf p)\rVert}.
$$

**Derivation (tangent-plane argument).** The zero isosurface passes near $\mathbf p$, and by the first-order (linear) approximation the surface behaves like the tangent plane through the point $\mathbf x_0$ where the normal ray from $\mathbf p$ meets the surface. Along the gradient direction, $f$ changes at rate $\lVert\nabla f\rVert$; so the distance $\hat d$ that reduces $f$ to $0$ is $f/\lVert\nabla f\rVert$. Geometrically: the plane tangent to the surface at the nearest point, intersected with the line through $\mathbf p$ along the gradient, gives a distance $f(\mathbf p)/\lVert\nabla f\rVert$. This is an *estimate* (first order), exact only for the plane (where $\nabla f$ is constant) and for the case that the nearest point lies along the gradient from $\mathbf p$.

**When is it exact?** For a *plane*, $f(\mathbf p)=\mathbf n\cdot\mathbf p-c$ with constant $\lVert\nabla f\rVert=\lVert\mathbf n\rVert=1$, so $\hat d=f$ exactly. For a *distance field*, $\lVert\nabla f\rVert$ would be 1, so again $\hat d=f$. So the estimate is exact whenever the field is either already a distance, or locally a plane.

**The failure mode.** The estimate $f/\lVert\nabla f\rVert$ is an **upper bound** on the distance when $\lVert\nabla f\rVert<1$ (flat spot) and a **lower bound** when $\lVert\nabla f\rVert>1$ (steep spot). It *overestimates* the distance precisely where the gradient is small, which is the classic source of *tunneling* in naive shaders. This is the rigorous justification for the "sine-plane" hole artifact: adding $\sin(x)$ to a plane makes $\lVert\nabla f\rVert=1$ at peaks but $>1$ (in the troughs, $|\cos|$... actually $\lVert\nabla\rVert=\sqrt{1+\cos^2 x}$), so the field overestimates inside troughs and the ray tunnels.

**Shader consequence.** The tangent-plane estimate is exactly what makes "implicit surface" shaders draw shapes of *non-uniform thickness*: the apparent width of a band depends on $1/\lVert\nabla f\rVert$. To get uniform thickness, divide by the gradient norm — i.e. use $f/\lVert\nabla f\rVert$ as the distance before coloring.

## 31b.4 The eikonal-constrained reparameterization

The general problem — turn an arbitrary implicit field into a distance — can be framed as: solve the eikonal equation with Dirichlet data. There are two practical tracks:

1. **Exact, off-line or numerical.** Solve via a fast-marching / fast-sweeping method (a "reinitialization" step in level set methods). Not usable in a per-pixel shader in general.
2. **Approximate, pointwise (shader).** Use the first-order estimate $f/\lVert\nabla f\rVert$, or a higher-order version. This is what fractals and "implicit surface" shaders do.

**The key theorem (why the estimate is well-motivated).** If $f$ is smooth and $\nabla f\neq0$ near the surface, then for points close to the surface the true distance $d$ and the estimate $\hat d=f/\lVert\nabla f\rVert$ agree to first order:
$$
\frac{f(\mathbf p)}{\lVert\nabla f(\mathbf p)\rVert}=d(\mathbf p)+O(\lVert\mathbf p-\mathbf x_0\rVert^2)
$$
where $\mathbf x_0$ is the nearest surface point. This is because $f$'s Taylor expansion along the normal is $f(\mathbf p)=\lVert\nabla f\rVert\,(\lVert\mathbf p-\mathbf x_0\rVert)+O(\lVert\mathbf p-\mathbf x_0\rVert^2)$. The estimate is therefore a genuinely good *local* distance, and the error is second-order in the distance to the surface.

## 31b.5 Applications

- **Fractal DEs.** The whole method of Chapter 19/20 is an application of the eikonal idea: the "distance estimate" is a first-order reconstruction of the distance from the iteration's growth rate, i.e. an approximate $\hat d$ from a field-like quantity ($f\sim\log|z|$) and its gradient ($\lVert\nabla f\rVert\sim dr/|z|$).
- **Level-set / neuronal / geometric implicit representations.** Modern implicit-surface reconstruction (point clouds, SIREN, neural SDFs) *enforces* the eikonal constraint $\lVert\nabla f\rVert\approx1$ as a regularizer, precisely so the learned field becomes a genuine distance and can be sphere-traced. This is the 2020s incarnation of "make the implicit field a distance."
- **Uniform-thickness shaders.** Dividing by $\lVert\nabla f\rVert$ before coloring/thresholding gives constant apparent thickness of an implicit band, which is the "distance-estimation" trick for rendering $\lvert f\rvert<\varepsilon$ bands.

## 31b.6 Why "almost everywhere" is not a technicality

The eikonal equation has no differentiable solution at the medial axis. The viscosity solution exists, but there $\nabla u$ is set-valued and the field has a "ridge." Any attempt to use $u$ as if it were a smooth function (e.g. to extract a unique normal) is ill-posed there. This is the mathematical reason that normals near creases/medial axes must be *averaged* (numerical gradients give the mean of the two branch derivatives) and that lighting there produces the characteristic rounded "seams." The graduate-level statement: **the distance to a set is a solution of the Hamilton–Jacobi equation in the viscosity sense, and it is differentiable exactly on the complement of the cut locus (medial axis).**

## Exercises

1. **(Derivation)** Derive the Hopf–Lax representation and explain why it recovers the distance definition.
2. **(Derivation)** Derive the tangent-plane estimate $\hat d=f/\lVert\nabla f\rVert$ and show it's exact for planes and distance fields.
3. **(Derivation)** Show the estimate is a *first-order* reconstruction: prove $f/\lVert\nabla f\rVert=d+O(d^2)$.
4. **(Analytic)** Explain why a sine-perturbed plane (`f=p.y+sin(p.x)`) can tunnel: compute $\lVert\nabla f\rVert$ and show where it exceeds 1.
5. **(Analytic)** Explain the viscosity/cut-locus non-differentiability and its consequence for normals near the medial axis.
6. **(Design)** Build a uniform-thickness implicit band using the gradient-based estimate; describe how it removes the "variable thickness" artifact.
