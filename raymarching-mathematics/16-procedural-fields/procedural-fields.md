# Chapter 16 — Procedural Fields and Deformation

Organic, turbulent, and "materially complex" surfaces are not usually produced by more primitives. They are produced by **displacing a base distance field with a procedural function**. This chapter treats displacement and deformation as mathematics: what a frequency and amplitude actually do, how multi-frequency sums create structure, and how domain warping operates.

## 16.1 Displacement of a distance field

Start with a base SDF $d_0$ and a scalar *displacement function* $g:\mathbb R^3\to\mathbb R$. The **displaced field** is

$$
d(\mathbf p)=d_0(\mathbf p)+g(\mathbf p).
$$

**Interpretation.** The surface $d=0$ is the set where $d_0=-g$; that is, the displaced surface is the base surface pushed "outward" by $g$ (if $g>0$) or "inward" (if $g<0$) along the normal. This is exactly a displacement: each point of the base surface moves by $g$ times the local normal direction.

**Safety.** $d_0$ is 1-Lipschitz. If $g$ is *also* 1-Lipschitz, then $d=d_0+g$ has $\lVert\nabla d\rVert\le2$ (the gradients add), so $d$ is only 2-Lipschitz and is a **distance bound**, not an exact SDF. To *restore* safety up to a factor, scale the step by the Lipschitz constant of $g$, or explicitly compute the bound.

**In practice.** Noise is not usually cleanly Lipschitz. Most raymarchers use displacement as a *bound* — the displaced field is an estimate that's visually fine because the displacement magnitude is small relative to feature size, but it is mathematically a bound/estimator. This is one of the most common places where a field "is not an exact SDF" and the book flags it.

## 16.2 Frequency and amplitude

A sinusoidal displacement is the canonical example:

$$
g(\mathbf p)=A\sin(k\,(\text{some coordinate})).
$$

The **amplitude** $A$ and **frequency** $k$ have precise meanings:

| Parameter | Mathematical meaning | Visual effect |
|-----------|----------------------|---------------|
| $A$ (amplitude) | The maximum displacement of the surface from base | Controls *how far* the surface bulges/warps. |
| $k$ (frequency) | The spatial frequency, $\theta'=k$; wavelength $\lambda=2\pi/k$ | Controls *how often* the bulges repeat. |
| $\phi$ (phase) | Shifts the wave | Animates the pattern over time. |

**Dimensional analysis.** $A$ has units of length; $k$ has units of inverse length. The product $A k$ is dimensionless and measures the *relative* "steepness" of the surface's slope. When $Ak\gg1$ the surface oscillates far faster than it moves in space — the displacement becomes a fine "ripple," and the resulting field's gradient grows large (since $\nabla g\sim Ak$), so the Lipschitz constant of the displacement is $\sim Ak$, meaning the field becomes a very loose bound.

## 16.3 Multi-frequency (spectral) deformation

Real structures have detail at many scales. A **multi-frequency sum**

$$
g(\mathbf p)=\sum_{i=0}^{N-1}a_i\,n\!\big(2^i\mathbf p\big)
$$

builds detail from coarse to fine. Here $a_i$ is the **amplitude** and $2^i$ is the **frequency** of octave $i$. The **lacunarity** (frequency ratio, normally 2) and **gain** (amplitude ratio, normally 0.5) control the spectral shape.

**Why changing $a_i$ and frequency changes visual roughness.** The function $g$ is a sum of octaves. The *low-frequency* octaves ($i$ small) create the large-scale structure — the broad lumps and swells. The *high-frequency* octaves ($i$ large) create fine detail — the small ripples and grain. If the gain is high (amplitudes stay large at high frequency), the surface is *rough* (lots of fine, high-amplitude detail). If the gain is low, the surface is *smooth* (high-frequency detail is insignificant).

**The roughness parameter.** Define the sum with $a_i=\text{gain}^i$ and frequency $2^i$. Then:

- $\text{gain}\to0$: only the first octave matters → smooth, low-frequency blobs.
- $\text{gain}\to1$: all octaves equally strong → "fractal," self-similar roughness (the surface looks similar at every zoom scale).
- $\text{gain}>1$: fine detail dominates → very rough, possibly noisy.

**Scaling behavior.** Because the octaves multiply frequency by 2 and amplitude by `gain`, the field $g$ scales with the *fractal dimension* of the roughness: the spectral exponent is $-\log_2(\text{gain})/\log_2(\text{lacunarity})$, which relates to the fractal dimension of the displaced surface. This is the quantitative "roughness" the prompt asks about.

## 16.4 FBM and turbulence

**FBM (fractional Brownian motion).** The sum of octaves (value/Perlin noise) is

$$
\operatorname{fbm}(\mathbf p)=\sum_{i=0}^{N-1}a_i\,n(2^i\mathbf p),\qquad a_i=\text{gain}^i,\ \text{freq}_i=2^i .
$$

This gives natural, cloud-like, "would look like nature" structure. The *number of octaves* $N$ sets the finest detail.

**Turbulence.** A common variant takes the absolute value of the noise before summing, which creates sharp ridges (because `abs` folds the noise's sign, producing fold lines). This is used for turbulent fire, molten rock, and erosion.

## 16.5 Ridged noise

**Ridged noise** emphasizes *crest* lines. A typical construction:

$$
\operatorname{ridged}(\mathbf p)=\sum_{i}\frac{(1-\lvert n(2^i\mathbf p)\rvert)^{p}}{2^i},
$$

where $p$ steepens the ridge profile. The `1-|n|` flips valleys into peaks, so the *crest of the noise* becomes a persistent ridge, and the denominator $2^i$ gives distance falloff. This produces mountain ridges, lightning, and "ridge-veined" materials.

## 16.6 Domain warping

**Domain warping** feeds one procedural field into the *coordinates* of another:

$$
f_{\text{warped}}(\mathbf p)=F\!\Big(\mathbf p+\lambda\ \mathbf W(\mathbf p)\Big),
$$

where $\mathbf W$ is a (possibly vector-valued) field and $\lambda$ is the warp strength. The canonical double warp:

$$
\mathbf q=\operatorname{fbm}(\mathbf p),\qquad
f(\mathbf p)=\operatorname{fbm}\!\big(\mathbf p+\mathbf q\big)
$$

or the famous triple: `q = fbm(p); r = fbm(p + q); f = fbm(p + r)`.

**Why domain warping creates complexity.** The composition $\mathbf p\mapsto\mathbf p+\lambda\mathbf W(\mathbf p)$ is *not linear* and generally *not isometric*. It folds, stretches, and curls the coordinate domain. Even if $F$ and $\mathbf W$ are individually simple, their composition produces swirls, veining, marble, and turbulent flow that look far more complex than either alone. The complexity is *generated*, not modeled.

**The Jacobian of the warp.** $\frac{\partial}{\partial\mathbf p}(\mathbf p+\lambda\mathbf W)=I+\lambda J_{\mathbf W}$. Its operator norm is $1+\lambda\lVert J_{\mathbf W}\rVert$. Because the warp can stretch or compress space (and importantly, can *fold* it, making the map non-injective), the warp is **not isometric**, so a distance field that uses domain warping before measuring distance becomes a **bound/estimator**. In practice this is fine as long as the warp is small relative to feature size, but it's not an exact SDF.

## 16.7 Curl fields and flow fields

**Curl noise.** A **divergence-free** (incompressible) vector field is a curl of a potential. In 2D,

$$
\mathbf v(x,y)=\left(\tfrac{\partial\psi}{\partial y},\ -\tfrac{\partial\psi}{\partial x}\right),\qquad \nabla\cdot\mathbf v=0.
$$

In 3D, $\mathbf v=\nabla\times\boldsymbol\psi$. Curl noise is used to advect particles/flow along divergence-free paths — the basis for **flow fields**, fluid turbulence, and smoke/cloud advection. Because $\nabla\cdot\mathbf v=0$, the flow doesn't compress or expand (no "mushy" accumulation), which gives it the natural look of fluids.

**Flow fields.** A flow field is a time-dependent vector field $\mathbf v(\mathbf p,t)$ (often from curl noise). Particles/paths follow the integral curves. In procedural shading, flow fields warp coordinates in a rotating/churning way, or drive the movement of stripes and waves.

## 16.8 The field class in each case

| Displacement | Field class | Safe? |
|--------------|-------------|-------|
| Small sinusoidal displacement | Bound/estimator | Usually fine |
| FBM displacement | Estimator | Fine visually |
| Domain warp | Estimator (non-injective possible) | Fine if warp small |
| Ridged/turbulence | Estimator | Fine |
| Curl/flow (vector) | Not a distance at all | Only for advection, not for an SDF |

**The recurring point.** Any of these *deforms* the distance field and, in general, destroys the exact-SDF property. We must treat the result as an estimate and ensure the marcher is conservative (e.g. by scaling the step, or by keeping the displacement amplitude small relative to feature size).

## 16.9 Curvature-based and volumetric displacement

Beyond scalar displacement, procedural shading can add:

- **Mean-curvature displacement** — push or pull along the normal proportional to local mean curvature, giving smooth "melt" or "inflation" effects (Chapter 12).
- **Shell/onion displacement** — combine with `abs(d)-t` (Chapter 09) to build layered structures.
- **Tube/lathe displacement** — displace a surface by a periodic function of the angular coordinate to create flutes, ribs, and gear teeth (Chapter 08 revolution).

These are all "deformation as a mathematical operator applied to the distance field," and they all fall into the bound/estimator category when they are not isometries.

## Exercises

1. **(Derivation)** Show that $d=d_0+g$ with both $d_0,g$ 1-Lipschitz is 2-Lipschitz, and hence a bound; give the safe-step scale factor.
2. **(Derivation)** Compute the gradient $\nabla(\sin(kx))$ and derive the Lipschitz constant $k$ for $A\sin(kx)$.
3. **(Analytic)** Explain why low-frequency octaves control large-scale structure and high-frequency octaves control fine detail, in terms of the spectrum.
4. **(Derivation)** Show that the domain-warp Jacobian is $I+\lambda J_{\mathbf W}$ and explain why a small warp keeps the field acceptable as a bound.
5. **(Design)** Build a displacement that produces ridges using `1-|noise|`; describe the resulting "crest" geometry.
6. **(Analytic)** Explain why curl noise is divergence-free and why that matters for flow realism.
7. **(Design)** Warp a torus with a small FBM to make a "molten ring"; describe the field class and the safety trade-off.
