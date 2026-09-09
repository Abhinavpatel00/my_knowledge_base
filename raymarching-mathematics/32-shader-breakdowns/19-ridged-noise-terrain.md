# Shader Breakdown 19 — Ridged-Noise Terrain and Heightfield Mountains

Terrain is one of the most satisfying procedural outputs. The canonical approach is a **heightsfield** (Chapter 6 taxonomy: a height field, not a distance) driven by **ridged noise** — a variant of fBm that produces sharp crests and valleys. This breakdown derives the ridged-noise field and its use in terrain.

## 1. The fragment (reconstructed key parts)

```glsl
float ridged(vec2 p, int octaves){
    float amp = 0.5, freq = 1.0, sum = 0.0;
    for(int i=0;i<octaves;i++){
        // 1 - |noise| : invert the noise so its crest becomes a ridge
        float n = 1.0 - abs(noise(p * freq));
        n = n * n;                                 // sharpen the ridge
        sum += n * amp;
        amp *= 0.5; freq *= 2.0;                   // classic gain/lacunarity
    }
    return sum;
}

float terrain_height(vec2 xz){
    return 60.0 * ridged(xz * 0.01);               // heightfield h(x,z)
}
```

## 2. Mathematics

### 2.1 The base noise octave and the ridge transform

Start from a noise $n(\mathbf p)\in[-1,1]$. The transform
$$
r(\mathbf p)=1-\lvert n(\mathbf p)\rvert
$$
**inverts the noise and folds it**: where the noise is $0$, $r=1$ (a ridge); where the noise is at its extremes ($\pm1$), $r=0$ (a valley). So $r$ has *dense, sharp* ridge lines at the noise's zero-crossings. Because $1-|n|$ has a cusp (non-differentiable) at $n=0$, and we square it ($r^2$) to sharpen the profile, the ridges become **sharp crests** and the valleys become **smooth basins**. 

**Why the absolute value creates ridges.** The absolute value folds the noise's negative region onto the positive region, so the field "mirrors" across the zero level — creating a sharp crease where $|n|$ has a minimum. That crease is the ridge.

### 2.2 The multi-octave (fBm) sum

The ridged field is summed over octaves with the standard fBm parameters (gain 0.5, lacunarity 2):
$$
R(\mathbf x)=\sum_i 0.5^i\,r\big(2^i\mathbf x\big).
$$
Each octave adds a finer set of ridges. The result has high-frequency detail concentrated along ridge lines — exactly mountains with sharp ridgelines and smooth valleys.

**Roughness control.** The gain (0.5) and the ridge sharpening (the square) control the balance between deep valleys and sharp crests. Higher gain → rougher; sharper ridge profile → more extreme peaks.

### 2.3 The terrain heightfield

The height is
$$
h(\mathbf x)=A\,R(k\,\mathbf x),\qquad \mathbf x=(x,z),\quad A=\text{amplitude},\ k=\text{scale}.
$$
This is a **height field** (a graph $y=h(x,z)$), not a distance field. It is rendered like the ocean (Breakdown 10) — but usually with a **hybrid**: a ray from the camera to the bounding sphere/plane of the terrain, then a heightfield march that intersects the ray at the height.

### 2.4 The intersection (heightfield march)

As in Breakdown 10, the ray $\mathbf r(t)=\mathbf o+t\mathbf d$ hits the terrain where
$$
o_y+t\,d_y=h\big((o_x+t d_x,\ o_z+t d_z)\big).
$$
This is solved by the vertical fixed-point update (Section 2.2 of Breakdown 10), or by a more robust slab/binary approach. Because $h$ is a height field (not a distance), we can't use an SDF step; we use the specialization for a graph.

## 3. Field class and normals

| Quantity | Class |
|----------|-------|
| noise octave | arbitrary scalar |
| ridged transform | smooth-ish (cusp at ridges) |
| octave sum | arbitrary scalar field |
| height field $h(x,z)$ | **height field** (not distance) |
| $\nabla h$ | gives the normal via the graph formula |

**The normal.** For a graph $y=h(x,z)$, the surface is parameterized by $(x,h(x,z),z)$, so the normal is
$$
\mathbf n=\frac{(-\partial h/\partial x,\ 1,\ -\partial h/\partial z)}{\sqrt{1+(\partial h/\partial x)^2+(\partial h/\partial z)^2}}.
$$
The partials of $h$ can be computed analytically (from the ridged-noise derivatives, Chapter 17) or by finite differences. The gradient direction gives the surface tilt, and the slope magnitude affects the shading.

## 4. The "thinking process"

1. **Ideas.** "I want mountains with sharp ridges and valleys." → ridged fBm.
2. **Ridge.** "Invert the noise, fold at zero, sharpen." → $1-|n|$, squared.
3. **Detail.** "Multi-scale." → octave sum (gain 0.5, lacunarity 2).
4. **Render.** "It's a height field, not a distance." → heightfield march + graph normal.
5. **Material.** "Snow on peaks, rock, water in valleys." → shade by height and slope.

## 5. Extensions

- **Physically-based scattering.** The ridge/valley shading with a gradient-based "sediment" or "snow" mask by altitude and slope.
- **Bent rock strata.** Warp the noise input with fBm (Chapter 18) before ridging, for bent/eroded strata.
- **Erosion / hydrological carving.** Apply a "carving" pass that lowers the field where the local gradient is steep (a cheap erosion heuristic, Chapter 16).
- **Heightfield + SDF hybrid.** A planet: compute the terrain height as a *distance* from a sphere's surface, so it can be combined with solids.
- **Analytic derivative.** Compute the noise gradient analytically (Chapter 17) for crisp slope-based shading.

## Exercises

1. **(Derivation)** Derive the ridge transform $1-|n|$, explain the cusp at $n=0$, and why squaring sharpens it.
2. **(Derivation)** Derive the graph normal from $h$ and its partial derivatives.
3. **(Field class)** Classify the terrain height field against the Chapter 6 taxonomy and explain why it can't be an SDF step.
4. **(Analytic)** Explain how gain and ridge-sharpening control roughness.
5. **(Design)** Add a snow/rock/water mask based on height and slope.
6. **(Implementation)** Render a ridged-noon terrain with heightfield marching and a graph normal.
