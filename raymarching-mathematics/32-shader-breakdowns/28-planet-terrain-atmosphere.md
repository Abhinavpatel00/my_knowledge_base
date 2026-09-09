# Shader Breakdown 28 — Planet, Terrain, and Atmosphere

The "procedural planet" is a raymarched scene that combines a **sphere + displaced terrain** (the ground), an **analytic atmosphere** (a volumetric gradient around the sphere), a **sun**, and **sky**. It is a synthesis of everything: an SDF (the planet), a displacement (terrain), a height field (the surface detail), and a volumetric atmosphere.

## 1. The fragment (reconstructed key parts)

```glsl
float terrain(vec3 p){ return fbm(p); }

float map(vec3 p){
    float r = length(p);
    return r - planRad - terrain(p)*...;   // a sphere displaced by fBm (planet surface)
}

// analytic atmosphere (optical depth along the ray through a shell)
vec3 atmosphere(vec3 ro, vec3 rd){
    ... integrate exp(-...) along the ray inside the atmosphere shell ...
}
```

## 2. Mathematics

### 2.1 The planet SDF + terrain displacement

The planet is a sphere of radius $R$, displaced by terrain:
$$
d(\mathbf p)=\lVert\mathbf p\rVert-R-D\,\operatorname{fbm}\big(\hat{\mathbf p}\,s\big),
$$
where $\hat{\mathbf p}=\mathbf p/\lVert\mathbf p\rVert$ is the unit direction, $s$ is the terrain frequency on the sphere, and $D$ the amplitude. The displacement scales with the sphere (to keep the terrain "on the planet").

**Field class.** The sphere part is exact. The fBM displacement makes it a **bound** (Chapter 16): the displacement is a scalar added to the SDF, so it shifts the surface by an amount up to $D$. If $D$ is small relative to $R$, the march is safe (bound); if large, it's an estimator.

### 2.2 The analytic atmosphere

An atmosphere is a *volumetric* shell around the planet with a density that falls off exponentially with height:
$$
\rho(h)=\rho_0\,e^{-h/H}
$$
($H$ = scale height). Light passing through this shell is scattered and absorbed (Chapter 21). The **key analytic quantity** is the **optical depth** along the ray through the shell — the integral of $\rho$ over the ray:
$$
\tau(\mathbf r)=\int \rho(\mathbf r(t))\,dt .
$$
For an exponential atmosphere in a spherical shell, this integral can be evaluated **analytically** (as a function of the entry/exit points and the density's exponential falloff), which is why the atmosphere is cheap. The color is then
$$
L_{\text{atm}}=\text{in-scatter}+\text{absorption},
$$
with an **in-scatter** term that peaks toward the sun (a forward-scattering phase function, Chapter 21) and a **transmittance** $e^{-\tau}$ that dims the background.

**The physics.** The blue sky is Rayleigh scattering (short wavelengths scattered more); the red sunsets are the *absence* of short wavelengths because the path through the atmosphere is long at the horizon (more $\tau$ for blue, so blue is scattered/absorbed and red survives). A shader captures this with a wavelength-dependent scattering coefficient.

### 2.3 The sun and the horizon glow

A sun disc is a sharp dot/gradient in the sky (the analytic atmosphere gives it a forward-scattered glow). The horizon glows because the optical depth $\tau$ is largest there (longest path through the shell), so the sky color peaks at the horizon.

## 3. The "thinking process"

1. **Ideas.** "I want a planet with terrain and an atmosphere." → sphere + displaced terrain + volumetric atmosphere.
2. **Planet.** "A sphere, displaced by noise for terrain." → $d=\lVert p\rVert-R-D\,\text{fbm}$.
3. **Atmosphere.** "A thin shell with exponential density." → $\rho_0 e^{-h/H}$; integrate the ray for optical depth.
4. **Sun.** "A bright light with forward scattering." → phase function + sun disc.
5. **Field class.** "The terrain displacement makes it a bound." → small $D$ keeps it safe.

## 4. Field class

| Quantity | Class |
|----------|-------|
| sphere SDF | exact |
| terrain displacement | bound (Chapter 16), small $D$ safe |
| atmosphere density | volume (arbitrary scalar) |
| optical depth | analytic integral |

## 5. Extensions

- **Rayleigh + Mie.** Split the scattering into Rayleigh (small particles, blue sky) and Mie (large particles, haze/glow) for realism.
- **Time-of-day.** Rotate the sun direction; the atmosphere colors (sunset vs. noon) emerge from the wavelength-dependent optical depth.
- **Clouds.** A volumetric cloud layer (Breakdown 21) in the troposphere, with the planet terrain below.
- **Water.** A heightfield ocean (Breakdown 10) at sea level, with Fresnel reflection of the sky.
- **Space.** Beyond the atmosphere, background stars + a black sky.

## Exercises

1. **(Derivation)** Derive the planet SDF + terrain displacement and class it as a bound.
2. **(Derivation)** Write the exponential atmosphere density and the optical-depth integral.
3. **(Analytic)** Explain why the horizon is red (longer $\tau$ for blue at grazing angles).
4. **(Derivation)** Derive the in-scatter/forward-scattering term toward the sun.
5. **(Design)** Add a cloud layer; describe the volumetric integration.
6. **(Implementation)** Render a planet with terrain and an analytic atmosphere.
