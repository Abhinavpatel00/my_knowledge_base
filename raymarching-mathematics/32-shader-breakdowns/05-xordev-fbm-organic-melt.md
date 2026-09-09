# Shader Breakdown 5 — XorDev-style fBm "Organic Melt" (domain warp + ripple)

A signature look in XorDev-style minimal shaders is a **metaball-organic** surface with a *melted, rippled* skin. It combines smooth-min (Ch. 9), fBm domain warping (Ch. 16), and an fBm surface displacement. Let's reconstruct a representative fragment rigorously.

## 1. The fragment

```glsl
float map(vec3 p){
    p = rot(p, iTime);                       // isometry
    vec3 q = p - 0.5*fbm(p*1.5);             // domain warp (vector)
    float d = sdSphere(q, 1.2);              // a blob
    d = smin(d, sdSphere(q-vec3(1.3,0,0), .8), .4);   // smooth union
    return d;
}

float fbm(vec3 p){
    float f = 0., a = .5;
    for(int i=0;i<4;i++){ f += a*noise(p); p*=2.; a*=.5; }  // 4 octaves
    return f;
}
```

## 2. Reconstruct the mathematics

### Step A — Rotation (isometry)
`rot(p, iTime)`: a time-dependent rotation. Isometry → exactness preserved, motion coherent.

### Step B — Domain warp (vector)
`q = p - 0.5*fbm(p*1.5)`:
$$
\mathbf q(\mathbf p)=\mathbf p-\lambda\,\mathbf F(\mathbf p),\qquad \lambda=0.5,\quad \mathbf F=\text{fbm vector field}.
$$
This is a **vector domain warp**: the coordinates fed to the blob are displaced by an fBm vector field. Because $\mathbf F$ varies smoothly and $\lambda$ is small, the warp *folds and swirls* the space, turning a smooth blob into a marbled, "melted" shape. It is **not** an isometry — the map's Jacobian is $I-\lambda J_{\mathbf F}$, so it can stretch, compress, and fold the domain. The result is a **distance bound** (and if the warp is strong, a non-injective map → the field is no longer a reliable distance, only an *estimator*).

### Step C — The base blob
`sdSphere(q, 1.2)`:
$$
d_1=\lVert\mathbf q\rVert-1.2 .
$$
Exact SDF (of the *warped* coordinate; the warp makes the *computed* field a bound).

### Step D — Smooth union
`d = smin(d_1, d_2, 0.4)` with $d_2=\lVert\mathbf q-(1.3,0,0)\rVert-0.8$. This is a smooth min (Ch. 9) — a bound. So **this blob is not an exact distance**; it's a smooth union of warped spheres, which is a bound on the actual melty surface.

## 3. Field-class analysis

| Stage | Operation | Isometry? | Field class |
|-------|-----------|-----------|-------------|
| Rotation | $R(\theta)$ | yes | exact preserved |
| Domain warp | $\mathbf p-\lambda\mathbf F(\mathbf p)$ | no | bound / estimator |
| Sphere | $\lVert\mathbf q\rVert-r$ | — | exact (in $\mathbf q$) |
| Smooth union | smin | no | bound |

**Conclusion.** The whole field is a **smooth, warped bound**. It renders beautifully because the error is smooth and small (the warp $\lambda$ is modest, the smooth union is mild), and the raymarcher uses a slightly conservative step. This is the canonical "organic melt" scenario: **you knowingly give up exactness to get the melted aesthetic, and the march is safe because the field is still conservative.**

## 4. The "thinking process"

1. **Base form.** "I want a blob." → a sphere.
2. **Organic.** "I want it to look alive, not like a ball." → smooth-union two spheres, optionally add a third.
3. **Melt/Marble.** "I want the surface to swirl and marble like liquid." → **domain warp** the coordinates with fBm. This is the key move: warping the *input* rather than the *output* is what makes the surface twist into marble-like flow.
4. **Detail.** "I want fine ripples on top of the melt." → a separate **fBm displacement** on the radius (or on the final distance: `d += λ*fbm(k*p)`).
5. **Motion.** "I want it to flow." → rotate the input / advect the warp offset with `iTime`.

The chain: **sphere + smooth-union + domain-warp + fBm displacement + rotation = organic melt.** The mathematical richness is in the composition; the field is a conservative bound.

## 5. The two distinct fBm uses

It is worth separating two roles fBm plays, because they have different mathematical effects:

| Role | Form | Field class | Purpose |
|------|------|-------------|---------|
| **Domain warp** | $q=p-\lambda\,F(p)$ | warp (bound/estimator) | swirls the *coordinates* → marble/flow |
| **Displacement** | $d\gets d+\lambda\,F(p)$ | displacement (bound) | adds *ripple/detail* to the *surface* |

The difference is whether fBm acts on the *independent variable* (domain warp) or on the *field value* (displacement). Both make the field a bound, but they produce different visuals: warp = twisting, displacement = rough surface.

## 6. Extensions

### 6.1 Increase the warp strength
As $\lambda$ grows, the warp eventually becomes **non-injective** (space folds over itself), producing "self-intersecting" marble and, crucially, a field that is no longer a reliable distance — it can *overestimate* and cause tunneling. The safe approach: keep $\lambda$ small, or rescale the field step, or clamp the warp.

### 6.2 Multi-layer domain warp
The famous "triple warp":
$$
q=fbm(p),\quad r=fbm(p+q),\quad f=fbm(p+r).
$$
Each layer adds a level of swirling. This is the Inigo Quilez "warping fBm" classic. It compounds the non-injectivity, so it's even more a *bound/estimator* — but it looks stunning.

### 6.3 Animate the warp offset
Add a time offset to the fBm input: `fbm(p + vec3(0.,0.,iTime))`. Smooth in time → coherent flow (Chapter 22).

### 6.4 Combine with Voronoi cells
For a "cellular melt," replace the fBm warp with a **Voronoi**-warped field (Chapter 18). The melt then derives from cell boundaries as well as noise. This produces organic biological tissue/cracked-melt motifs.

### 6.5 Curvature-driven bevels
For a "gel" look, add a mean-curvature term (Chapter 12) to the shading (e.g. an inner-glow or a specular bevel along creases). This is a *shading* modification, not a field change, so it doesn't affect safety.

### 6.6 Ray-marched soft-AO goo
The melty blob looks best with **SDF ambient occlusion** (Chapter 14) and a curvature-based glow in the creases. Both use the same field (more marching) and are mathematically standard.

## Exercises

1. **(Analytic)** Distinguish domain warp from displacement: which acts on the independent variable, which on the field value, and what visual each gives.
2. **(Derivation)** Compute the Jacobian $I-\lambda J_{\mathbf F}$ of the domain warp and its spectral norm; state when it becomes non-injective.
3. **(Field class)** Classify the "sphere + smooth union + domain warp + fBm" field and explain why it's a bound/estimator.
4. **(Analytic)** Explain why a strong warp can cause tunneling, and how to keep the march safe.
5. **(Design)** Build a 2- and 3-layer domain warp; describe the increasing complexity and the safety implication.
6. **(Implementation)** Add a small fBm displacement to the sphere to produce ripples; vary the amplitude and describe the roughness change.
7. **(Reverse engineering)** Given a fragment using `p - 0.5*fbm(...)`, identify the structural move and the resulting field class.
