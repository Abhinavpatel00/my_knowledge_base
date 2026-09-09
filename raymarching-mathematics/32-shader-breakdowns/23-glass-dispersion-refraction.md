# Shader Breakdown 23 — Glass, Dispersion, and Refraction (with internal rays)

Glass/water refraction (Chapter 15) is one of the most beautiful and most mathematically demanding raymarching effects. This breakdown covers the *path* through a glass object: entry refraction, internal path, exit refraction, Fresnel energy balance, and **chromatic dispersion** (splitting by wavelength).

## 1. The fragment (reconstructed key parts)

```glsl
vec3 glassMarch(vec3 ro, vec3 rd, float eta){   // eta = n_glass/n_air
    float t = raymarch(ro, rd);                  // hit the outer surface
    vec3 p = ro + rd*t;
    vec3 n = normal(p);
    if(dot(rd, n) > 0.0) n = -n;                 // face inward if needed
    // entry
    vec3 rd2 = refract(rd, n, 1.0/eta);
    if(length(rd2) < 0.0001) rd2 = reflect(rd, n);  // TIR
    // march through the interior
    float t2 = raymarch(p, rd2);
    vec3 p2 = p + rd2*t2;
    vec3 n2 = normal(p2);
    // exit
    vec3 rd3 = refract(rd2, -n2, eta);
    ...
    // Beer-Lambert absorption of the interior path (length = t2)
    vec3 tint = exp(-vec3(1.0, 2.0, 3.0) * sigma * t2);
    // trace the exit ray to the environment
    vec3 bg = raymarchEnvironment(p2, rd3);
    return tint * bg;
}
```

## 2. Mathematics

### 2.1 Entry and exit refraction (Snell)

The refraction vector from Chapter 15:
$$
\mathbf t=\mu\mathbf d+\big(\mu(-\mathbf d\cdot\mathbf n)-\sqrt{1-\mu^2(1-(\mathbf d\cdot\mathbf n)^2)}\big)\mathbf n,\qquad \mu=\frac{\eta_i}{\eta_t}.
$$
For a ray entering glass from air, $\mu=1/\eta$, and the ray bends toward the normal. At the exit surface (glass→air), $\mu=\eta$, and the ray bends away; if the angle is past the critical angle, **total internal reflection (TIR)** occurs and we switch to `reflect`.

### 2.2 The interior path and Beer–Lambert absorption

The ray travels a distance $t_2$ through the glass. The transmitted light is attenuated by **Beer–Lambert** (Chapter 21):
$$
L_{\text{transmitted}}=L_{\text{bg}}\,e^{-\sigma_t\,t_2}\,.
$$
For *chromatic* absorption, $\sigma_t$ depends on wavelength:
$$
\text{tint}=e^{-\boldsymbol\sigma \,t_2},\qquad \boldsymbol\sigma=(\sigma_R,\sigma_G,\sigma_B).
$$
So the glass tints the transmitted light by the *path length* through it. A thicker or denser path gives a stronger, more saturated tint — this is why thick glass looks green/blue at the edges (color accumulates with path length).

### 2.3 Fresnel energy balance

At each surface, the fraction reflected vs. refracted is governed by Fresnel (Chapter 13/15). The Schlick approximation:
$$
F(\theta)=F_0+(1-F_0)(1-\cos\theta)^5,\qquad F_0=\Big(\frac{1-\eta}{1+\eta}\Big)^2 .
$$
The total output is
$$
\text{col}=F\,\text{reflection}+(1-F)\,\text{tint}\cdot\text{refracted-environment},
$$
so grazing angles are mostly reflective and normal incidence is mostly transmissive. This is what gives glass its characteristic "bright rim" (Fresnel) plus its see-through center.

### 2.4 Chromatic dispersion

Dispersion arises because the refractive index depends on wavelength: $\eta(\lambda)$. The shader traces 3 rays with slightly different $\eta$ for R, G, B:
$$
\text{col}_R=\text{trace}(\eta_R),\ \text{col}_G=\text{trace}(\eta_G),\ \text{col}_B=\text{trace}(\eta_B).
$$
Because different wavelengths bend by different amounts, the image splits into colored fringes — the prism/glass dispersion effect. The split is small (the indices differ by a few percent), which is why the fringe is subtle.

## 3. The thinking process

1. **Ideas.** "I want a realistic glass/water object." → refraction, absorption, Fresnel.
2. **Path.** "Refract in, traverse, refract out." → two Snell steps + interior march.
3. **Absorb.** "Thicker path = more tint." → Beer–Lambert along the interior length.
4. **Balance.** "Some light reflects, some refracts." → Fresnel (Schlick).
5. **Dispersion.** "Different colors bend differently." → trace R/G/B with different $\eta$.

## 4. Field class

| Quantity | Class |
|----------|-------|
| surface SDF | exact/bound |
| refraction vector | analytic (Chapter 15) |
| interior march | distance march |
| Beer–Lambert tint | physically-based attenuation |
| Fresnel | analytic approximation |
| dispersion | 3 rays with different $\eta$ |

## 5. Extensions

- **Caustics.** Estimate the focused light *inside* the glass by accumulating the "concentration" of refracted rays; a classic fake is to brighten where many refracted rays converge.
- **Internal reflections.** Trace one bounce *inside* the glass (TIR or Fresnel) for a more realistic thick-glass look.
- **Frost / roughness.** Add a small jitter to the refracted direction (a random perturbation) for frosted glass.
- **Graded-index.** Vary $\eta$ with height (water with a temperature gradient).
- **Two refracting surfaces** (a lens). Refract in, traverse, refract out — the lens effect.

## Exercises

1. **(Derivation)** Write the entry and exit refraction vectors (Snell) and state the TIR condition.
2. **(Derivation)** Write the Beer–Lambert tint and explain how the path length $t_2$ drives it.
3. **(Derivation)** Write the Schlick Fresnel and the energy balance.
4. **(Derivation)** Explain dispersion by tracing R/G/B with different $\eta$.
5. **(Analytic)** Explain why thick glass is more saturated at the edges (longer path).
6. **(Implementation)** Render a refracting sphere with absorption and Fresnel.
