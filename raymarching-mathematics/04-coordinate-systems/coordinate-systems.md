# Chapter 04 — Coordinate Systems

The most powerful idea in procedural modeling is not a specific formula but a choice: **choose the coordinate system in which the desired structure is a simple object.** A ring is trivial in polar coordinates; a spiral is trivial in polar coordinates with a linear phase; a torus is trivial in a "tube" coordinate; a crystal is trivial in a folded lattice. This chapter establishes the coordinate systems and the mathematics of changing between them.

## 4.1 Why coordinate systems matter

The geometry of an object is intrinsic — it does not depend on how we label points. But the *description* does. If a structure is "rotationally symmetric around an axis," then writing it in cylindrical coordinates makes the angular dependence trivial or absent. If it is "radially symmetric about a point," spherical coordinates remove the angular variation entirely.

The practical rule:

> To build a shape, pick the coordinate system in which the shape's **symmetry group** is the subgroup that makes the description one-dimensional or simple.

This is a *symmetry-guided* design principle, and it is the single most reusable idea in this book.

## 4.2 Polar coordinates (planar)

For a point $(x,y)$ in the plane:

$$
r=\sqrt{x^2+y^2},\qquad \theta=\operatorname{atan2}(y,x) .
$$

The inverse is

$$
x=r\cos\theta,\qquad y=r\sin\theta .
$$

**Interpretation.** $(r,\theta)$ is the radius (distance from origin) and the angle from the positive $x$-axis. $r\ge0$ by convention; $\theta\in(-\pi,\pi]$ from `atan2`.

**The Jacobian** of the polar map $(r,\theta)\mapsto(x,y)$ is

$$
J=\frac{\partial(x,y)}{\partial(r,\theta)}=
\begin{pmatrix}\cos\theta&-r\sin\theta\\ \sin\theta&r\cos\theta\end{pmatrix},
\qquad \det J=r .
$$

The `r` factor carries the geometry: an area element $dx\,dy=r\,dr\,d\theta$. When we use polar coordinates to **deform** space, this area distortion is what creates the "wrapping" of detail near the origin.

**Relevance.** Polar coordinates make *radial repetition*, *rings*, *discs*, and *rotational symmetry* trivial. A ring of $n$ wedges is $n$ copies of the wedge $\theta\in[-\pi/n,\pi/n]$ applied about the origin — see Chapter 11.

## 4.3 Cylindrical coordinates (axial)

For a point in 3D with axis $z$:

$$
r=\sqrt{x^2+y^2},\qquad \theta=\operatorname{atan2}(y,x),\qquad z=z .
$$

The inverse is $x=r\cos\theta,\ y=r\sin\theta,\ z=z$.

**Interpretation.** $(r,\theta,z)$ is the polar radius/angle and the axial coordinate. Cylindrical symmetry around $z$ means the object's description is independent of $\theta$.

**Relevance.** Used to build *tubes*, *torus* (in the torus coordinate system of §4.6), *spirals* (a helix is $z$ proportional to $\theta$), and *radial repetition* around an axis. The "twist" transform (Chapter 10) is literally adding a term to $\theta$ proportional to $z$.

## 4.4 Spherical coordinates (radial)

For a point in 3D:

$$
r=\sqrt{x^2+y^2+z^2},\qquad
\theta=\arccos\!\frac{z}{r},\qquad
\phi=\operatorname{atan2}(y,x) .
$$

Here $\theta$ is the polar angle from the $+z$ axis ($0\le\theta\le\pi$) and $\phi$ is the azimuth in the $xy$-plane. The inverse:

$$
x=r\sin\theta\cos\phi,\quad
y=r\sin\theta\sin\phi,\quad
z=r\cos\theta .
$$

**The Jacobian.** $\det J=r^2\sin\theta$, so $dx\,dy\,dz=r^2\sin\theta\,dr\,d\theta\,d\phi$.

**Relevance.** Spherical coordinates make *radially symmetric* objects trivial and are the basis of **spherical repetition**, **kaleidoscopic patterns**, and the whole family of "powered" radial fractals. The **Mandelbulb** (Chapter 19) is literally defined by this coordinate system: it raises $r$ to a power and multiplies the angles, which is a spherical-coordinate operation.

## 4.5 The "raise to a power" operation in spherical coordinates

Define the operation $\mathbf v\mapsto \mathbf v^{n}$ in spherical coordinates by

$$
(r,\theta,\phi)\mapsto (r^n,\;n\theta,\;n\phi).
$$

Written out in Cartesian coordinates this is the **triplex power** used to build the Mandelbulb. Its Jacobian is the crucial quantity for the distance estimator (Chapter 19–20). The reason it produces rich fractal structure is that a nonlinear map with $n>1$ is *expansive* — it blows up small radial variations and wraps the angle $n$ times, so the iteration $z\mapsto z^n+c$ has a non-integer or fine fractal structure for suitable $n$.

## 4.6 The torus coordinate system

A torus is best described by a **shifted polar map**. Taking a circle of radius $R$ in the $xy$-plane, and a tube of radius $r$ about it: in coordinates $(\theta,\rho)$ where $\theta$ runs around the main ring and $\rho$ runs around the tube cross-section,

$$
(x,y,z)=\big((R+\rho\cos\theta)\cos\phi,\ (R+\rho\cos\theta)\sin\phi,\ \rho\sin\theta\big).
$$

The distance to the torus' surface is essentially the 2D distance from the point $(q_x,q_y)=(\sqrt{x^2+y^2}-R,\ z)$ to the origin, minus the tube radius:

$$
d=\sqrt{(\sqrt{x^2+y^2}-R)^2+z^2}-r .
$$

Here the coordinate change $q=\big(\sqrt{x^2+y^2}-R,\ z\big)$ is the key move: it folds the 3D torus problem into a 2D circle problem (Chapter 08).

## 4.7 Change of coordinates and the chain rule

If $\boldsymbol\sigma:\mathbb R^3\to\mathbb R^3$ is a coordinate map and $F$ is a function on the new coordinates, the derivative of $F\circ\boldsymbol\sigma$ is given by the chain rule:

$$
\nabla_{\mathbf p}(F\circ\boldsymbol\sigma)=J_{\boldsymbol\sigma}(\mathbf p)^T\,\nabla F(\boldsymbol\sigma(\mathbf p)).
$$

This is how we compute gradients (normals) of warped or coordinate-transformed fields (Chapter 12). The Jacobian $J_{\boldsymbol\sigma}$ captures how the map stretches and rotates space, which is exactly the information that decides whether a transform preserves the distance property (Chapter 10).

## 4.8 Distortion of the metric: the "does distance survive?" test

When we use a coordinate change as a *deformation* (rather than a passive re-labeling), we are mapping the reference space through $\boldsymbol\sigma$ and treating the output as real space. The distance field is then $d'(\mathbf p)=d(\boldsymbol\sigma(\mathbf p))$. The question is whether $d'$ is still a signed distance.

The condition is that $\boldsymbol\sigma$ be an **isometry** (preserve lengths) — i.e. its Jacobian is an orthogonal matrix at every point. Polar/cylindrical/spherical *coordinates* are isometries only as passive re-labelings of Euclidean space; applying them as *maps of points* is generally *not* isometric (they curl, fold, and stretch the metric), so $d'$ is at best a *distance bound or estimator.* See Chapter 10 for the full treatment.

## Exercises

1. **(Calculation)** Convert $(1,1,1)$ to cylindrical and spherical coordinates.
2. **(Derivation)** Derive $\det J=r$ for the polar map and $\det J=r^2\sin\theta$ for spherical coordinates.
3. **(Geometric)** Write the distance to a circle of radius $R$ in 2D in polar coordinates. Then generalize to the torus.
4. **(Derivation)** Given a helical curve $(\cos\theta,\sin\theta,k\theta)$, express it in cylindrical coordinates and explain what change makes it simple.
5. **(Design)** You want a ring of $n$ radial arms. Which coordinate system and transform produces it from a single arm? How does a spiral of arms arise when you let the angular offset grow linearly?
6. **(Analytic)** Show that the map $(x,y)\mapsto(\rho\cos\theta,\rho\sin\theta)$ is not isometric by computing its Jacobian and noting it is not orthogonal everywhere.
