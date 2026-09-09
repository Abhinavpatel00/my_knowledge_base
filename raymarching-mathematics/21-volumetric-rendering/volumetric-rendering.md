# Chapter 21 — Volumetric Rendering

Up to now we rendered *surfaces* (zero level sets). Volumetrics render *participating media* — fog, clouds, smoke, fire, space dust — where light is scattered and absorbed through a **density field**. This chapter derives the mathematics of volume rendering and the "light marching" algorithm.

## 21.1 Density fields vs. distance fields

A **density field** $\rho(\mathbf p)\ge0$ describes the *amount of scattering/absorbing material* at each point. Unlike a distance field, $\rho$ has no metric meaning and is **not** used as a step length directly (it is a scalar field, in the "arbitrary scalar field" row of the taxonomy). However, one can still raymarch a density field by *fixed step sizes* through the volume.

**Key difference.** A surface SDF asks "where is the surface and how far is it?" A density field asks "how much material is here?" The latter has no a-priori "safe step," so volumetric marching uses either a fixed step or a *distance field that bounds the volume* to skip empty space.

## 21.2 The volume-rendering (Beer–Lambert) equation

Along a ray from $\mathbf o$ in direction $\mathbf d$, the **transmittance** at distance $t$ is

$$
T(t)=\exp\!\left(-\sigma_t\int_0^{t}\rho(\mathbf o+s\mathbf d)\,ds\right),
$$

where $\sigma_t$ is the (possibly per-channel) **extinction coefficient**. This is the **Beer–Lambert** law: the amount of light *transmitted* decays exponentially with the accumulated opacity.

**Interpretation.** $\int\rho\,ds$ is the accumulated density (optical depth). If the medium is dense, little light passes through; if thin, most passes. The transmittance $T$ is the fraction of background light that survives to reach the camera.

## 21.3 The radiative transfer / emission equation

The total radiance arriving at the camera along the ray is the integral of *emitted and in-scattered light*, attenuated by the transmittance to the camera:

$$
L=\int_0^{D}\underbrace{T(t)}_{\text{attenuation to camera}}\cdot\underbrace{\big(\sigma_a e(\mathbf r(t))+\sigma_s \,L_i(\mathbf r(t),\mathbf d)\big)}_{\text{emission }+\text{in-scatter}}\,dt,
$$

plus the attenuated background $T(D)L_{\text{bg}}$.

Here:

- $\sigma_a$ = absorption coefficient,
- $\sigma_s$ = scattering coefficient,
- $e$ = emission (glowing medium, e.g. fire/lava),
- $L_i$ = light that scatters *into* the view direction $-\mathbf d$ (in-scatter, from the direct light and other light sources).

**Discrete marching.** Break the ray into $N$ segments of width $\Delta t$ and accumulate:

```
T = 1.0;              // transmittance
L = 0.0;              // accumulated radiance
for t in steps:
    p = ro + rd*t
    rho = density(p)
    if rho > 0:
        // transmittance over the segment
        Tseg = exp(-sigma_t * rho * dt)
        // light reaching this sample (shadowed):
        Li = lightInScatter(p, rd)   // from light marching
        // add emitted + scattered, attenuated by T (to camera)
        Lo = emission(p) + scattering(p) * Li
        L += T * (1 - Tseg) * Lo
        T *= Tseg
    if T < 0.01: break    // fully opaque
L += T * background(ro + rd*D)
```

This is the standard **volumetric ray marching** loop. It accumulates emission + in-scatter, attenuated by the running transmittance.

## 21.4 Light marching

The in-scatter term $L_i$ requires the light reaching the sample point. This is computed by **marching from the sample toward the light** through the *same* density field (a "light march" or "nested" march). The direct light contribution to in-scatter is

$$
L_i(\mathbf p)=L_{\text{light}}\cdot T_{\text{light}}(\mathbf p)\cdot \text{phase}(\theta),
$$

where $T_{\text{light}}(\mathbf p)$ is the transmittance from $\mathbf p$ to the light (shadowing the volumetric medium), and $\text{phase}(\theta)$ is the **scattering phase function** depending on the angle $\theta$ between the light and the view direction.

**Phase functions.** The **Henyey–Greenstein** phase function is standard:

$$
p(\theta)=\frac{1-g^2}{4\pi\,(1+g^2-2g\cos\theta)^{3/2}},
$$

where $g\in(-1,1)$ is the **anisotropy** ($g>0$ forward-scattering, $g<0$ back-scattering, $g=0$ isotropic). This gives the characteristic bright/dark variation seen in volumetrics (e.g. the "glow" toward the sun in a foggy sky).

## 21.5 Fog and distance-based fog

**Distance-based fog** is the simplest volumetric effect: an exponentially-damped blend toward a fog color based on depth.

**Exponential fog.** $T=e^{-\sigma D}$ where $D$ is the depth. The fog color is $L_{\text{bg}}$:

$$
\text{color}=\text{surfaceColor}\cdot T+\text{fogColor}\cdot(1-T).
$$

**Fog with height.** A **height fog** uses a density that depends on height $\rho(y)=\rho_0 e^{-y/H}$ (exponential atmosphere). This gives the classic look where fog gathers in valleys and thins at altitude.

**The key parameter.** $\sigma$ (or $\rho_0$) and the scale height $H$ control the visual density and falloff.

## 21.6 Volume as a surface with soft edges

Many ShaderToy "volumetric" effects are actually a *soft surface* disguised as a volume: a **smoothstep (soft) surface** rendered by marching, then applying fog. Because a soft-surface SDF gives a soft inside/outside value, it can be shaded with a smooth transition — yet this is still a *surface* rendering, not true volume.

**The distinction.** A true volumetric field (density) uses fixed-step or distance-bounded marching and integrates over a thick slab; a soft SDF is a *single level set* with a gradient-blurred edge. Recognize which you are doing: the former requires an integration loop, the latter is one surface evaluation.

## 21.7 Light scattering and the "god rays" look

The "god rays" / "volumetric light shaft" effect comes from a directional light scattering through a medium: samples along the ray that lie in the light's "beam" get a strong in-scatter contribution (via the $L_i$ term and the phase function), creating visible shafts. This is a *quantitative* result of the in-scatter integral: where the light path is clear, $T_{\text{light}}$ is high, so $L_i$ is high, so the medium glows along the beam.

## 21.8 Performance and cost of volumetrics

Volumetric marching multiplies cost: for each pixel, $N_{\text{step}}$ volume samples, and *each sample* may require a nested light march. The cost model (Chapter 25) becomes

$$
\text{cost}\approx\text{pixels}\times N_{\text{step}}\times(N_{\text{light}}\cdot\text{density eval}).
$$

**Optimizations:**

- **Distance-bounded volume skipping.** Store a rough distance field that bounds the volume; step *fast* in empty space (using the distance field) and only do the fine fixed-step integration *inside* the volume. This is the "raymarching + volumetrics hybrid."
- **Reduced-resolution / temporal accumulation.** Compute the volume at a quarter resolution and temporally filter.
- **Limit the light march step count** and use a coarser estimate of transmittance far from the camera.

## 21.9 Summary of field classes in volumetrics

| Quantity | Field class | Used for |
|----------|-------------|----------|
| $\rho(\mathbf p)$ | scalar density | Absorption/scattering amount |
| $T(t)$ | transmittance (not a distance) | Attenuation |
| Volume SDF | could be a bound | Skip empty space |
| Phase function | not a field | Scattering angular distribution |

## Exercises

1. **(Derivation)** Derive the Beer–Lambert transmittance from the differential equation $dT/dt=-\sigma_t\rho T$.
2. **(Derivation)** Write the discrete volumetric accumulation and explain the roles of $T$, $T_{\text{seg}}$, and $L_i$.
3. **(Derivation)** State the Henyey–Greenstein phase function and its behavior for $g>0$, $g<0$, $g=0$.
4. **(Analytic)** Explain why a distance-bounded volume march is faster than a fixed-step march, and what the distance field saves.
5. **(Implementation)** Implement exponential height fog; tune the density and scale height.
6. **(Design)** Build a "god rays" effect and explain mathematically why the light shaft appears.
7. **(Analytic)** Distinguish a true volumetric field from a soft SDF; explain which uses an integration loop.
