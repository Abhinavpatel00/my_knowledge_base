# Shader Breakdown 12 — Menger Sponge: A KIFS via Cross-Folding

The Menger sponge is the canonical 3D fractal and the cleanest illustration of the **KIFS** (Chapter 11/6) structure: fold, repeat, scale, and *subtract* an inner carving. We break down `fb39ca4`'s famous construction (`WtfXzj`), which builds the sponge from a single `sdCross` primitive, repeated and scaled, taken as a difference.

## 1. The fragment (reconstructed key parts)

```glsl
float sdCross(vec3 p){
    p = abs(p);
    vec3 d = vec3(max(p.x,p.y), max(p.y,p.z), max(p.z,p.x));
    return min(d.x, min(d.y,d.z)) - 1.0/3.0;
}

float sdCrossRep(vec3 p){
    vec3 q = mod(p + 1.0, 2.0) - 1.0;
    return sdCross(q);
}

float sdCrossRepScale(vec3 p, float s){
    return sdCrossRep(p * s) / s;
}

float sdScene(vec3 p){
    float s = 1.0, d = 0.0;
    for(int i=0;i<5;i++){
        d = max(d, -sdCrossRepScale(p, s));   // subtract the cross
        s *= 3.0;
    }
    return d;
}
```

## 2. Mathematics

### 2.1 `sdCross` — the "infinite cross" primitive

The Menger sponge is a **cube with a lattice of holes** carved through it. The hole-carving primitive is the **infinite cross**: the set of points *away from* the three axial "plus" curves. Specifically, for a point with `abs(p)`, the quantities
$$
\delta_1=\max(p_x,p_y),\qquad \delta_2=\max(p_y,p_z),\qquad \delta_3=\max(p_z,p_x)
$$
measure, along each pair of axes, how far the point is from the axis line... Taking the **min** of these three, then subtracting $1/3$, gives

$$
d_{\text{cross}}(\mathbf p)=\min(\delta_1,\delta_2,\delta_3)-\frac13 .
$$

**Interpretation.** The infinite cross is the *complement of the three axial "slabs"* — it's a set of three mutually-perpendicular infinite "plates" along the coordinate planes. The `abs(p)` folds the octants (a reflection, isometry), and the `min`/`max` encodes the box-style distance to the three plates. The value is an **exact SDF** of the cross (it is a box-like half-space construction, $C^0$ at edges).

### 2.2 Repetition + scaling (the KIFS engine)

`sdCrossRepScale(p, s) = sdCrossRep(p*s)/s`:

- `p*s` **scales** space by $s$ (a uniform scale, exact-SDF-preserving — Chapter 10).
- `sdCrossRep` **repeats** the cross into a lattice with `mod` (centered repetition, exact along each axis — Chapter 11).
- Dividing by $s$ **rescales** the distance, so the repetitive cross has the right metric relative to the outer cube.

The loop then **unions** ($d=\max$) the *negative* of each rescaled cross:
$$
d_{\text{Menger}}=\max_{i}\Big(-\operatorname{sdCrossRepScale}(\mathbf p,\ 3^i)\Big).
$$
The `max` of `-cross` is the **difference** (Chapter 9): it subtracts each finer cross from the accumulating solid. Each level multiplies the scale by 3, so the holes get finer by a factor of 3 (the sponge's self-similarity ratio 1/3).

### 2.3 Why this produces the sponge

At scale $s=1$ we subtract the coarsest cross (the largest holes). At $s=3$ we subtract a finer cross (smaller holes), and so on. The result is the recursive removal of the cross-shaped "tunnels" at each of the 3×-finer scales — precisely the self-similar structure of the Menger sponge. The recursion depth (5 iterations) sets the finest level of holes; more iterations = finer detail.

### 2.4 The distance bound and rescale factor

Because the carries in `sdCrossRepScale` divide by $s$, each level's contribution is correctly scaled. The final $d$ (a `max` of exact SDFs) is itself an **exact SDF** of the sponge *if* the recursion were infinite. With a finite 5-level truncation, it's a *bound* on the true (infinite) sponge — but a good one, because the fine structure is sub-pixel.

**Key point.** In contrast to the "scale without rescale" pitfall (Breakdown 6), the `/s` here *rescales* correctly, so the field is a proper distance bound and the actual sponge surface is not overestimated. This is the crucial correctness detail that makes this sponge render cleanly.

## 3. Field-class analysis

| Stage | Operation | Isometry? | Field class |
|-------|-----------|-----------|-------------|
| `abs(p)` | reflection | yes | exact |
| `mod` | centered repetition | yes (per cell) | exact |
| `max`/`min` | half-space booleans | — | exact |
| `p*s` then `/s` | uniform scale + rescale | yes | exact |
| `max` of $-cross$ | difference | — | exact |

So `sdScene` is an **exact SDF for the truncated sponge**, one of the cleanest fractal constructions. Unlike the Mandelbulb (which is a DE *estimate*), the Menger sponge — because it's built entirely from folding/repetition/exact primitives — admits an **exact SDF**.

## 4. The thinking process

1. **Ideas.** "I want the Menger sponge." → it's a cube with self-similar cross holes.
2. **Hole primitive.** "What's the single carve that repeats?" → the infinite cross `sdCross`.
3. **Self-similarity.** "Repeat it at scales 3-fold apart." → `scale`, `repeat`, and `÷s`.
4. **Carve.** "Remove each scale." → `max(d, -cross)` (difference).
5. **Safety.** "Rescale each level or the field overestimates." → the `/s`.

The Menger sponge is the best example of the general rule: **a fractal built entirely from isometries + exact primitives + difference is an exact SDF, while a fractal built from a nonlinear iteration (Mandelbulb) is only a DE estimate.** That distinction (Chapter 20) is the whole lesson.

## 5. Extensions

- **Recursive depth / finer detail.** Increase the loop iterations; but each level adds a `mod`+`max`, so it's more expensive. The fineness is limited by the marcher's epsilon.
- **Rotating the frame.** Rotate $\mathbf p$ before `sdScene` (an isometry) to spin the sponge.
- **Rounded sponge.** Replace the exact `-cross` with a smooth-max (Chapter 9) for a "melted" sponge — but then the field becomes a bound.
- **Other fractals via the same engine.** The same `sdCross`(s) KIFS pattern builds the **"Apollonian"** and other self-similar fractals; only the primitive and the subtraction differ.
- **Volumetric density.** Use the amount "inside" (how negative $d$ is) as a density for a volumetric look, or carry the SDF into a voxel/3D-texture bake for faster rendering.

## Exercises

1. **(Derivation)** Derive `sdCross` from the box-distance construction and verify it's an exact SDF.
2. **(Derivation)** Show that `p*s` then `/s` preserves the distance, and why omitting `/s` overestimates.
3. **(Field class)** Classify the truncated Menger sponge and explain why it's exact (vs. a Mandelbulb's DE).
4. **(Analytic)** Explain the self-similarity ratio (1/3) and how the recursion depth sets the finest detail.
5. **(Design)** Build a "rounded" or "melted" Menger sponge with a smooth max; describe the field-class change.
6. **(Implementation)** Compute the analytic normal and add lighting/AO to the sponge.
