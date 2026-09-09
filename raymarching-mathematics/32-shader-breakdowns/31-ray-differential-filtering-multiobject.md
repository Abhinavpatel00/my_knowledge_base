# Shader Breakdown 31 — Ray Differentials, Multi-Object Material IDs, and Screen-Space Filtering

This final breakdown collects three "interface" techniques that make a raymarched scene *clean*: **(1)** using ray differentials to band-limit procedural detail (anti-aliasing), **(2)** returning a **material ID** from the distance function so different parts get different materials, and **(3)** analytic/material-aware **screen-space filtering**. These are the professional-level finishing touches.

## 1. The fragment (reconstructed key parts)

```glsl
// 1) ray differentials: how the ray changes per pixel → the surface footprint
vec2 rayDiff(vec3 ro, vec3 rd, float t){
    return t * iResolution.y / ... ;       // footprint ≈ t / focal
}

// 2) material ID: return the distance AND which primitive was hit
float map(vec3 p, out int mat){  // or return a vec2(d, id)
    float d1 = sdSphere(p, 1.0);
    if(d1 < d){ d = d1; mat = SPHERE; }
    float d2 = sdBox(p, ...);
    if(d2 < d){ d = d2; mat = BOX; }
    ...
    return d;
}

// 3) screen-space filtering: band-limit the texture to the footprint
float footprint = rayDiff(ro, rd, t);
col *= filter(footprint);          // or stop adding octaves above 1/footprint
```

## 2. Mathematics

### 2.1 Ray differentials and the footprint

The ray differential is $\partial\mathbf r/\partial x$ w.r.t. the pixel coordinate $x$. For a perspective camera (Chapter 23), the origin is fixed and the direction varies linearly, so
$$
\frac{\partial\mathbf d}{\partial x}\propto\mathbf r,
\qquad
\frac{\partial\mathbf r(t)}{\partial x}=\frac{\partial\mathbf o}{\partial x}+t\frac{\partial\mathbf d}{\partial x}
\approx t\,\frac{\partial\mathbf d}{\partial x}.
$$
The **surface footprint** — the size of the region a single pixel covers on the surface — is therefore
$$
\text{footprint}\approx\big\lVert t\,\partial\mathbf d/\partial x\big\rVert,
$$
growing linearly with $t$ (distance). So a distant surface has a large footprint.

**Why it's the key to anti-aliasing.** A *procedural* texture being sampled at the hit point has a tiny pixel-scale frequency only for *near* surfaces; for far surfaces, the frequency effectively exceeds the pixel's resolving power → **aliasing / shimmer**. If we **band-limit** the texture to the footprint (i.e. only include octaves whose wavelength $\ge$ footprint, or blur by the footprint), we eliminate the sub-pixel detail that would alias. This is exactly the analogue of choosing a mip level by a texture's footprint.

### 2.2 Material IDs

A raymarched scene often has several primitives. To shade each correctly, `map` returns both the distance and a **material ID** (`mat`). The `min` over primitives is augmented with a "which one won" bookkeeping. This is the 3D/branching version of the boolean (Chapter 9), tracking the *identity* of the nearest surface.

**Field class.** The field is still a bound/`min` union; the material ID is a side-channel. It's used to pick the color/roughness/reflective properties per surface. Because the union of exact SDFs is exact (up to the nondifferentiability at the seam), the material ID transfers correctly to whichever surface is nearest.

### 2.3 Screen-space / analytic filtering

The band-limit can be done by:
- **Truncating an fBm octave sum.** Stop adding octaves once their frequency exceeds $1/\text{footprint}$ (Chapter 18/17). This gives *distance-adaptive* detail.
- **A filter kernel.** Blur the texture by the footprint (a Gaussian/bilinear footprint), or use an analytic cosine filter.
- **Derivative-aware filtration.** Using the *analytic* noise gradient (Chapter 17) to compute an exact first-order filtered value (band-limited to the pixel).

The result: a raymarched scene that doesn't "shimmer" and whose detail density adapts to the screen.

## 3. The "thinking process"

1. **Aliasing.** "Far, high-frequency detail shimmers." → band-limit with the **ray differential footprint**.
2. **Multi-material.** "Different parts, different materials." → return a **material ID** from `map`.
3. **Filter.** "Resolve to the pixel." → truncate/smooth texture octaves to the footprint.

## 4. Extensions

- **Mip-style procedural.** Precompute several octave levels and sample the appropriate one (the "procedural mip" of ray differentials).
- **Temporal accumulation.** Combine with a jittered supersampling (Chapter 23) for the highest quality.
- **Footprint-driven DDX.** Use screen-space derivatives of the hit point (`dFdx`) directly for the footprint — the simplest practical version.
- **Material blending at seams.** Smoothly blend material IDs near a boolean seam, or use the smooth-min's weight to blend (Chapter 9).

## Exercises

1. **(Derivation)** Derive the ray differential and the footprint for a perspective camera.
2. **(Derivation)** Show how to truncate an fBm octave sum based on the footprint.
3. **(Field class)** Explain why the material ID is a side-channel to the (exact) min union.
4. **(Analytic)** Explain why footprint-based filtering eliminates shimmer and is the "mip" for procedural textures.
5. **(Implementation)** Implement `map` that returns both distance and material ID.
6. **(Implementation)** Apply footprint-based octave truncation to reduce shimmer.
