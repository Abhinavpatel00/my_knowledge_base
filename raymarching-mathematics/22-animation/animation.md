# Chapter 22 — Animation

Animation is not "add `+ iTime`." It is making the mathematical model a function of a time parameter. This chapter treats time as a first-class variable and develops the mathematics of periodic motion, interpolation, traveling waves, and evolving fields — and explains why some animations look stable and others flicker.

## 22.1 Time as a parameter

The whole scene model becomes

$$
f(\mathbf p,t).
$$

Time $t$ is a scalar driving every animated quantity. The shader passes `iTime` (seconds since start) into the model. The task is to choose how $t$ enters each parameter.

**The coherence requirement.** For the image to be temporally stable (no flicker, no popping), $f$ must be **continuous** in $t$ for each fixed $\mathbf p$, and ideally $\mathcal C^1$ in $t$. Discontinuous changes in $t$ (e.g. a parameter that flips at an integer) produce visible "pops." Smooth periodic functions avoid this.

## 22.2 Phase, frequency, and periodicity

The fundamental oscillatory building block is

$$
\phi(t)=\sin(\omega t+\phi_0).
$$

| Parameter | Meaning | Visual effect |
|-----------|---------|---------------|
| $\omega$ (angular frequency) | $2\pi/\text{period}$ | Speed of the cycle |
| $\phi_0$ (phase) | initial offset | Phase-locks multiple motions |
| $A$ (amplitude) | oscillation range | How far it oscillates |

**Notes on units.** $\omega$ in radians/second; $\text{period}=2\pi/\omega$. To get a cycle *per $T$ seconds*, use $\omega=2\pi/T$. Using $\sin(\omega t)$ gives a *stationary* harmonic; a phase loop $\phi_0=\omega_0 t$ gives a continuous drift.

**Periodicity.** Any function $\sin(\omega t)$ is periodic with period $2\pi/\omega$. Periodic motion is temporally stable because it returns to the same state smoothly.

## 22.3 Harmonics

A **harmonic** is an integer multiple of a base frequency. Summing harmonics

$$
\sum_{k=1}^{N}a_k \sin(k\omega t+\phi_k)
$$

creates richer, less mechanical motion. This is the *time-domain* analogue of FBM (spatial octaves) — but in time. Use it for organic pulsing, breathing, wiggling.

## 22.4 Oscillation, damping, and easing

**Damped oscillation.** $\sin(\omega t)\,e^{-dt}$ decays over time (a "settling" motion). The damping factor $e^{-dt}$ ensures $\mathcal C^\infty$ approach to rest.

**Easing functions.** Interpolations between values often use **ease** curves to avoid motion that's too linear. The mathematical form of the classic **smoothstep**

$$
\operatorname{smoothstep}(a,b,x)=t^2(3-2t),\qquad t=\operatorname{clamp}\!\Big(\frac{x-a}{b-a},0,1\Big),
$$

gives $\mathcal C^1$ (zero-derivative endpoints) interpolation. The **ease-in-out** is the same smoothstep applied to a normalized time. For a *spring* ease, use a damped sine.

## 22.5 Interpolation

Interpolating between scalar/vector parameters over time. The two main forms:

$$
\text{lerp}(a,b,s)=a+(b-a)s,\qquad \text{with } s=\text{smoothstep}(t).
$$

**Linear interpolation (lerp).** Constant velocity, sharp corners at endpoints (non-differentiable in $t$ if $s$ is linear). **Smoothstep interpolation.** $\mathcal C^1$ at endpoints, slow-fast-slow. **Cubic/Bezier interpolation** gives $\mathcal C^2$.

For *rotations*, interpolate with quaternions via **slerp** (Chapter 02), which is the proper spherical interpolation.

## 22.6 Traveling waves

A **traveling wave** propagates a pattern in space as time advances:

$$
u(\mathbf p,t)=A\sin(\mathbf k\cdot\mathbf p-\omega t).
$$

The phase $\mathbf k\cdot\mathbf p-\omega t$ moves with velocity $\omega/\lVert\mathbf k\rVert$ in the direction $\mathbf k$. This is the basis of ripples, flowing stripes, waves in water, and the "warm/cool" banding animations.

**Spatiotemporal phase.** In GLSL, `sin(p.x*f - iTime*s)` is a wave traveling along $x$. By varying the direction (using $\mathbf k$), you get waves in any orientation; by summing directional waves, you get complex interference.

## 22.7 Rotating frames

**Rotating frames** animate an object's orientation over time. Apply a time-dependent rotation to the sample point before evaluating the field:

$$
\mathbf p'=R(\omega t)\,\mathbf p,\qquad f(\mathbf p,t)=f_0(R(\omega t)\mathbf p).
$$

**Exactness.** A time-varying *rotation* is an isometry for each $t$, so $f(\mathbf p,t)$ is an exact SDF for every fixed $t$ (the distance property holds pointwise in $t$, and since the rotation is smooth, $f$ is continuous in $t$). This is why rotating a rigid SDF is safe and stable.

## 22.8 Morphing implicit surfaces

**Morphing** between two (or more) implicit surfaces is done by blending their fields:

$$
f(\mathbf p,t)=\operatorname{mix}\big(f_A(\mathbf p),f_B(\mathbf p),s(t)\big),
$$

or by *warping* the coordinate. The quantitative point: a *linear* interpolation of distance fields is generally **not** an SDF (it's a bound), but it is a *valid* interpolation of the surfaces. The transition is smooth as long as $s(t)$ is smooth. For *topology-changing* morphs (e.g. a sphere splitting into two), a smooth-union style blend gives a visually continuous transition.

**The important subtlety.** Interpolating $f_A$ and $f_B$ linearly does not necessarily interpolate their *surfaces* in a visually simple way, but it does give a continuous family of surfaces. In practice, morphing is usually done with the *smooth-union/hybrid* of the distance fields, which is smooth and acceptable as a bound.

## 22.9 Parameter interpolation and domain motion

- **Parameter interpolation.** Animate the *parameters* of a primitive (radius, height, blend radius) with time. Because the primitive's SDF is continuous in its parameters, the animated field is continuous in $t$.
- **Domain motion.** Animate the *coordinates* — moving the sample point through a tiled/periodic scene (the "infinite tunnel" fly-through). This is a time-dependent translation of the domain:
  $$
  f(\mathbf p,t)=f_0(\mathbf p-\mathbf c(t)).
  $$
  If $f_0$ is periodic/repeated, a moving $\mathbf c(t)$ produces the "fly through an infinite corridor" effect.

## 22.10 Noise evolution

Animate noise by offsetting its *input* by a time-varying phase, e.g.

$$
n(\mathbf p+\mathbf v t),
$$

or by evolving its parameters. This is the standard way to make water, smoke, and clouds move naturally. **Temporal coherence** requires the noise to be *continuous in time*; hashed lattice noise with a time offset is smooth, so it animates well.

## 22.11 Temporal coherence and stability

**Why some animations flicker.** If a quantity is *discontinuous* in time (e.g. a repetition count that flips when the object crosses a cell boundary, or a hash `floor` of time), then adjacent frames differ by a large jump — a "pop." The fix is to ensure every animated quantity is continuous in $t$ (use smooth functions, avoid `floor(iTime)` for geometry choices, use interpolation).

**The rule.** For visual stability, $f$ must be continuous (ideally $\mathcal C^1$) in $t$. Every discrete decision (which tile, which cell, which material) must be made *continuously* or smoothly-blended.

## Exercises

1. **(Derivation)** Write a traveling wave and compute its phase velocity.
2. **(Derivation)** Explain why a linear interpolation of two distance fields is a bound, not an SDF.
3. **(Implementation)** Animate a rotating torus and note whether the field stays exact and stable.
4. **(Design)** Build a "breathing" organic shape by animating a smooth-union blend radius.
5. **(Implementation)** Create a traveling-wave displacement on a plane.
6. **(Analytic)** Explain why a `mix(fA,fB,s(t))` morph is continuous in $t$ but the field class becomes a bound.
7. **(Reverse engineering)** A fragment contains `sin(p*3.0 - iTime*1.5)`. Reconstruct the animated quantity and its phase velocity.
