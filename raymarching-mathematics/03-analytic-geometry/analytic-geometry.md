# Chapter 03 — Analytic Geometry

Before we can build distance fields, we need the geometry of the basic objects: points, lines, planes, segments, and the distance formulas between them. Nearly every SDF primitive is derived by locating *the nearest point of the object to the sample*, and measuring the distance to it. This chapter supplies those "nearest point" calculations.

## 3.1 Parametrized lines

A **line** through $\mathbf o$ in direction $\mathbf d$ is

$$
\mathbf r(t)=\mathbf o+t\mathbf d,\qquad t\in\mathbb R .
$$

If $\lVert\mathbf d\rVert=1$, then $t$ is the arclength parameter: moving from $t$ to $t+\Delta t$ travels distance $\Delta t$. This is the **ray equation** of Chapter 07.

## 3.2 Point-to-line distance

**Problem.** Given a point $\mathbf p$ and a line through $\mathbf o$ with unit direction $\mathbf d$, find the distance and the closest point.

Set $\mathbf w=\mathbf p-\mathbf o$. The projection of $\mathbf w$ onto $\mathbf d$ is $(\mathbf w\cdot\mathbf d)\mathbf d$; the perpendicular remainder is $\mathbf w-(\mathbf w\cdot\mathbf d)\mathbf d$. The closest point on the line is

$$
\mathbf q=\mathbf o+(\mathbf w\cdot\mathbf d)\mathbf d,
$$

and the distance is

$$
\lVert\mathbf p-\mathbf q\rVert=\lVert\mathbf w-(\mathbf w\cdot\mathbf d)\mathbf d\rVert .
$$

**Vector identity.** For unit $\mathbf d$,

$$
\lVert\mathbf w-(\mathbf w\cdot\mathbf d)\mathbf d\rVert^2=\lVert\mathbf w\rVert^2-(\mathbf w\cdot\mathbf d)^2,
$$

which is the Pythagorean relation. For non-unit $\mathbf d$, the closest parameter is $t=(\mathbf w\cdot\mathbf d)/\lVert\mathbf d\rVert^2$.

**Relevance to SDFs.** An *infinite cylinder* of radius $r$ about a line is exactly $\lVert\mathbf p-\mathrm{proj}(\mathbf p)\rVert-r$, where $\mathrm{proj}$ is the projection onto the line. An *infinite cone* similarly uses the distance to a line but with a different combination (Chapter 08).

## 3.3 Point-to-plane distance

A **plane** with unit normal $\mathbf n$ through point $\mathbf a$ is the set

$$
\mathbf n\cdot(\mathbf x-\mathbf a)=0 .
$$

The signed distance from $\mathbf p$ to the plane is

$$
\delta=\mathbf n\cdot(\mathbf p-\mathbf a).
$$

**Interpretation.** If $\mathbf n$ is a unit normal, $\delta$ is the (signed) perpendicular distance; it equals zero exactly on the plane, is positive on the side toward which $\mathbf n$ points, negative otherwise. For a non-unit normal $\mathbf n$, divide by $\lVert\mathbf n\rVert$.

**Relevance to SDFs.** The *plane primitive* $d=\mathbf n\cdot\mathbf p - c$ (with $\lVert\mathbf n\rVert=1$) is an exact SDF — it is 1-Lipschitz, and its gradient is the constant $\mathbf n$. This is the simplest exact SDF in existence and the basis for half-space booleans.

## 3.4 Point-to-segment distance

**Problem.** Given $\mathbf p$ and the segment from $\mathbf a$ to $\mathbf b$, find the distance and closest point.

Parametrize the segment as $\mathbf a+t(\mathbf b-\mathbf a)$, $t\in[0,1]$. Let $\mathbf w=\mathbf p-\mathbf a$ and $\mathbf v=\mathbf b-\mathbf a$. The unconstrained closest parameter is

$$
t_0=\frac{\mathbf w\cdot\mathbf v}{\lVert\mathbf v\rVert^2}.
$$

Clamp to the interval:

$$
t=\operatorname{clamp}(t_0,0,1).
$$

The closest point is $\mathbf a+t\mathbf v$; the distance is $\lVert\mathbf p-(\mathbf a+t\mathbf v)\rVert$.

**Derivation of the clamp.** The unconstrained minimizer of $\lVert\mathbf w-t\mathbf v\rVert^2$ satisfies $2(\mathbf w-t\mathbf v)\cdot(-\mathbf v)=0$, i.e. $t_0=\mathbf w\cdot\mathbf v/\lVert\mathbf v\rVert^2$. The constrained problem has the same minimizer unless it falls outside $[0,1]$, in which case the nearest point is an endpoint because $\lVert\mathbf p-\mathbf q\rVert$ is convex in $t$. This is the origin of the `clamp` in the capsule and segment SDFs.

**Relevance to SDFs.** The *capsule* (a segment swept by a sphere) and the *line segment* primitive are directly this formula with a radius (Chapter 08). It is also the basis for tube geometries (Chapter 16).

## 3.5 Line–plane intersection

Solve $\mathbf r(t)=\mathbf o+t\mathbf d$ and $\mathbf n\cdot(\mathbf r(t)-\mathbf a)=0$:

$$
t=\frac{\mathbf n\cdot(\mathbf a-\mathbf o)}{\mathbf n\cdot\mathbf d}.
$$

This fails (no unique intersection) exactly when $\mathbf n\cdot\mathbf d=0$, i.e. the ray is parallel to the plane. This is relevant for planar clipping and for the "slab" method of intersecting convex volumes.

## 3.6 Intersection of a ray with an axis-aligned box

The **slab method**. A box with min corner $\mathbf c_{\min}$ and max corner $\mathbf c_{\max}$ is

$$
c_{\min,i}\le x_i\le c_{\max,i},\quad i=1,2,3 .
$$

For each axis, solve $o_i+t d_i=c_{\min,i}$ and $=c_{\max,i}$ to get $[t_{i,1},t_{i,2}]$ (order after checking sign of $d_i$). The ray enters the box at

$$
t_{\text{enter}}=\max_i(\min(t_{i,1},t_{i,2})),
$$

and leaves at

$$
t_{\text{exit}}=\min_i(\max(t_{i,1},t_{i,2})).
$$

The ray intersects the box iff $t_{\text{enter}}\le t_{\text{exit}}$ (and, for a bounded ray, $t_{\text{exit}}\ge0$). This is used for **bounding-volume acceleration** and for the "infinite corridor" style of scene where we march a ray against an enclosing box (Chapter 25).

## 3.7 Distance to convex polyhedra and half-spaces

A convex polyhedron can be written as an intersection of a finite set of half-spaces,

$$
S=\bigcap_i\{\mathbf x:\mathbf n_i\cdot\mathbf x\le c_i\}.
$$

The **distance to a convex polytope** is a min/max combination (Chapter 08), but the key geometric tool is this: for each half-space, the signed distance is $\delta_i=c_i-\mathbf n_i\cdot\mathbf x$ (positive outside, negative inside). Inside the polytope, the signed distance is $\min_i\delta_i$ (the nearest face). Outside, you must measure to the *nearest face or edge or vertex*, which is where the "distance to convex body" formula (used for boxes) comes from.

## 3.8 The projection as the master tool

Summarizing: for **convex** primitives, the SDF is always obtained by:

1. Finding the closest point $\mathbf q\in S$ to $\mathbf p$ (a projection, possibly clamped to a parameter range),
2. Computing the signed distance $\delta=\lVert\mathbf p-\mathbf q\rVert$ (with the sign decided by inside/outside).

Almost every primitive in Chapter 08 is a specialization of this two-step recipe. For non-convex or composite shapes, we use the SDF *composition algebra* of Chapter 09, which never requires us to know the actual closest point — only the distance values.

## Exercises

1. **(Calculation)** Find the distance from $(1,0,2)$ to the line through the origin in direction $(1,1,0)$, and give the closest point.
2. **(Calculation)** Find the distance from $(2,3,-1)$ to the plane $\mathbf n=(1,0,1)/\sqrt2$ through the origin.
3. **(Derivation)** Derive the point-to-segment distance by minimizing $\lVert\mathbf w-t\mathbf v\rVert^2$ over $t\in[0,1]$; justify the clamp.
4. **(Geometric)** Show that for a unit normal $\mathbf n$, $\mathbf n\cdot(\mathbf p-\mathbf a)$ is the perpendicular distance to a plane, and that the gradient of $d(\mathbf p)=\mathbf n\cdot\mathbf p-c$ is $\mathbf n$ (hence $d$ is 1-Lipschitz).
5. **(Design)** Given a ray and an axis-aligned box, write the slab test. Why is it useful for bounding-volume optimization?
6. **(Derivation)** Explain why the distance to a convex set equals $\lVert\mathbf p-\operatorname{proj}_S(\mathbf p)\rVert$ and why the projection is unique for convex sets.
