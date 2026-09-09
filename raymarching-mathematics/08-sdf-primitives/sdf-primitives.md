# Chapter 08 — SDF Primitives

Every SDF primitive here is derived from its geometry. The universal method: identify the **nearest point** of the object to the sample, measure the (signed) distance to it, and decide the sign by inside/outside. We state, for each primitive, the geometry, the coordinate setup, the derivation, the resulting equation, the gradient behavior, and the GLSL. Where a formula is due to a specific author (chiefly Iñigo Quilez and the SDF community), the derivation is given so it is not a "magic formula."

The universal convention: sample point $\mathbf p$, surface defined by $d(\mathbf p)=0$, solid $d\le0$.

## 8.0 The derivation template

For every primitive follow:

```
GEOMETRIC DEFINITION
  → COORDINATE SETUP
  → NEAREST-POINT IDENTIFICATION
  → SIGNED DISTANCE
  → GRADIENT BEHAVIOR
  → GLSL
```

## 8.1 Sphere

**Geometric definition.** The set of points at distance $r$ from center $\mathbf c$. WLOG take $\mathbf c=0$ (translation is treated in Chapter 10).

**Derivation.** The nearest point to $\mathbf p$ on a sphere of radius $r$ centered at the origin is $r\hat{\mathbf p}$ where $\hat{\mathbf p}=\mathbf p/\lVert\mathbf p\rVert$. Its distance from $\mathbf p$ is $\lVert\mathbf p\rVert-r$ for exterior points. For interior points the same formula gives the distance to the surface with the correct (negative) sign because the distance to the boundary is $r-\lVert\mathbf p\rVert$ and the interior point's sign is negative. Thus

$$
d(\mathbf p)=\lVert\mathbf p\rVert-r .
$$

**Interpretation.** $\lVert\mathbf p\rVert$ is the radial distance from the center; subtracting $r$ "centers" the zero level at the surface. Inside ($\lVert\mathbf p\rVert<r$) we get negative; on the boundary zero; outside positive.

**Gradient.** $\nabla d=\hat{\mathbf p}$ for $\mathbf p\neq\mathbf 0$, so $\lVert\nabla d\rVert=1$ everywhere except the center (the medial-axis point). The center is where the gradient fails to exist (the field is $\mathcal C^0$ there, since $d=-\lVert\mathbf p\rVert$ near it).

**Numerical behavior.** $\sqrt{\mathbf p\cdot\mathbf p}$ is well-conditioned for moderate magnitudes, but when $\lVert\mathbf p\rVert$ is so large that its float rounding exceeds $r$, the difference $\lVert\mathbf p\rVert-r$ loses precision. In practice this only bites in very deep scenes; for a well-scaled scene the exact difference is fine.

```glsl
float sdSphere(vec3 p, float r){ return length(p)-r; }
```

**Generalization.** Vary $r$ with a function $r(\mathbf p)$ (→ a blob/noise-deformed sphere, Chapter 16), or transform $\mathbf p$ (→ ellipsoid/rotation, Chapter 10). A *rounded sphere* anywhere becomes an environment of soft blobs.

## 8.2 Plane

**Geometric definition.** The set of points satisfying $\mathbf n\cdot\mathbf p=c$ with $\lVert\mathbf n\rVert=1$.

**Derivation.** The signed distance is the perpendicular projection of $\mathbf p$ onto the normal, minus the offset:

$$
d(\mathbf p)=\mathbf n\cdot\mathbf p-c .
$$

**Gradient.** $\nabla d=\mathbf n$, constant, unit. So $d$ is exactly 1-Lipschitz and smooth everywhere (it's linear).

**Interpretation.** The plane is an exact SDF, and the simplest one. It is the universal clipping/ground tool. Because it's per-pixel-simple, it is cheap.

```glsl
// unit normal n, plane through point where n·p = c
float sdPlane(vec3 p, vec3 n, float c){ return dot(p,n)-c; }
```

## 8.3 Box (axis-aligned, half-extents)

**Geometric definition.** The axis-aligned box with half-extents $\mathbf b=(b_x,b_y,b_z)$ centered at the origin.

**Derivation via nearest point.** Let $\mathbf q=\mathbf p-\operatorname{clamp}(\mathbf p,-\mathbf b,\mathbf b)$ be the vector from the box (clamped point) to $\mathbf p$. Define the component-wise "outside amount" $\mathbf w=\lvert\mathbf p\rvert-\mathbf b$ (component-wise absolute difference from the box in each axis):

- If $\mathbf p$ is outside, the nearest point on the box surface is the clamp of $\mathbf p$ to the box, and the distance is $\lVert\mathbf p-\operatorname{clamp}(\mathbf p)\rVert=\lVert\max(\mathbf w,0)\rVert$.
- If $\mathbf p$ is inside, the nearest surface point is on the nearest face, and the distance is the negative of the minimum component magnitude, $-\min(\max_x,\max_y,\max_z)$ (i.e. $-\max_i(\lvert p_i\rvert-b_i)$, which is negative inside).

The standard closed formula combining both cases is

$$
d(\mathbf p)=\lVert\max(\lvert\mathbf p\rvert-\mathbf b,0)\rVert+\min(\max(\mathbf d),\ 0)\;,
\quad\mathbf d=\lvert\mathbf p\rvert-\mathbf b .
$$

**Explanation of terms.** The first term measures displacement *outside* the box (zero inside). The second term is the (negative) distance to the nearest face *inside* (zero outside). Adding them gives the signed distance (the sum of a nonnegative and a nonpositive term is exact because the "outside" and "inside" regions are disjoint and one of the two is always zero).

**Gradient behavior.** On the flat faces $\nabla d$ is one of the coordinate axes. At edges $\nabla d$ is discontinuous; the field is $\mathcal C^0$ across edges and $\mathcal C^1$ within faces. At corners the gradient is a "diagonal" average.

```glsl
float sdBox(vec3 p, vec3 b){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
```

## 8.4 Rounded box

**Derivation.** Roundedness is achieved by *shrinking* the half-extents by the rounding radius $r$ before applying the box formula and then adding $r$ back to the result. Because "rounding" an edge is equivalent to offsetting the surface outward by $r$ (a Minkowski sum with a ball of radius $r$), and offsetting an SDF by $r$ is

$$
d^{+}(\mathbf p)=d(\mathbf p)-r
$$

(negative sign: the shrunken box is made *larger* by $r$, and we want the surface to be $r$ away from the shrunken box), the rounded-box SDF is

$$
d(\mathbf p)=\operatorname{sdBox}(\mathbf p,\mathbf b-r)-r .
$$

**Numerical benefit.** The rounding $r$ also makes the field smoother near edges, reducing $\mathcal C^0$ discontinuities.

```glsl
float sdRoundedBox(vec3 p, vec3 b, float r){
    return sdBox(p, b - r) - r;   // r < min(b)
}
```

## 8.5 Infinite cylinder (axis = y)

**Geometric definition.** The set of points at distance $r$ from the $y$-axis.

**Derivation.** The nearest point is at the same $y$ but with the $(x,z)$ coordinates clamped to radius $r$; the distance is $\sqrt{x^2+z^2}-r$.

$$
d(\mathbf p)=\sqrt{x^2+z^2}-r=\lVert\mathbf p_{xz}\rVert-r .
$$

**Gradient.** $\nabla d=(\hat{\mathbf p}_{xz},0)$, unit. Smooth everywhere off the axis.

```glsl
float sdCylinder(vec3 p, float r){ return length(p.xz)-r; }
```

## 8.6 Capped cylinder (axis = y)

**Geometric definition.** Finite cylinder height $h$ (half-height) and radius $r$ along the $y$-axis.

**Derivation.** The distance is found by locating the nearest point on the cylinder's *surface*:

- Clamp $y$ to $[-h,h]$ (so `dy = clamp(p.y,-h,h) - p.y` is the axial overshoot).
- The radial distance is $\lVert\mathbf p_{xz}\rVert-r$ (call it $d_r$).
- The axial distance is the overshoot magnitude $\lvert dy\rvert$.

The signed distance combines the radial and axial "outside amounts" with the box/min-max formula. The trick is to treat the cylinder boundary as a 2D shape in the $(u,v)$ plane, where $u=\lVert\mathbf p_{xz}\rVert$ is the radial coordinate and $v=\lvert p_y\rvert$ is the axial coordinate. Define the 2D "outside" vector

$$
\mathbf q=(u,\ v)-\left(r,\ h\right)
=\big(\lVert\mathbf p_{xz}\rVert-r,\ \lvert p_y\rvert-h\big).
$$

Then the signed distance is

$$
d(\mathbf p)=\lVert\max(\mathbf q,0)\rVert+\min(\max(q_x,q_y),\ 0).
$$

**Explanation.** This is exactly the box formula (§8.3) applied in the $(u,v)$ plane, because in that plane the cylinder is a *rectangle* (of half-width $r$ in the radial direction and half-height $h$ in the axial direction). The first term $\lVert\max(\mathbf q,0)\rVert$ measures the distance *outside the rectangle* (zero inside); the second term $\min(\max(q_x,q_y),0)$ measures the (negative) distance to the nearest side *inside* (zero outside). Because the radial/axial rotation is an isometry of the 3D point down to the $(u,v)$ plane, the distance is exact — this is why the plateau-capped cylinder SDF is exact everywhere including along the rim.

**Alternative (cleaner for caps).** The finite cylinder is the intersection of the infinite cylinder and the slab $|y|<h$; its SDF can be approximated with a smooth or exact boolean (Chapter 09). But the closed form above is exact and efficient.

```glsl
float sdCappedCylinder(vec3 p, float r, float h){
    vec2 d = vec2(length(p.xz), abs(p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
```

## 8.7 Cone (infinite, apex at origin)

**Geometric definition.** Two-sided cone with apex at origin, opening with half-angle $\alpha$ (so the cone's surface is at polar angle $\alpha$ from the $+y$ axis), extending both directions.

**Derivation.** Let $q=\lVert\mathbf p_{xz}\rVert$ and $h=p_y$. After wrapping the azimuth angle (an isometry), the cone's boundary in the $(q,h)$ plane is a pair of straight lines through the origin. A surface point of the right half-cone (opening downward along $-y$) satisfies $q=h\tan\alpha$, i.e. lies on the line through the origin with unit direction $(\sin\alpha,\cos\alpha)$. The perpendicular unit normal to that line is $(\cos\alpha,-\sin\alpha)$, so the Euclidean distance from $(q,h)$ to the cone surface is

$$
d(\mathbf p)=\big\lvert\lVert\mathbf p_{xz}\rVert\cos\alpha - p_y\sin\alpha\big\rvert .
$$

The `abs` makes it the distance to the *two-sided* cone (both halves). Dropping the `abs` gives a *signed* distance to one half-cone, with the sign convention depending on which half.

**Why it is exact.** Because the map $(x,z)\mapsto(r=\lVert\mathbf p_{xz}\rVert,\ \theta)$ is an isometry in the radial direction (the azimuth rotation preserves distances), the 3D problem reduces exactly to a distance-to-a-line in the Euclidean $(q,h)$ plane, which is the point-to-line formula of Chapter 03. The line's unit normal is exactly $(\cos\alpha,-\sin\alpha)$, giving the neat linear form below.

```glsl
// c = (cos a, sin a) for half-angle a, cone half-angle = a
float sdCone(vec3 p, vec2 c){
    return abs(dot(c, vec2(-length(p.xz), p.y))) ; // two-sided cone
}
```

(For a one-sided cone, use `dot(c, vec2(length(p.xz), p.y))` with the matching branch and an appropriate sign, and clamp the solid region.)

## 8.8 Capped cone (finite, radius $r_1$ at bottom, $r_2$ at top, height $h$)

**Geometry.** Truncated cone along $y$ with radii $r_1$ (bottom, $y=0$) and $r_2$ (top, $y=h$).

**Derivation approach.** This is a straight-sided frustum. Its exact SDF is more involved because the nearest point may lie on the slant, the bottom rim, the top rim, or one of the two cap discs. The construction is: define the reduced coordinate $(q,h)=(\lVert\mathbf p_{xz}\rVert,\ p_y)$; in the $(q,h)$ plane the frustum is a trapezoid. The exact distance is obtained by (a) clamping the point to the trapezoid in a way that resolves which part of the boundary is nearest — slant vs. rim vs. cap — and (b) applying the box/min-max trick in that rotated frame, exactly as for the capped cylinder (§8.6) but with *slanted* sides.

Rather than reproduce the fully general closed form (it is long and best stored as a reference function), we note the structure: the frustum's boundary in the $(q,h)$ plane consists of two slanted lines and two horizontal caps, and the exact SDF is a min-max combination of the signed distances to those. For the *purpose of safe marching*, a capped cone is very commonly replaced by the intersection (smooth or exact `max`) of an infinite cone (§8.7) and a slab $\lvert p_y\rvert\le h$, which yields an exact *distance bound* (or an acceptable distance estimator) at far lower complexity.

## 8.9 Torus

**Geometric definition.** A circle of radius $R$ in the $xy$-plane, swept by a tube of radius $r$.

**Derivation via torus coordinate (§4.6).** Let $\mathbf p=(x,y,z)$. The main ring lies in the $xy$-plane. Define the "radial distance in the ring's plane" $u=\sqrt{x^2+y^2}$ and the axial coordinate $v=z$. A point on the tube surface is at distance $r$ from the ring (a circle of radius $R$ in the $(u,v)$ point...). Actually, the distance to the ring's center circle is $\sqrt{(\sqrt{x^2+y^2}-R)^2+z^2}$. The tube surface subtracts the tube radius:

$$
d(\mathbf p)=\sqrt{(\sqrt{x^2+y^2}-R)^2+z^2}-r .
$$

**Interpretation.** $\sqrt{x^2+y^2}-R$ measures the radial displacement from the ring's centerline; squaring and adding $z^2$ gives the squared distance from $\mathbf p$ to the ring circle; $\sqrt{\cdot}$ is that distance; subtracting $r$ gives the signed distance to the torus surface.

**Numerical behavior.** The inner `sqrt` (for the ring) and outer `sqrt` (for the distance) are both fine. The torus is an exact SDF.

```glsl
float sdTorus(vec3 p, float R, float r){
    vec2 q = vec2(length(p.xz)-R, p.y);
    return length(q)-r;
}
```

**Generalization.** Vary $R$ and $r$ with $\theta$, or add a "spiral" phase to $R$ (→ snail shell / vortex), or transform $\mathbf p$ (Chapter 10). The torus is the seed for many machine/organic forms.

## 8.10 Capsule and line segment

**Geometric definition.** Capsule = set of points within distance $r$ of a segment from $\mathbf a$ to $\mathbf b$.

**Derivation.** From §3.4 the nearest point on the segment to $\mathbf p$ is the clamped projection; then the distance to that point minus $r$:

$$
d(\mathbf p)=\lVert\mathbf p-\operatorname{clamp}_{\text{seg}}(\mathbf p)\rVert-r .
$$

The clamp uses the parameter $t=\operatorname{clamp}(\frac{(\mathbf p-\mathbf a)\cdot(\mathbf b-\mathbf a)}{\lVert\mathbf b-\mathbf a\rVert^2},0,1)$.

**Segment SDF** (radius 0) is the same without subtracting $r$.

**Gradient behavior.** Smooth along the cylinder part; $\mathcal C^0$ at the two spherical caps (the caps are smooth, and the seam between the cylindrical side and the spherical end is $\mathcal C^1$). A capsule, being a segment swept by a ball, is an exact SDF (Minkowski sum of a segment and a ball → offset by $r$ keeps the SDF property).

```glsl
float sdCapsule(vec3 p, vec3 a, vec3 b, float r){
    vec3 pa = p-a, ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa-ba*h)-r;
}
```

## 8.11 2D circle and 2D shapes (as used in the plane)

Many 3D SDFs reduce to 2D SDFs via a projection. The **2D circle** is $d=\lVert\mathbf p\rVert-r$ (used inside the tube of the torus). The **2D box** is the 2D analog of §8.3:

$$
d(\mathbf p)=\lVert\max(\lvert\mathbf p\rvert-\mathbf b,0)\rVert+\min(\max(\mathbf d),0),\quad \mathbf d=\lvert\mathbf p\rvert-\mathbf b .
$$

**Rounded rectangle / rounded box (2D)** is the 2D version of §8.4.

## 8.12 Triangle, polygon, regular polygon (2D)

**Triangle SDF.** Using barycentric/signed areas, the distance from a point to a triangle is computed by a clamped projection onto each edge. A standard exact form (iq) returns the signed distance to the triangle using robust barycentric logic.

**General polygon.** For a convex polygon, the SDF is the max over the half-planes of the signed distances to each edge (inside), combined with the distance to nearest edge/vertex outside. The canonical exact 2D polygon SDF iterates over edges, using edge normals and projecting the point. This is the building block for extruded prisms (§8.13) and for lattice/architecture patterns (Chapter 16).

## 8.13 Extruded shapes (prism)

**Derivation.** Extruding a 2D shape $d_2$ (defined in $(x,y)$) along $z$ over half-height $h$ gives

$$
d(\mathbf p)=\operatorname{sdExtrusion}(d_2, z, h).
$$

The closed form:

$$
d(\mathbf p)=\max\!\big(d_2(x,y),\ \lvert z\rvert-h\big)\ \text{is a simple but not exact (for corners)} ;
$$

the *exact* extrusion SDF accounts for the "rim" at the top/bottom via a $\max$/`length` clamp. The standard formula is

$$
d(\mathbf p)=\operatorname{sdExtrusion}(d_2(x,y),\,z,\,h):
=\max\!\left(d_2(x,y),\ \operatorname{clamp}\!\left(\max(d_2(x,y),0)-\text{?}\ \right)\right)
$$

Concretely, a widely used exact extrusion:

$$
d(\mathbf p)=\operatorname{max}\!\big(d_2(x,y),\ \lvert z\rvert-h\big)
$$

is itself a **distance bound** but not exact at corners (it overestimates at the vertical edges). To get the *exact* extrusion SDF, one must treat the 2D field's "half-space" part and its "vertex" part separately; this is the classic `sdExtrusion` that combines `d2` with `max(|z|-h, 0)` and the length of the corner residual. For our purposes, the boundary between "bound" and "exact" is exactly the taxonomy of Chapter 06.

## 8.14 Revolved shapes

**Definition.** Revolve a 2D profile about an axis. If the profile is given in the $(r,z)$ half-plane and we revolve about $z$, then for a 3D point $\mathbf p=(\mathbf p_{x y},z)$ the radial coordinate is $r=\lVert\mathbf p_{x y}\rVert$ and the SDF is

$$
d(\mathbf p)=d_{\text{profile}}(r,z).
$$

**Interpretation.** The 3D re-volved solid's distance equals the 2D profile distance evaluated at $(r,z)$, because revolving about the axis preserves distance (the axial rotation is an isometry). This is exactly the torus construction and the basis for vases, bottles, incense, gears ($\approx$ pole-pitch shaped profiles), and lathe art.

## 8.15 Polyhedra: octahedron and tetrahedron

**Octahedron.** The set $\lvert x\rvert+\lvert y\rvert+\lvert z\rvert\le1$ is a regular octahedron $L_1$ ball. Its SDF is a scaled distance to a pyramid. Because it's a convex polytope, the distance is $(\lVert\mathbf p\rVert_1\text{-ish})/s$ combined with corner clamping. iq's exact form uses a 1-norm trick. As a *bound*, the distance to the octahedron is approximately $\frac{\lVert\mathbf p\rVert_1-1}{\sqrt3}$ (the gradient norm of the $L^1$ ball is $\sqrt3$ on the faces away from edges).

```
SDOctahedron(p, s):  // s = radius
   p = abs(p)
   m = p.x+p.y+p.z - s
   return m * (1/√3) ...  // but must handle edges/corners for exactness
```

**Tetrahedron.** Distance to a regular tetrahedron is likewise a convex-polytope distance. Its exact SDF uses the 4 face normals and the vertex "caps."

For *practical* purposes, polyhedra in raymarching are commonly expressed as the **intersection** (`max`) of a few half-space SDFs with orientation, then made into a solid; the exact "distance to a polytope" boxes are more expensive but give correct bounds.

## 8.16 Summary table

| Primitive | Exact SDF? | Smooth | Cost | Notes |
|-----------|-----------|--------|------|-------|
| Sphere | Yes | Yes | Low | The canonical primitive |
| Plane | Yes | Yes | Low | Clipping/ground |
| Box | Yes | Piecewise | Low | Corner/edge handling |
| Rounded box | Yes | Mostly | Low | Minkowski sum with ball |
| Infinite cylinder | Yes | Yes | Low | `length(p.xz)` |
| Capped cylinder | Yes | Piecewise | Low | End-caps |
| Cone | Yes | Yes | Low | Linear in cone basis |
| Capped cone | Approx/bound | Piecewise | Med | Often via intersection |
| Torus | Yes | Yes | Low | Two roots |
| Capsule | Yes | Yes | Low | Minkowski of segment+ball |
| Segment | Yes | Yes | Low | Capsule with r=0 |
| Extrusion | Exact needs care | Piecewise | Med | Corner handling |
| Revolution | Yes | Yes | Med | Reduce to 2D profile |
| Octahedron | Yes | Piecewise | Med | Corner clamping |
| Tetrahedron | Yes | Piecewise | Med | Vertex caps |

## Exercises

1. **(Derivation)** Derive the sphere SDF and its gradient; show $\lVert\nabla d\rVert=1$ away from the center.
2. **(Derivation)** Derive the box SDF by the "outside + inside" argument; explain why the two terms never both contribute.
3. **(Derivation)** Derive the torus SDF from the ring-circle distance.
4. **(Derivation)** Derive the capsule SDF as the distance to a segment minus $r$; justify the clamp.
5. **(Analytic)** Show that the rounded box is a Minkowski sum of the shrunken box and a ball, and that offsetting an SDF by $-r$ is the correct operation.
6. **(Implementation)** Implement `sdBox`, `sdCylinder`, `sdCapsule`, `sdTorus` in GLSL and test them in a sphere-tracer.
7. **(Design)** Combine a torus and a capsule to make a ring-with-a-handle; describe the visual.
8. **(Derivation)** Derive the revolution SDF and use it to build a vase; explain the isometry argument.
9. **(Analytic)** Identify the medial-axis / non-differentiable sets of the box, the capsule, and the torus.
