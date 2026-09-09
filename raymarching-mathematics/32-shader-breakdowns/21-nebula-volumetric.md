# Shader Breakdown 21 — Nebula / Space Clouds (Volumetric fBm)

Nebula and space-cloud shaders are the natural domain of **volumetric ray marching** (Chapter 21): a density field of fBm, integrated along the ray with light scattering and tone-mapping. This is a *true volume* (not a surface), so the technique is the fixed-step integral of Chapter 21.

## 1. The fragment (reconstructed key parts)

```glsl
float density(vec3 p){
    // a domain-warped, ridged/warped fBm cloud density
    vec3 q = p; q += 0.5 * fbm(p);        // domain warp
    return smoothstep(threshold, 0.0, fbm(q) + ...);   // threshold to a soft cloud
}

void mainImage(...){
    ...
    for(int i=0;i<STEPS;i++){
        vec3 p = ro + rd*t;
        float d = density(p);
        if(d > 0.0){
            float lt = transm(p, l);                     // light transmission to the sun
            vec3 emit = ...  (self-emission / in-scatter);
            col += T * d * emit * dt;                    // accumulate
            T *= exp(-sigma * d * dt);                   // Beer-Lambert
        }
        t += dt;                                         // fixed step
    }
    col = toneMap(col);
}
```

## 2. Mathematics

### 2.1 The density field

The cloud density is a scalar field $\rho(\mathbf p)\ge0$, typically a **domain-warped fBm**:
$$
\rho(\mathbf p)=\operatorname{smoothstep}\!\big(T_0,\ 0,\ \sigma(\mathbf p)\big),\qquad
\sigma(\mathbf p)=\operatorname{fbm}\!\big(\mathbf p+\lambda\mathbf W(\mathbf p)\big).
$$
The `smoothstep` thresholds the fBm to a soft cloud: value $>0$ inside the cloud, $0$ outside. The domain warp ($\mathbf W$) makes the cloud turbulent (Breakdown 18). Because this is a **density field** (arbitrary scalar), it is rendered with **fixed steps**, not a distance step.

### 2.2 The volumetric integration

The renderer integrates the radiative-transfer equation (Chapter 21). In its simplest form:

**Emission/self-light.** `emit` is the cloud's own glow (often a color modulated by the density and a palette). The accumulation is
$$
L=\sum_i T_i\,\rho_i\,\text{emit}_i\,\Delta t .
$$

**Absorption (Beer–Lambert).** The transmittance accumulates as
$$
T_{i+1}=T_i\,e^{-\sigma_t\,\rho_i\,\Delta t}\approx T_i\,(1-\sigma_t\,\rho_i\,\Delta t).
$$
So the cloud becomes opaque as $\int\rho\,dt$ grows. This is what makes a thick cloud core dense and a thin edge translucent.

**In-scatter / light transmission.** For a sun-scattering look, compute how much light reaches the sample (a nested light march — the "transm" to the light). The in-scatter term adds the glow toward the sun. This is the "god-ray" of a nebula.

### 2.3 The tone-map and the "right look"

The accumulated $L$ can be large; a filmic tone-map (Chapter 9 of this series, or `col = col/(col+k)` or `1-exp(-x)`) compresses it. The final color is the characteristic "one-shot" volumetric nebula look.

## 3. Field class

| Quantity | Class |
|----------|-------|
| $\rho=\text{smoothstep}(\text{fbm warp})$ | **density field** (arbitrary scalar) |
| $T$ transmittance | not a distance |
| $L$ accumulated radiance | not a distance |

The nebula is a **true volumetric** render — no SDF, no distance step. The only "field" is a density, and we march it with fixed steps. This is the correct way to think about it; it is not "an SDF that happens to be soft," it is a volume.

## 4. The "thinking process"

1. **Ideas.** "I want space clouds / a nebula." → a volumetric density field.
2. **Shape.** "Clouds are turbulent." → a domain-warped fBm, thresholded.
3. **Render.** "It's a volume, integrate along the ray." → fixed-step march, accumulate emission and absorption.
4. **Light.** "Glow toward the sun." → a nested light-transmission march.
5. **Tone.** "Make it filmic." → a tone-map.

## 5. Extensions

- **6- or 8-octave fBm for fine detail** (more octaves, more cost).
- **Peano/ridged clouds.** Use `1-|noise|` for wispy edges, or a higher warp for tendrils.
- **Blue-noise dithering.** Jitter the step offset per pixel to reduce banding (Chapter 24), and use a low number of steps + temporal accumulation.
- **Physically-based self-shading.** Add a real Henyey–Greenstein phase function (Chapter 21) for forward-scattering glow.
- **Cluster/tendril clouds.** Use a Voronoi distance as an input to the warp, so clouds form along cell interiors.

## Exercises

1. **(Derivation)** Write the fixed-step volumetric integral and the Beer–Lambert transmittance.
2. **(Field class)** Classify the density field and explain why fixed steps (not a distance) are used.
3. **(Derivation)** Derive the light-transmission (in-scatter) term for a single sun.
4. **(Analytic)** Explain why the cloud becomes opaque as $\int\rho\,dt$ grows.
5. **(Design)** Add a domain warp for turbulent clouds; describe the visual change.
6. **(Implementation)** Render a nebula with a nested light march and tone-map.
