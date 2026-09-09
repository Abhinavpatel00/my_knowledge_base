# Chapter 23 — Camera Mathematics

The camera turns pixel coordinates into rays. This chapter derives the ray-generation mathematics: the camera basis, perspective projection, field of view, aspect ratio, and how shaders normalize screen coordinates. It also covers orbit cameras and how to filter (anti-alias) via ray differentials.

## 23.1 The camera basis

Define the camera by an **origin** $\mathbf o$ and an orientation given by three orthonormal vectors:

- **Forward** $\mathbf f$ — the direction the camera looks,
- **Right** $\mathbf r$ — pointing to the right of the view,
- **Up** $\mathbf u$ — pointing up.

They satisfy $\mathbf r\cdot\mathbf f=0$, $\mathbf u\cdot\mathbf f=0$, $\mathbf r\times\mathbf u=\mathbf f$ (a right-handed frame). In practice: given a forward direction and an "up hint" $\mathbf u_{\text{hint}}$, derive

$$
\mathbf r=\operatorname{normalize}(\mathbf f\times\mathbf u_{\text{hint}}),\qquad
\mathbf u=\mathbf r\times\mathbf f .
$$

**Why normalize.** Only the *direction* of forward/up matters; the frame must be orthonormal for the projection math to be exact.

## 23.2 Screen coordinates and normalization

The fragment shader receives the pixel coordinate `fragCoord` (in `[0,iResolution]`). Normalize to the range $[-1,1]$:

$$
\mathbf{uv}=2\cdot\frac{\text{fragCoord}}{\text{iResolution.xy}}-1 .
$$

**Why scale by resolution.** To make the coordinate system resolution-independent and to handle aspect ratio. After normalization, $uv.x\in[-1,1]$ and $uv.y\in[-1,1]$, but the *physical* aspect ratio of the screen is `iResolution.x / iResolution.y`. To avoid **stretched** images, correct the horizontal coordinate by the aspect ratio:

$$
u=uv.x\cdot\frac{\text{iResolution.x}}{\text{iResolution.y}} .
$$

**Derivation.** The image spans $[-1,1]$ in both axes, so an equal change in $uv.x$ and $uv.y$ covers the same number of pixels, but the screen is wider than tall. Scaling $uv.x$ by the aspect ratio makes the *screen-space* units proportional to *world* units, so features at the same world distance appear round (not elliptical). This is why failing to correct aspect ratio makes circles into ellipses.

## 23.3 Perspective projection

For a **perspective** camera with field of view, the ray through a screen point is a *cone* emanating from the origin. The base (image plane) is at distance $1$ along the forward axis. In camera-local coordinates, the pixel maps to

$$
\mathbf{p}_{cam}=(u,\ v,\ 1)
$$

(the $1$ puts the plane at distance $1$ in front of the camera). The ray direction in world space is

$$
\mathbf d=\operatorname{normalize}\big(u\,\mathbf r+v\,\mathbf u+1\,\mathbf f\big).
$$

**Derivation.** The image plane is spanned by right and up, at a distance $1$ along forward. A displacement of $u$ in the camera's horizontal and $v$ in vertical, at that plane, gives the local point; transforming to world via the basis and normalizing gives the direction. This is the standard "pinhole camera" ray.

**Field of view (FOV).** The normalization by `1` sets a fixed "focal length." To control FOV, introduce a **focal length** $L$ (distance from the camera to the image plane) — equivalently scale the plane's forward component:

$$
\mathbf d=\operatorname{normalize}\big(u\,\mathbf r+v\,\mathbf u+L\,\mathbf f\big),
$$

or equivalently scale $u,v$ by `tan(fov/2)`. The **vertical FOV** relation:

$$
\frac{1}{L}=\tan\!\Big(\frac{\text{fov}}{2}\Big).
$$

So a larger FOV ↔ smaller $L$ ↔ a "wider" cone of rays; a smaller FOV ↔ longer $L$ ↔ a "narrower," more telephoto look.

## 23.4 Orthographic projection

For an **orthographic** camera, all rays are parallel (they all point along $\mathbf f$), and the image plane is at an infinite distance (or at least the rays do not converge). The ray origin varies across the screen:

$$
\mathbf o'=\mathbf o+u\,\mathbf r+v\,\mathbf u,\qquad \mathbf d=\mathbf f .
$$

So the ray is $\mathbf r(t)=\mathbf o'+t\mathbf f$. **Use for:** technical/blueprint views, texture-baking-on-a-plane, and "flat" styles where perspective distortion is undesirable.

## 23.5 Deriving the ray in GLSL (perspective)

```glsl
Vec2 uv = (2.0*fragCoord - iResolution.xy) / iResolution.y;
// aspect-corrected: uv.x already spans width/height by dividing by iResolution.y
vec3 ro = vec3(0.0,0.0, ...);        // camera origin
vec3 rd = normalize(vec3(uv, -1.0)); // perspective: plane at z=-1
// or with FOV: vec3 rd = normalize(vec3(uv*tanHalfFov, -1.0));
```

**Note on the front direction sign.** The sign convention for which axis is "forward" varies; pick one consistently and keep the right-handed frame consistent.

## 23.6 Aspect ratio handling summary

| Goal | Action |
|------|--------|
| Map pixels to $[-1,1]$ | `2*fragCoord/res - 1` |
| Correct aspect ratio | scale the *horizontal* coordinate by `res.x/res.y`, OR divide both by `res.y` |
| Set FOV | multiply `uv` by `tan(fov/2)` |

## 23.7 Orbit / look-at cameras

An **orbit camera** swings around a target point $\mathbf t$ at distance $d$ with angles $\theta$ (azimuth) and $\phi$ (elevation):

$$
\mathbf o=\mathbf t+d\,\big(\sin\theta\cos\phi,\ \sin\phi,\ \cos\theta\cos\phi\big),
$$

and the forward vector points from $\mathbf o$ to $\mathbf t$: $\mathbf f=\operatorname{normalize}(\mathbf t-\mathbf o)$. Build the right/up from $\mathbf f$ and an up hint. This is the standard interactive camera for exploring a scene (and for the "look at a procedural object" genre of ShaderToy).

## 23.8 Ray differentials and anti-aliasing

A **ray differential** is the derivative of the ray with respect to the pixel coordinate. It tells us how much the ray *changes* as we move 1 pixel, which measures the local footprint of the ray on the surface. This is used for:

- **Filtering.** The ray differential gives the *footprint size* on the surface — the region a single pixel covers. Procedural textures (and normals) can be filtered/band-limited to that size, reducing aliasing. This is the "ray differentials" technique (inigo quilez, and classic graphics).
- **Anti-aliasing.** Computed as $\partial\mathbf o/\partial x+\partial\mathbf d/\partial x\cdot t$ (and similarly for $y$). For a perspective camera, $\partial\mathbf d/\partial x$ is constant (the direction changes linearly with pixel), giving $\partial\mathbf o=0$ (fixed origin) and $\partial\mathbf d\propto\mathbf r$. So the surface footprint grows with distance.

**Why it matters.** Without ray differentials, a sharp high-frequency procedural texture mapped onto a distant surface produces **aliasing / shimmer** (the "moiré" and sparkle). Ray differentials let us band-limit the texture to the pixel footprint.

## 23.9 Anti-aliasing via supersampling vs. temporal accumulation

- **Supersampling (SSAA).** Trace several rays per pixel and average. Reduces aliasing but multiplies cost by the sample count. It is a "brute-force" anti-aliasing.
- **Temporal accumulation.** Reuse the previous frame and jitter the pixel per frame (a temporal anti-aliasing). Cheap per-frame but risks ghosting (temporal artifacts) with moving content.

For raymarched *surfaces*, the **ray differential / filter** approach is the cleanest: instead of more samples, make each pixel's sample *band-limited* to its footprint (see the "game of life / fractal filter" note in Chapter 24).

## Exercises

1. **(Derivation)** Derive the perspective ray from the camera basis and the image-plane geometry.
2. **(Derivation)** Show that aspect-ratio correction is needed and how it works.
3. **(Derivation)** Derive the relationship between FOV and the focal length $L$ via `tan(fov/2)`.
4. **(Implementation)** Implement a perspective ray generator and an orbit camera.
5. **(Derivation)** Derive the ray differential for a perspective camera and explain how it gives the surface footprint.
6. **(Design)** Explain when to use orthographic vs. perspective, and the visual difference.
7. **(Analytic)** Explain why ray differentials reduce aliasing vs. why supersampling reduces it.
