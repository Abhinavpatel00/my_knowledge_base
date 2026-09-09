# Chapter 24 — Numerical Analysis

A mathematically elegant formula can still produce an ugly or wrong image. The gap between the ideal real-valued mathematics and the actual GPU computation is the subject of numerical analysis. This chapter explains where that gap is, why it matters, and how to manage it.

## 24.1 Floating-point representation

A float (IEEE-754 single precision) is

$$
\pm\;1.m\times 2^{e-127},
$$

i.e. a sign, a mantissa (24 bits of precision, one implicit) and an 8-bit exponent. In a shader, `float` is typically 32-bit (about 7 decimal digits of precision); `half` (mediump) is 16-bit (about 3 digits); some GPUs use more.

**The key number: machine epsilon.** For single precision, $\epsilon_{\text{mach}}=2^{-23}\approx1.19\times10^{-7}$. This is the smallest relative difference between two distinct floats near $1.0$. All our $\varepsilon$ choices (for normals, marching tolerance) must be comfortably above this.

## 24.2 Catastrophic cancellation

When two nearly-equal numbers are subtracted, the leading digits cancel and the *relative* error explodes:

$$
a-b\quad\text{with } a\approx b.
$$

Even if $a$ and $b$ are each accurate to $10^{-7}$ relative, their difference may be accurate to only $1$ significant digit (or less). This is **catastrophic cancellation**.

**Where it bites in raymarching.** The box SDF subtracts `abs(p)-b`; near a face where `abs(p)≈b`, the result is a small difference of large quantities. The torus $d=\sqrt{(\sqrt{x^2+y^2}-R)^2+z^2}-r$ has a similar issue near the inner radius. And the marching tolerance $\varepsilon$ compared to a tiny `d` value is exactly a cancellation-prone comparison.

**Mitigation.** Avoid subtracting nearly-equal magnitudes; reformulate the equation. For the box, use a formulation that avoids the cancellation (the standard box SDF is already robust). For the reach of values, shift coordinates to be near the relevant origin (re-center).

## 24.3 The epsilon selection

The marching $\varepsilon$ is a trade-off: too large → chunky; too small → the field's numerical noise (float error) becomes comparable to $\varepsilon$, so the marcher can't cleanly decide a hit. The optimal $\varepsilon$ is related to the local scale.

**The "adaptive" epsilon.** Many marchers use $\varepsilon(t)=\varepsilon_0(1+k t)$, because far-away surface detail is sub-pixel anyway and precision degrades with distance (large $t$), so the tolerance should grow. This is a heuristic, and it reduces cost while staying visually clean.

## 24.4 Error accumulation along a ray

The march accumulates position error. After $t$ steps, the point $\mathbf p=\mathbf o+t\mathbf d$ is computed with an absolute error roughly

$$
\text{error}\sim\epsilon_{\text{mach}}\cdot\lVert\mathbf o+t\mathbf d\rVert.
$$

For large $t$ (far from the camera), this error can exceed the marching tolerance $\varepsilon$, so the marcher decides "hit" or "miss" based on noise. This is why deep scenes (infinite corridors) are the worst case.

**Mitigation.** Re-center coordinates: march in a local frame where the relevant distances are small, or pass a "time offset" so the scene is evaluated near the origin, or use a relative epsilon.

## 24.5 Stability and convergence

**Convergence of sphere tracing.** The iteration $t_{n+1}=t_n+d(t_n)$ converges because $t_n$ is monotone and bounded above, *if* the field is a true lower bound. But a field that *overestimates* distance (a bad estimator) can cause $t_{n+1}$ to jump past the root, and then the marcher is on the wrong side: the sequence can oscillate or converge to the wrong (later) root — **overshoot/tunneling**. This is the numerical manifestation of the estimator-vs-bound distinction (Chapters 06, 20).

## 24.6 Underflow and overflow

- **Underflow** to denormal/zero: very small field values become $0$, so a far-away marcher sees "hit at every point" (or zero steps). Use a small clamp or a relative epsilon.
- **Overflow to infinity:** very large field values (e.g. `pow` of a large base, or a distance to a huge scene) overflow to `inf`, causing `NaN` in normalization. Mitigate with clamping, safe scaling, and `max(x, tiny)` guards (e.g. the `1e-6` in the Mandelbulb DE).

## 24.7 Branch discontinuity

A branch (an `if`, a `sign`, a `floor`, a `max`/`min` pick, a `mod` wrap, an `abs` fold) can be **discontinuous** in its output at the branch boundary. When this boundary is hit by the marcher (e.g. a `mod` wrap point, a fold), the field value changes discontinuously. This is:

- **A real geometric feature** (the crease in a union, the cell boundary in a repetition) — fine, it's geometry.
- **A numerical problem** if the discontinuity causes the marcher to step across it and miss a thin feature, or to generate a "seam."

**Managing branch discontinuities.** For *smooth* geometry, use smooth blends (smooth union, smoothstep) to avoid sharp branches. For *repetition* where a seam is unavoidable, ensure the `mod` centering keeps the seam away from where the marcher crosses it, or accept the seam as a feature.

## 24.8 Derivative noise (normals)

The finite-difference normal (Chapter 12) is a *numerical derivative*. Its error depends on $\varepsilon$:

$$
\text{error}\sim\frac{\text{field noise}}{\varepsilon}+\varepsilon\cdot\text{curvature}.
$$

- Small $\varepsilon$ → the numerator difference is dominated by float noise → normal is garbage (noisy sparkle).
- Large $\varepsilon$ → the difference averages over genuine curvature → normal is blurred.

**The optimum.** Because the two errors trade off, there is an optimal $\varepsilon$ around $\sqrt{\epsilon_{\text{mach}}}$ (for field noise) but in practice it's tuned visually. This is why a "good-looking" constant $\varepsilon$ in a shader is a carefully chosen value, and why naively using a tiny epsilon makes the normals sparkle.

## 24.9 Banding

**Banding** is the appearance of discrete "bands" or rings in a field, especially in gradients and in smooth transitions (soft shadows, AO, fog, and fractal iteration counts). It comes from *quantization*: a continuous quantity is evaluated to a limited precision, so the discretization shows up as steps.

- **Color banding.** A gradient from a low-precision intermediate causes visible steps. Fix with dithering (add a tiny noise) or use higher precision.
- **Shadow banding.** The soft-shadow march samples the occlusion at discrete points, and the `min` picks a local feature that changes as you move across a pixel, producing rings. Fix with more samples or a smoother accumulation.
- **Fractal banding.** The iteration count (and hence the DE) is quantized; smooth coloring reduces it.

## 24.10 Temporal instability

A quantity that is discontinuous in *time* (Chapter 22) causes temporal popping/flicker. E.g. a repetition count that flips when an object crosses a cell boundary, or a `hash(floor(time))` that jumps. The fix is to make every animated decision continuous in $t$, or to smooth-blend across the discrete choice.

## 24.11 The error cascade

The prompt's "error analysis" pipeline:

```
Ideal mathematics
  → floating-point representation
  → approximation (finite differences, DE, smooth booleans)
  → ray-march accumulation
  → surface estimate (marching tolerance)
  → normal estimate (finite differences)
  → lighting
  → visible image
```

Each stage introduces its own error, and they can compound. Typically the *dominant* visible errors are (a) marching tolerance → chunky/steppy normals, (b) normal finite-difference $\varepsilon$ → sparkle/glare, (c) soft-shadow sampling → banding, (d) iteration-count quantization → fractal banding. Knowing which dominates lets you tune the right parameter.

## 24.12 Practical checklist

1. Re-center coordinates to avoid large-magnitude cancellation.
2. Choose $\varepsilon$ relative to the scene scale; use adaptive epsilon for depth.
3. Keep normal $\varepsilon$ near the optimal; tune visually.
4. Use a small clamp (`max(d, 1e-6)`) to avoid division/zero underflow in DEs and normals.
5. Use smooth blends instead of hard branches where you want continuity.
6. Dither gradients; add a tiny noise to kill color banding.
7. Increase soft-shadow samples or use a smoother accumulation to kill penumbra banding.
8. Make any animated quantity continuous in time.

## Exercises

1. **(Derivation)** Show that subtracting two floats of magnitude $\sim 10^3$ that differ by $10^{-3}$ loses all significant figures; quantify the cancellation.
2. **(Analytic)** Derive the trade-off in the finite-difference normal error and find the optimal $\varepsilon$.
3. **(Geometric)** Explain why the box SDF's `abs(p)-b` can suffer cancellation near a face and how to mitigate it.
4. **(Derivation)** Estimate the accumulated position error after $N$ march steps of size $d$ in a large scene.
5. **(Analytic)** Explain how a DE that overestimates distance causes tunneling, and how a factor $<1$ restores safety.
6. **(Implementation)** Add dithering to kill color banding in a smooth gradient.
7. **(Implement)** Compare a too-small and too-large normal $\varepsilon$; describe the visual differences in terms of this chapter's error model.
