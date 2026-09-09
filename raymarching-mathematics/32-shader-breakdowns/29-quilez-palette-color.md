# Shader Breakdown 29 — iq's Smooth Color Palette (cosine palette)

The "cosine palette" is iq's famous one-liner for procedurally generating smooth, appealing gradients: a sum of cosines with controllable hue/luminance. It is the bridge between a mathematical *field* and a *color*, and it's why so many procedural shaders get beautiful, designer-like gradients with almost no code. This breakdown derives it and analyzes it as a color map.

## 1. The fragment

```glsl
vec3 palette( float t ){
    vec3 a = vec3(0.5, 0.5, 0.5);   // offset
    vec3 b = vec3(0.5, 0.5, 0.5);   // amplitude
    vec3 c = vec3(1.0, 1.0, 1.0);   // frequency
    vec3 d = vec3(0.00, 0.33, 0.67);// phase
    return a + b * cos( 2.0 * 3.14159 * (c * t + d) );
}
```

## 2. Mathematics

### 2.1 The color map as a vector cosine function

The palette is
$$
\operatorname{pal}(t)=\mathbf a+\mathbf b\odot\cos\!\big(2\pi(\mathbf c\,t+\mathbf d)\big),
$$
where $\odot$ is component-wise multiplication, and $t\in\mathbb R$ is the scalar "color coordinate" (position, distance, time, or an iteration count). Each channel is a cosine with its own offset/amplitude/frequency/phase. So it's a **component-wise periodic function of $t$**, with the three channels phase-shifted relative to one another so that they cycle through colors.

### 2.2 The role of each parameter

- **$\mathbf a$ (offset):** the vertical center of the waveform. $\mathbf a=(0.5,0.5,0.5)$ gives waveforms centered at 0.5 (in $[0,1]$ after the cosine).
- **$\mathbf b$ (amplitude):** the vertical range. $\mathbf b=(0.5,0.5,0.5)$ gives $[0,1]$ range. Increasing $\mathbf b$ makes more saturated/bright colors; decreasing dims the whole palette.
- **$\mathbf c$ (frequency):** how fast the color cycles per unit $t$. With $\mathbf c=(1,1,1)$, one full cycle per unit $t$. Different $\mathbf c$ per channel make the color *not* cycle together — e.g. $\mathbf c=(1,1,1)$ gives a clean cyclic rainbow; $\mathbf c$ that differ give more "unpredictable" transitions.
- **$\mathbf d$ (phase):** the per-channel phase offset. The famous $\mathbf d=(0,0.33,0.67)$ splits the three channels by a third of a cycle each, so the palette cycles through red/green/blue in sequence — the classic rainbow/sunset gradient.

### 2.3 Why this is a "smooth gradient generator"

Because each channel is a cosine of $t$, the palette is **$\mathcal C^\infty$** and **periodic** in $t$. So as you vary $t$ smoothly, the color varies smoothly (no banding, no seams, no hard transitions). It's the perfect color map to plug into a smoothly-varying field like an fBm, a distance, or an iteration count. The "design" is entirely in the four vectors.

**Relation to the phase.** The phase difference $\Delta d_{ij}=d_i-d_j$ between channels determines the color *hue* ordering. $\mathbf d=(0,1/3,2/3)$ is the classic (channels split by 1/3 cycle) — the rainbow. Changing the phase shifts the hue; changing the frequency ratio changes how "fast" each color family cycles.

## 3. Where it's used

- **Mapping a field to color.** A scalar field $t$ (e.g. distance, fBm altitude, iteration count) mapped via `palette(t)`.
- **Polychrome abstract art.** The palette converts a smooth field into a striking gradient.
- **Procedural material color.** Colorize a surface by a coordinate or a noise value.

## 4. The "thinking process"

1. **Ideas.** "I want a smooth, attractive gradient, no hand-tuned ramp." → a parametric cosine palette.
2. **Math.** "A per-channel cosine with phase offsets." → $\mathbf a+\mathbf b\cos(2\pi(\mathbf c t+\mathbf d))$.
3. **Tune.** "Set the offset/amplitude/frequency/phase to get the hue." → four vectors.
4. **Map.** "Feed it a smooth field value $t$." → color = palette(t).

## 5. Extensions

- **Vary the frequency per channel.** $\mathbf c=(1,1,1)$ is the clean rainbow; $\mathbf c=(1,2,4)$ makes the color cycle at different rates per channel, giving more "complex" palettes.
- **Non-linear $t$.** Apply a function to $t$ first (e.g. `t = 0.5+0.5*sin(...)`) to concentrate the color transitions in certain ranges.
- **Tri-quadratic / HSV.** Other color maps; the cosine palette is just one (very cheap and pleasant) family.
- **Wrap $t$.** Because the palette is periodic, you can loop it seamlessly for time-varying color (Chapter 22).

## Exercises

1. **(Derivation)** Write the palette as a component-wise function and expand a channel.
2. **(Derivation)** Derive the waveform $[a-b,a+b]$; explain how $\mathbf a,\mathbf b$ set the range.
3. **(Analytic)** Explain how the phase $\mathbf d=(0,1/3,2/3)$ produces the rainbow, and how changing it shifts the hue.
4. **(Derivation)** Explain how differing channel frequencies ($\mathbf c$) change the palette's "complexity."
5. **(Design)** Map a distance or fBm field to color with the palette; describe the result.
6. **(Implementation)** Implement the palette and apply it to a procedural field.
