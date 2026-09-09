# Shader Breakdown 10 — iq's "Seascape": Heightfield Raymarching of an Ocean

Seascape is Inigo Quilez's canonical ocean shader. It is not an SDF raymarcher of a solid object; it is a **heightfield raymarcher** that casts rays at an animated, procedurally-generated water surface, then shades it with sky reflection, Fresnel, and distance fog. This is a close cousin of the SDF marcher with one crucial difference: the "field" is a heightfield, not a distance.

## 1. The fragment (reconstructed, key parts)

```glsl
// ocean surface height: sum of octaves of a choppy wave field
float sea_octave(vec2 uv, float choppy){
    uv += noise(uv);
    vec2 wv = 1.0 - abs(sin(uv));
    vec2 swv = abs(cos(uv));
    wv = mix(wv, swv, wv);
    return pow(wv, vec2(choppy));
}

float sea_height(vec2 uv){            // the height function h(x,z)
    float h = 0.0;
    uv = uv * SEA_FREQ;
    uv.y += SEA_TIME;                  // scroll
    h += sea_octave(uv, SEA_CHOPPY) ...
    for(i...) { uv *= octave_m; h += ...; }
    return SEA_HEIGHT * h;
}

// raymarch: intersect ray ro+rd*t with the heightfield
float heightMapTracing(vec3 ro, vec3 rd, float t){
    for(int i=0;i<ITER_GEOMETRY;i++){
        float h = sea_height((ro + rd*t).xz);
        t += (ro.y - ... + h) / -rd.y;   // the vertical ray-height update
    }
    return t;
}
```

## 2. Decode into mathematics

### 2.1 The heightfield

The ocean surface is a **heightfield**: a function $h:\mathbb R^2\to\mathbb R$ of the horizontal position $\mathbf x=(x,z)$, giving the surface height $y=h(\mathbf x)$. The surface is the graph
$$
\mathcal S=\{(x,\ h(x,z),\ z)\}.
$$

The height is a sum of octaves of a **choppy wave field**. Each octave is built from `noise` (a value-noise, Chapter 17) phase-warped, then shaped by `1-|sin(u)|` and `|cos(u)|`, combined with `mix(wv,svw,wv)` and raised to `choppy`. The appearance is a family of waves with sharp crests (the `pow(., choppy)` sharpens the peaks) — the "choppy" parameter sets how peaked the waves are.

The octave loop applies a rotation matrix `octave_m` to the UV each octave and adds a scaled height, so the sum is an **anisotropic, rotating multi-octave (FBM-like) field**. This is Fractal Brownian Motion (Chapter 16) with a rotational transform between octaves to avoid alignment artifacts.

### 2.2 Heightfield ray marching

The camera ray is $\mathbf r(t)=\mathbf o+t\mathbf d$. We want the first $t$ where the ray crosses the surface, i.e.
$$
\mathbf r(t)\cdot\mathbf y = h(\mathbf r(t)_{xz}).
$$

This is a *root-finding* problem in $t$. The standard march does a **fixed-point/vertical update**: at the current $t$, compute the surface height $h$ at that point, then move the ray to the height by advancing along the ray by
$$
\Delta t=\frac{h(\mathbf r(t))-o_y}{-d_y}\qquad(\text{for }d_y<0).
$$

**Derivation.** The ray's height at parameter $t$ is $o_y+t d_y$. The surface height at the same horizontal position is $h(\mathbf r(t)_{xz})$. The vertical gap is
$$
\Delta y = h(\mathbf r(t)_{xz})-(o_y+t d_y).
$$
To close the gap by moving along the ray, divide by $d_y$ (the vertical rate):
$$
\Delta t=\frac{\Delta y}{d_y}=\frac{h-(o_y+t d_y)}{d_y}.
$$
Each iteration recomputes $h$ at the new position and re-closes the gap. Because the waves are gentle for most rays, this converges quickly (3 geometry iterations). This is a **fixed-point iteration** on the curve $\mathbf x\mapsto h(\mathbf x)$, and it's the classic "fast heightfield raymarching" trick — cheaper than a full SDF march because each step is one height evaluation.

**Field class.** The heightfield is **not a distance field**. It is a height field (one of the taxonomy rows of Chapter 06: "height field — graph of $z=h(x,y)$ — not a distance field"). So we cannot step by a value and be safe; we use the specialized fixed-point trajectory for the height function. The march is safe *for a valid heightfield* because at each step it re-closes the gap, and it's fast because height evaluation is cheap.

## 3. Shading: sky reflection, Fresnel, fog

### 3.1 The Fresnel term

The water reflects the sky. The reflected color is $\operatorname{skyColor}(\mathbf e_{\text{reflect}})$, with the **Fresnel** weight
$$
F=F_0+(1-F_0)(1-\cos\theta)^5
$$
(Schlick, Chapter 13/15). At grazing angles $\theta\to90^\circ$, $F\to1$ and the water is a mirror of the sky; at normal incidence, $F=F_0$ and the deep water color dominates. This is exactly why the horizon of Seascape glows and the near water is dark blue — the Fresnel term is doing the work.

### 3.2 The deep-water absorption

The water's own color (refracted/absorbed light) fades with depth and the light's path, giving the characteristic teal. This is a heuristic for Beer–Lambert absorption (Chapter 21): the deeper or more opaque the water, the darker the base color.

### 3.3 The sky

The sky color is a gradient based on the ray direction $\mathbf e$: a horizon-to-zenith gradient modulated by the sun direction and a soft "glow" toward the sun. This is a cheap, analytic atmosphere (no light scattering) — a **VISUAL MODELLING** of a sky rather than a physically-based one.

### 3.4 Fog

Distance fog blends toward a horizon color with $e^{-k t}$ style decay, where $k$ is tuned so the horizon melts into the sky. This is the exponential fog of Chapter 21.

## 4. The "thinking process"

1. **Ideas.** "I want a vast, realistic ocean." → a heightfield, not a solid.
2. **Waves.** "Real waves are choppy and multi-scale." → sum octaves, cheat the wave shape with `1-|sin|`+`|cos|`+`mix`, sharpen with `pow(.,choppy)`, rotate UV between octaves.
3. **Ray-surface.** "How do I find where the ray hits the water?" → the vertical fixed-point update, since a heightfield is exactly a graph.
4. **Look.** "It must reflect the sky and glow at the horizon." → Fresnel (Schlick) + sky gradient.
5. **Depth.** "The water should fade into distance." → exponential fog.

## 5. Extensions

- **Analytic normals.** Compute $\nabla h$ analytically from the wave sum (via the noise derivatives, Chapter 17) instead of finite differences, for crisp specular.
- **Gerstner waves.** Replace the FBM height with a genuine Gerstner sum (horizontal displacement + vertical), which gives *slant and curl* to the crests — this is the "spectral ocean" look and is what makes long swells travel faster than short chop.
- **Subsurface/absorption.** Add a real Beer–Lambert term along the refracted path.
- **Volumetric mist.** Add light-scattering mist (Chapter 21), the "god-ray" look over the water.
- **Convert to an SDF.** If you want to combine this ocean with solid SDF objects, you'd need a *distance to a heightfield* (a bound), then use a hybrid marcher. This is the axis where Seascape's technique and SDF raymarching meet.

## Exercises

1. **(Derivation)** Derive the heightfield ray-march update $\Delta t=(h-(o_y+t d_y))/d_y$ and state when it converges.
2. **(Field class)** Classify a heightfield against the Chapter 06 taxonomy and explain why it cannot be used as an SDF step.
3. **(Derivation)** Expand the choppy-wave octave and derive its analytic gradient.
4. **(Derivation)** Write the Schlick Fresnel term and explain the horizon glow.
5. **(Analytic)** Explain the role of the rotation `octave_m` between octaves (avoiding axis-aligned artifacts).
6. **(Design)** Replace the FBM height with Gerstner waves; describe the mathematical difference.
