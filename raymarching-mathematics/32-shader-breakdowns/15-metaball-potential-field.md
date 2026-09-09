# Shader Breakdown 15 — Metaballs: A Potential Field, Not an SDF

Metaballs (and the "goo"/"blob" look of a family of spheres) are often described with the language of SDFs, but the classic metaball is actually a **potential field** rendered by *isosurfacing a threshold*. This is a critical distinction (Chapter 6 taxonomy): a metaball field is generally **not a distance**, and rendering it requires care. This breakdown derives the metaball field and shows how it differs from a true distance field.

## 1. The fragment (reconstructed key parts)

```glsl
float metaball(vec2 p, vec2 c, float r){
    float d = length(p - c);
    return r*r / (d*d);                 // a 1/r^2 potential (non-SDF)
}

float field(vec2 p){
    float v = 0.0;
    for(int i=0;i<N;i++) v += metaball(p, centers[i], radii[i]);
    return v;
}

void mainImage(...){
    float v = field(uv);
    float iso = smoothstep(1.0, 0.94, v);   // surface at v ≈ 1 (threshold)
    color = ... iso ...
}
```

## 2. Mathematics

### 2.1 The potential field

Each metaball contributes a **potential** that decays with distance. A common form is the inverse-power potential
$$
\phi_i(\mathbf p)=\frac{r_i^2}{\lVert\mathbf p-\mathbf c_i\rVert^2}.
$$
The total field is the **sum**
$$
\Phi(\mathbf p)=\sum_i\phi_i(\mathbf p).
$$
The surface is the **isosurface** $\Phi(\mathbf p)=1$ (some threshold $T$). Points inside ("blippy" region) have $\Phi>1$, outside have $\Phi<1$.

### 2.2 Why this is fundamentally not a distance

An SDF is characterized by $\lVert\nabla d\rVert=1$ almost everywhere (the eikonal property, Chapter 6). But $\Phi$ is a sum of decaying potentials, so:

1. **It is not 1-Lipschitz.** Near a ball center $\phi_i\to\infty$; far away it decays slowly. The gradient is
$$
\nabla\phi_i=-\frac{2r_i^2(\mathbf p-\mathbf c_i)}{\lVert\mathbf p-\mathbf c_i\rVert^4},\qquad
\lVert\nabla\phi_i\rVert=\frac{2r_i^2}{\lVert\mathbf p-\mathbf c_i\rVert^3},
$$
which is unbounded as $\mathbf p\to\mathbf c_i$ and tiny far away. So $\Phi$ has no single Lipschitz constant, and certainly not 1.
2. **It is not a distance.** $\Phi(\mathbf p)$ is not the distance to any surface; it's a scalar potential whose *level set* happens to look like a blob.

**Consequence.** The metaball field is the **"arbitrary scalar field"** (or, more precisely, a *potential field*) row of the Chapter 6 taxonomy. It carries **no safe step**. To render it you either:
- **(a)** march with a **fixed small step** (a volumetric/level-set march), or
- **(b)** **reparameterize** the field into a distance using the gradient estimate: $\hat d\approx(\Phi-T)/\lVert\nabla\Phi\rVert$ (Chapter 31b). This gives a first-order distance estimate.

### 2.3 The isosurface and its "melt" behavior

The field is the **sum** of the potentials. When two balls are near each other, their potentials **add**, raising the field between them above the threshold. This is what makes the balls "melt" into a single blob when they're close, and split when they're far. The degree of blending is governed by the threshold and the falloff exponent.

**Why the sum is the source of the blend.** For an SDF, the union is `min` (Chapter 9), which *does not* blend — it's a hard union. For a potential field, the sum *does* blend, because potentials add. This is precisely why metaballs give smooth melty forms and SDF unions give hard creases. It's a fundamental mathematical difference, not a cosmetic one.

### 2.4 The threshold as a "morphing" parameter

The isosurface $\Phi=T$ for different $T$ gives different shapes:
- Larger $T$ → surface is smaller/tighter around the balls.
- Smaller $T$ → surface is larger and the balls blend more.
So $T$ is a *blob amount* knob. If you animate $T$ over time, the object smoothly grows/blends/splits — a topology-changing morph, rendered implicitly (Chapter 22).

## 3. Field-class table

| Quantity | Class |
|----------|-------|
| $\phi_i=r_i^2/\lVert p-c\rVert^2$ | potential (not distance) |
| $\Phi=\sum\phi_i$ | **potential field** |
| isosurface $\Phi=T$ | implicit surface (Chapter 5) |
| gradient estimate $\hat d=(\Phi-T)/\lVert\nabla\Phi\rVert$ | first-order distance estimate |

## 4. The "thinking process"

1. **Ideas.** "I want smooth, melty, blobby forms." → a potential field that sums.
2. **Merge.** "Balls should melt when close." → *sum* potentials (unlike an SDF's `min`).
3. **Surface.** "Where is the surface?" → the isosurface $\Phi=T$.
4. **Safety.** "This isn't a distance." → either fixed-step march or reparameterize via the gradient estimate.

## 5. Extensions

- **Higher falloff.** Change the exponent: `1/d^2` gives soft, `1/d^3` or `exp(-k d)` gives sharper/tighter blobs or "harder" melts.
- **Signed metaballs.** Subtract a potential (negative ball) to carve "holes" in a melt.
- **Animated centers.** Move the ball centers (springs, noise, or flow) — the melt flows, and the topology changes smoothly.
- **Volumetric metaballs.** Use the field value as a *density* in a volumetric render (Chapter 21) rather than a hard surface, for "smoke-like" blobs.
- **The "gooey" 2D look.** XorDev-style goo is very often this same potential field, with a smooth `smoothstep` threshold (Breakdown 1), and is rendered *without* a ray march — it's just a 2D field-remap.

## Exercises

1. **(Derivation)** Compute $\nabla\phi_i$ and its norm; show it's unbounded near the center, so $\Phi$ is not 1-Lipschitz.
2. **(Analytic)** Explain why summing potentials *blends* while an SDF `min` does not.
3. **(Derivation)** Derive the gradient distance estimate $\hat d=(\Phi-T)/\lVert\nabla\Phi\rVert$ and state when it's first-order exact.
4. **(Field class)** Classify the metaball field against the Chapter 6 taxonomy.
5. **(Analytic)** Explain how the threshold $T$ controls blending and morphing.
6. **(Design)** Merge metaballs into a volumetric render; describe the density interpretation.
