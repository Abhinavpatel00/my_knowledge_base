# Chapter 17 — Noise

Noise is a *random-but-continuous* scalar field used as the raw material for procedural surfaces and fields. This chapter defines what noise is mathematically, derives value and Perlin noise, explains hashing, and shows how to get derivatives.

## 17.1 What noise is

A **noise function** $n:\mathbb R^d\to[0,1]$ (or $\to[-1,1]$) is a deterministic function that is:

1. **Continuous** (not stepwise/random per point),
2. **Locally supported-ish** (the value at $\mathbf p$ depends on points in a small neighborhood),
3. **Pseudo-random** (looks like random variation but is a deterministic function of the input),
4. **Statistically stationary** (its statistics don't drift with position).

The classic noise is **lattice-based**: space is divided into integer cells, each cell gets a random value/gradient, and the field is a smooth interpolation between the corners.

## 17.2 Hashing

The "random value" at each integer lattice point is produced by a **hash**: a deterministic, cheaply-computed pseudo-random function of the integer coordinates. The requirement is a *good* hash: it must be fast, have no obvious correlations, and return values in a known range.

A common GLSL hash for a 2D point:

```glsl
float hash21(vec2 p){ p = fract(p*vec2(123.34, 456.21)); p += dot(p,p+45.32); return fract(p.x*p.y); }
```

**Mathematical grounding.** A good hash is (ideally) a perfect pseudo-random function on the lattice, so that the noise has white spectrum (no drift, no correlations among neighbors). The later octave summation (FBM) *is* what gives the structured spatial frequencies, and it needs a flat hash spectrum to be correct. A poor hash produces visible grooves/lines (hash artifacts) along the lattice, which is the "noise banding" artifact (Chapter 24).

## 17.3 Value noise

**Value noise** interpolates *values* at lattice corners.

**Step 1.** Compute the lattice cell: $\mathbf i=\lfloor\mathbf p\rfloor$, fractional $\mathbf f=\mathbf p-\mathbf i$.

**Step 2.** Fetch the four (2D) or eight (3D) corner values via the hash.

**Step 3.** Smoothly interpolate. The natural interpolation uses a **smoothstep** (Hermite) blending function:

$$
u(t)=t^2(3-2t)=3t^2-2t^3 .
$$

**Why smoothstep?** The linear interpolation of random corner values would be *continuous but not differentiable* at cell boundaries (kinks at $\mathbf f=0$ or $1$), which shows up as visible "creases." The smoothstep $3t^2-2t^3$ has a zero derivative at $t=0$ and $t=1$, so the interpolation matches value *and slope* across cell boundaries. This makes the noise $\mathcal C^1$, which eliminates the creases and makes it suitable for smooth shading. (For higher smoothness, use the quintic $6t^5-15t^4+10t^3$, which is $\mathcal C^2$.)

**Padding/derivation.** The blend is a bilinear (2D) or trilinear (3D) interpolation of the corner values with the Hermite weights. In 2D:

$$
n(\mathbf p)=(1-u_x)(1-u_y)\,c_{00}+u_x(1-u_y)c_{10}+(1-u_x)u_y c_{01}+u_x u_y c_{11},
$$

where $u_x,t$ are the smoothstepped fractional coordinates and $c_{ij}$ are the corner hashes.

## 17.4 Perlin (gradient) noise

**Gradient noise** (Perlin) interpolates *gradients* rather than values. Each lattice point gets a random *gradient vector* $\mathbf g_i$, and the value at $\mathbf p$ is the smooth integration of these gradients.

**Mathematical definition.**

$$
n(\mathbf p)=\sum_{i}\mathbf g_i\cdot(\mathbf p-\mathbf c_i)\,w_i
$$

with appropriate smooth weights $w_i$ summing to 1 (a bilinear/trilinear blend of the distances to the corners dotted with their gradient). In 2D:

```
for each corner c of the cell:
    delta = p - c
    v = gradient[c] · delta
    n += v * weight(c)
```

**Why gradient noise.** Because each corner contributes a *linear* term (the dot product with a random gradient), the resulting field has controlled first derivatives and a wider spectral content than value noise: value noise has its energy mostly at low frequency (flat, "blobby"), while Perlin noise has more mid-frequency energy (fuller, more natural motion). This matters for FBM quality.

**The gradient derivative.** The derivative of the noise is essentially what you get by feeding the gradients directly, which is why we can obtain the noise *gradient* cheaply (see §17.5).

## 17.5 Derivative noise (analytic gradients)

Because value/Perlin noise is built from smooth polynomials, its *gradient* can be computed analytically rather than by finite differences. This is valuable because it costs roughly the same as the noise itself and gives exact gradients, enabling:

- smooth normal/height maps from noise,
- curl noise (derivatives of a 2D field),
- optimization of the displaced-field gradient.

For value noise, the derivative of the interpolation is computed from the corner values and the derivative of the smoothstep:

$$
\frac{d}{dt}\big(3t^2-2t^3\big)=6t-6t^2=6t(1-t).
$$

So the noise gradient is a combination of these derivative factors times the corner-value differences. For a 2D field,

$$
\frac{\partial n}{\partial x}=u_x'(t_x)\big[(1-u_y)(c_{10}-c_{00})+u_y(c_{11}-c_{01})\big]
$$

(and the analogous $y$ expression). This is why "noise with derivative" is cheap and exact.

## 17.6 Frequency/amplitude and the octave sum

Noise is the *primitive*; FBM (Chapter 16) sums it:

$$
\operatorname{fbm}(\mathbf p)=\sum_{i}a_i\,n(2^i\mathbf p+\text{offset}_i).
$$

Without the octave sum, a single noise is too smooth and featureless. The octaves give the *spectrum*. The "roughness" is set by the spectral exponent $-\log_2(\text{gain})/\log_2(\text{lacunarity})$.

## 17.7 The field class of noise

Noise and FBM are **not distance fields**. They are scalar *fields* with bounded range and bounded derivative (for a bounded octave sum, $\lVert\nabla\operatorname{fbm}\rVert$ is bounded). When used as an SDF *displacement* (Chapter 16), they turn an exact SDF into a **bound/estimator**. Noise values themselves have no metric meaning and cannot be used as a step for a ray marcher. This is the critical taxonomy point: **noise is an arbitrary scalar field, not a distance.**

## 17.8 Comparison

| Type | Value at corners | Smoothness | Spectrum | Cost | Best for |
|------|------------------|-----------|----------|------|----------|
| Value noise | scalar | $\mathcal C^1$ (smoothstep) | low-freq bias | low | Cheap, blobby |
| Perlin noise | gradient vectors | $\mathcal C^1$ | fuller | med | Natural motion, FBM |
| Simplex noise | gradient | $\mathcal C^1$ + triangulated | fuller | med-high | Higher dims, fewer axis artifacts |
| Worley/cellular | nearest-site | piecewise | sparse | med | Cracks, cells (Ch 18) |

## Exercises

1. **(Derivation)** Show that the smoothstep $3t^2-2t^3$ has zero derivative at $t=0,1$ and hence the interpolation is $\mathcal C^1$ across cell boundaries.
2. **(Derivation)** Derive the analytic gradient of 2D value noise from the interpolation formula.
3. **(Implementation)** Implement value noise (2D and 3D) with a hash; observe the effect of using linear vs. smoothstep interpolation.
4. **(Analytic)** Explain why Perlin noise has more mid-frequency energy than value noise.
5. **(Derivation)** Derive the Lipschitz bound of a single value-noise octave and of an FBM sum; state the field class.
6. **(Design)** Build an FBM with gain 0.6 and lacunarity 2, and one with gain 0.3; describe how the visual roughness differs.
7. **(Reverse engineering)** Given a fragment that uses `hash21` and `smoothstep`, reconstruct the noise type and its parameters.
