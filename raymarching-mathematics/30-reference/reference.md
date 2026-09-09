# Chapter 30 — Reference

This chapter is the book's formulary: the identities, formulas, and algorithms most frequently needed to construct and understand raymarched shaders. It doubles as the appendices A–O.

---

## Appendix A — Notation

| Symbol | Meaning |
|--------|---------|
| $\mathbf p$ | a point in space (sample point) |
| $\mathbf o$ | ray origin |
| $\mathbf d$ | ray direction, $\lVert\mathbf d\rVert=1$ |
| $\mathbf n$ | unit normal |
| $\mathbf l$ | unit direction toward a light |
| $\mathbf v$ | unit direction toward the viewer (surface → camera) |
| $\mathbf h$ | half vector = normalize($\mathbf l+\mathbf v$) |
| $\mathbf r$ | reflected direction / right vector (context) |
| $t$ | ray parameter / distance |
| $d(\mathbf p)$ | signed distance field |
| $d(\mathbf p,S)$ | unsigned distance to a set |
| $D(\mathbf p)$ | distance estimator |
| $\nabla f$ | gradient of $f$ |
| $J_f$ | Jacobian of $f$ |
| $H_f$ | Hessian of $f$ |
| $f^{-1}(c)$ | level set at $c$ |
| $\lVert\cdot\rVert$ | Euclidean norm |
| $\mathbf a\cdot\mathbf b$ | dot product |
| $\mathbf a\times\mathbf b$ | cross product |
| $\operatorname{mod}(x,a)$ | $x-a\lfloor x/a\rfloor$ |

---

## Appendix B — Vector identities

- $\lVert\mathbf a\rVert^2=\mathbf a\cdot\mathbf a$
- $\mathbf a\cdot\mathbf b=\lVert\mathbf a\rVert\lVert\mathbf b\rVert\cos\theta$
- $\lVert\mathbf a\times\mathbf b\rVert=\lVert\mathbf a\rVert\lVert\mathbf b\rVert\sin\theta$
- $\mathbf a\times\mathbf b=\mathbf 0 \iff \mathbf a\parallel\mathbf b$
- $\mathbf a\cdot(\mathbf b\times\mathbf c)=\mathbf b\cdot(\mathbf c\times\mathbf a)=\mathbf c\cdot(\mathbf a\times\mathbf b)$
- $\mathbf a\times(\mathbf b\times\mathbf c)=\mathbf b(\mathbf a\cdot\mathbf c)-\mathbf c(\mathbf a\cdot\mathbf b)$
- $\mathbf a\times(\mathbf b+\mathbf c)=\mathbf a\times\mathbf b+\mathbf a\times\mathbf c$
- Reflexion: $\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n$
- Projection of $\mathbf b$ onto unit $\mathbf u$: $(\mathbf b\cdot\mathbf u)\mathbf u$

---

## Appendix C — Matrix identities

- $(AB)^T=B^TA^T$
- $(AB)^{-1}=B^{-1}A^{-1}$
- $R^TR=I$ (orthogonal), $\lVert R\mathbf x\rVert=\lVert\mathbf x\rVert$
- Rotation about $z$: $\begin{pmatrix}\cos\theta&-\sin\theta&0\\\sin\theta&\cos\theta&0\\0&0&1\end{pmatrix}$
- Rodrigues rotation about unit $\mathbf a$: $R\mathbf x=\mathbf x\cos\theta+(\mathbf a\times\mathbf x)\sin\theta+\mathbf a(\mathbf a\cdot\mathbf x)(1-\cos\theta)$
- Jacobian of composition: $J_{f\circ g}=J_f\cdot J_g$

---

## Appendix D — Trigonometric identities

- $\sin^2\theta+\cos^2\theta=1$
- $\sin(a+b)=\sin a\cos b+\cos a\sin b$
- $\cos(a+b)=\cos a\cos b-\sin a\sin b$
- $\sin(2\theta)=2\sin\theta\cos\theta$
- $\cos(2\theta)=\cos^2\theta-\sin^2\theta$
- $\operatorname{atan2}$ order: $\theta=\operatorname{atan2}(y,x)$
- Polar↔Cartesian: $x=r\cos\theta,\ y=r\sin\theta$; $r=\sqrt{x^2+y^2}$

---

## Appendix E — Common SDF formulas

| Primitive | SDF |
|-----------|-----|
| Sphere | `length(p)-r` |
| Plane (n unit) | `dot(p,n)-c` |
| Box (half-extents b) | `q=abs(p)-b; length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)` |
| Rounded box | `sdBox(p, b-r)-r` |
| Infinite cylinder | `length(p.xz)-r` |
| Capped cylinder | `d=vec2(length(p.xz),abs(p.y))-vec2(r,h); min(max(d.x,d.y),0.)+length(max(d,0.))` |
| Torus | `q=vec2(length(p.xz)-R, p.y); length(q)-r` |
| Capsule | `h=clamp(dot(pa,ba)/dot(ba,ba),0.,1.); length(pa-ba*h)-r` |
| Segment | capsule with r=0 |
| Extrusion | `max(d2, |z|-h)` (bound) or exact form |
| Revolution | `d_profile(r, z)` with `r=length(p.xz)` |

---

## Appendix F — Common transformations

| Transform | Map | Distance class |
|-----------|-----|----------------|
| Translation | `p-c` | exact |
| Rotation | `R p` | exact |
| Reflection | `abs(p)-c` (if symmetric) | exact |
| Uniform scale | `s * p` | exact (`s*d(p/s)`) |
| Non-uniform scale | `D p` | bound |
| Repetition | `mod(p+a/2,a)-a/2` | exact |
| Twist | rotate by $k\,p_y$ | bound |
| Bend | arc-length rotation | bound |
| Taper | scale cross-section by $f(p_y)$ | bound |
| Domain warp | `p + W(p)` | bound/estimator |

---

## Appendix G — Common noise equations

- Value noise: `<hash corners>` + smoothstep $3t^2-2t^3$ bilinear/tri-linear blend.
- Perlin (gradient) noise: dot gradients with offsets, weighted blend.
- fBm: $\sum_i a_i\,n(2^i\mathbf p+\text{offset}_i)$, $a_i=\text{gain}^i$.
- Turbulence: $\sum_i a_i\,|n(\ldots)|$.
- Ridged: $\sum_i (1-|n(\ldots)|)^p/2^i$.
- Smoothstep: $3t^2-2t^3$.
- Hash (2D): `fract(sin(dot(p,vec2(...)))*43758.5453)` or the modern `fract(p*=vec2(...)); p+=dot(p,p+...); return fract(p.x*p.y)`.

---

## Appendix H — Common lighting equations

- Lambert: $L_d=\rho\,I\,\max(0,\mathbf n\cdot\mathbf l)$.
- Blinn-Phong specular: $I_s k_s \max(0,\mathbf n\cdot\mathbf h)^m$.
- GGX $D$: $\frac{\alpha^2}{\pi((\mathbf n\cdot\mathbf h)^2(\alpha^2-1)+1)^2}$.
- Cook–Torrance: $\frac{D\,G\,F}{4(\mathbf n\cdot\mathbf l)(\mathbf n\cdot\mathbf v)}$.
- Fresnel / Schlick: $F(\theta)=F_0+(1-F_0)(1-\cos\theta)^5$, $F_0=(\frac{1-\eta}{1+\eta})^2$.
- Reflection: $\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n$.
- Refraction: $\mathbf t=\mu\mathbf d+(\mu\cos\theta_i-\cos\theta_t)\mathbf n$, $\mu=\eta_i/\eta_t$, $\cos\theta_t=\sqrt{1-\mu^2(1-\cos^2\theta_i)}$.

---

## Appendix I — Raymarching algorithms

```
t = 0
for n in 0..MAX:
    p = o + t*d
    delta = map(p)
    if delta < eps: return t
    t += delta            # safe step (if map is a distance/bound)
    if t > FAR: return far
return far
```

**Soft shadow:**

```
res = 1
for n in 0..MAX:
    d = map(p + t*l); res = min(res, k*d/t); t += d
    if res < tol or t > lightDist: break
return clamp(res,0,1)
```

**SDF AO:**

```
occ = 0
for i in 0..N:
    d = t0*i; occ += max(0., d - map(p + n*d)) * weight(i)
```

---

## Appendix J — Distance estimator patterns

- Running derivative: $dr_{k+1}=p\,|z_k|^{p-1}dr_k+1$, $dr_0=0$.
- Mandelbulb DE: $\text{DE}=0.5\,\log(r)\,r/dr$.
- Mandelbox DE: box fold (isometry, no change to $dr$), sphere fold (scale by $(R/r)^2$ or $(R/r_{\min})^2$), multiply $dr$ by the fold's scale, then `scale*dr+1`.
- Dual-number DE: full Jacobian $D$, $\text{DE}=\lVert z\rVert^2/\lVert z\cdot D\rVert$.
- $\text{DE}=0.5\,G(\mathbf p)/|\nabla G(\mathbf p)|$ (potential gradient form).

---

## Appendix K — GLSL mathematical reference

| GLSL | Math | Notes |
|------|------|-------|
| `dot(a,b)` | $\mathbf a\cdot\mathbf b$ | |
| `cross(a,b)` | $\mathbf a\times\mathbf b$ | |
| `length(v)` | $\lVert\mathbf v\rVert$ | uses sqrt |
| `normalize(v)` | $\mathbf v/\lVert\mathbf v\rVert$ | |
| `abs`, `sign`, `floor`, `fract`, `mod`, `mix`, `clamp`, `smoothstep` | as named | |
| `reflect(d,n)` | $\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n$ | d points toward surface |
| `refract(d,n,eta)` | Snell vector | returns 0 on TIR |
| `exp2`, `log2`, `pow`, `sin`, `cos`, `atan`, `atan2`, `sqrt`, `inversesqrt` | as named | `pow(x,y)=exp2(y*log2(x))` |

---

## Appendix L — Numerical stability checklist

1. Re-center coordinates to avoid large-magnitude cancellation.
2. Use an adaptive epsilon $\varepsilon(t)=\varepsilon_0(1+kt)$ for depth.
3. Pick normal $\varepsilon$ near the optimal (between noise and blur).
4. Guard divisions/`log` with `max(x, 1e-6)`.
5. Avoid subtracting nearly-equal magnitudes.
6. Prefer `highp` for positions and normals.
7. Clamp `d` to a small positive floor in marching to guarantee strict progress.

---

## Appendix M — Performance checklist

1. Reduce step count (better distance bound, adaptive epsilon, early exit).
2. Use a cheap bounding volume to skip empty space.
3. Avoid `normalize` where the vector is already unit.
4. Avoid transcendental functions where a cheap equivalent suffices.
5. Move cheap tests before expensive ones.
6. Keep loop bounds as low as the scene allows (warp divergence).
7. Lower the loop cap; it bounds worst-case cost.

---

## Appendix N — Shader debugging checklist

1. Wrong aspect ratio → ellipses instead of circles.
2. Choppy normals → normal $\varepsilon$ too large or field is a bound.
3. Sparkle/glare on normals → normal $\varepsilon$ too small (float noise).
4. Banding in shadows/AO → too few samples.
5. Tunneling/overshoot → field overestimates distance (bad estimator).
6. Popping in animation → discontinuity in $t$.
7. No image / black → failed hit or `T_MAX` too small.

---

## Appendix O — Recommended literature and papers

- **John C. Hart**, *Sphere Tracing: A Geometric Method for the Antialiased Ray Tracing of Implicit Surfaces* (1995) — the sphere-tracing algorithm and its guarantees.
- **John C. Hart et al.**, *Ray Tracing Deterministic 3-D Fractals* (1989) — distance-estimated rendering of fractals.
- **Iñigo Quilez**, *Distance functions*, *Smooth minimums*, *Raymarching SDFs*, *Mandelbulb* — the modern SDF/raymarching reference material.
- **Douady & Hubbard**, *Iteration des polynômes quadratiques complexes* (1982) — the potential theory underlying the DE.
- **Claude Heiland-Allen**, *Distance Estimation for Hybrid Escape Time Fractals* — derivation of DEs, including Mandelbrot/Mandelbox.
- **Tom Lowe / Fractal Forums community (Buddhi, Makin)** — Mandelbox scalar-deviation DE.
- **Daniel White & Paul Nylander** — the Mandelbulb.
- **Ken Perlin**, *An Image Synthesizer* (1985) and *Improving Noise* — gradient noise.
- **A. Worley**, *A Cellular Texture Basis Function* — Voronoi/Worley cellular textures.
- **Robert Cook & Kenneth Torrance**, *A Reflectance Model for Computer Graphics* — the microfacet BRDF.
- **E. Heitz**, *Understanding the Masking-Shadowing Function in Microfacet BRDFs* — GGX/Smith.
- **Pharr, Jakob, Humphreys**, *Physically Based Rendering* — light transport and volume rendering (Beer–Lambert).
- **ShaderToy / GLSL ES documentation** — the target platform and conventions.

---

*This corpus is a synthesis of the above sources, derived and re-explained in the book's own words except where standard mathematical formulas (not copyrightable) are restated. See the Preface for the sourcing policy.*
