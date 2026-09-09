# Chapter 15 — Reflection and Refraction

Mirrors, glass, water, and crystal all come from the physics of how a ray changes direction at a surface. This chapter derives the reflection and refraction equations, then shows how a raymarcher approximates the recursive paths.

## 15.1 The law of reflection

**Physical statement.** A ray reflects off a surface such that the angle of incidence equals the angle of reflection, with the reflected ray lying in the plane of incidence (the plane containing the incident ray and the normal).

**Vector form.** For a unit incident direction $\mathbf d$ (pointing *into* the surface) and unit normal $\mathbf n$, the **reflected direction** is

$$
\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n .
$$

**Derivation.** Decompose $\mathbf d$ into its component parallel and perpendicular to $\mathbf n$:

$$
\mathbf d=(\mathbf d\cdot\mathbf n)\mathbf n+\big[\mathbf d-(\mathbf d\cdot\mathbf n)\mathbf n\big].
$$

The reflection negates the normal component (the ray bounces "back" across the surface) and keeps the tangential component unchanged. Hence

$$
\mathbf r=-(\mathbf d\cdot\mathbf n)\mathbf n+\big[\mathbf d-(\mathbf d\cdot\mathbf n)\mathbf n\big]
=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n .
$$

**Interpretation.** If $\mathbf d$ is incoming (direction of travel), $\mathbf r$ is outgoing. Both are unit vectors (reflection is an isometry, preserving length). The term $-2(\mathbf d\cdot\mathbf n)$ is the "double projection onto the normal" correction.

**GLSL.** `reflect(d, n)` (with d pointing toward the surface).

## 15.2 The law of refraction (Snell's Law)

When a ray passes from a medium with refractive index $\eta_i$ into one with index $\eta_t$, it bends according to **Snell's law**:

$$
\eta_i\sin\theta_i=\eta_t\sin\theta_t,
$$

where $\theta_i$ is the angle of incidence (between the incoming ray and the normal) and $\theta_t$ is the angle of refraction (between the refracted ray and the normal, on the *far* side).

**Derivation of the vector form.** Let $\mathbf d$ be the unit incident direction and $\mathbf n$ the unit normal pointing *out of* the first medium (toward the second). Let $\mu=\eta_i/\eta_t$. The refracted direction $\mathbf t$ is:

$$
\mathbf t=\mu\,\mathbf d+\big(\mu\cos\theta_i-\cos\theta_t\big)\mathbf n,
\qquad
\cos\theta_i=-\mathbf d\cdot\mathbf n .
$$

Now use Snell to relate the cosines via the basic identity $1-\cos^2$:

$$
\cos\theta_t=\sqrt{1-\mu^2\big(1-\cos^2\theta_i\big)} .
$$

**Derivation of this scalar.** Squaring Snell: $\mu^2\sin^2\theta_i=\sin^2\theta_t$, so $\cos^2\theta_t=1-\sin^2\theta_t=1-\mu^2(1-\cos^2\theta_i)$, giving the square root. Choosing the positive root corresponds to the physically transmitted ray (bending away from the normal as you enter a denser medium).

**The full refraction vector:**

$$
\mathbf t=\mu\mathbf d+\big(\mu(-\mathbf d\cdot\mathbf n)-\sqrt{1-\mu^2(1-(\mathbf d\cdot\mathbf n)^2)}\big)\mathbf n.
$$

**GLSL.** `refract(d, n, eta)` (with d pointing toward the surface, n pointing outward from the surface toward the incident side).

**Interpretation.** When $\eta_t>\eta_i$ (entering a denser medium, e.g. air into glass), $\mu<1$, the ray bends *toward* the normal. When leaving a dense to a less dense medium ($\mu>1$), the ray bends *away* from the normal.

## 15.3 Total internal reflection

When $\mu>1$ (going from denser to less dense medium), the term under the square root

$$
1-\mu^2(1-\cos^2\theta_i)
$$

can become **negative** for incidence angles beyond the **critical angle** $\theta_c$, defined by

$$
\sin\theta_c=\frac{\eta_t}{\eta_i}=\frac{1}{\mu}.
$$

At $\theta_i>\theta_c$, no refracted ray exists; the ray is **totally internally reflected**. The fraction under the square root is negative, so `refract` returns a zero vector in GLSL — we must detect this and switch to reflection.

**Implementation.** If the discriminant is negative, use `reflect(d,n)` instead of `refract`. In ShaderToy GLSL, when `refract` produces a zero vector, we fall back to reflection.

## 15.4 Fresnel reflectance and refraction mixing

Whether a ray *mostly reflects* or *mostly refracts* depends on the Fresnel term (Chapter 13). For a material with a surface normal $\mathbf n$ and refraction indices, the fraction of energy reflected is $F(\theta)$; the rest, $1-F(\theta)$, is refracted. The Schlick approximation (Chapter 13) gives $F(\theta)=F_0+(1-F_0)(1-\cos\theta)^5$, with $F_0=(1-\eta)^2/(1+\eta)^2$ for a dielectric at normal incidence.

So glass is modeled as:

```
vec3 reflect_dir = reflect(d, n);
vec3 refract_dir = refract(d, n, eta);
float f = fresnel_schlick(cos_theta, F0);
color = f * trace(reflect_dir) + (1-f) * trace(refract_dir);
```

## 15.5 Recursive vs. iterative raymarching

Reflected/refracted rays in raymarching are handled by **tracing the bounce ray with the same sphere-tracer** (with a new origin just off the surface and the bounce direction). Two practical architectures:

1. **Recursive / bounded-depth.** Compute $L=L(\mathbf p)$ with $K$ bounces. Each bounce re-traces from the new surface point. This is the physically motivated approach but grows cost multiplicatively with depth. In GLSL, recursion is often unrolled or depth-limited (e.g. $K=2$ or $3$).

2. **Iterative / path accumulation.** Some shaders trace the reflected/refracted ray once to gather environment/emissive color and then stop. This is cheaper and suffices for many glass/mirror looks.

**Cost control.** Because each bounce is a full raymarch, a reflective scene multiplies cost by the bounce depth. Budgeting is essential (Chapter 25). A common trick is to approximate distant reflections with the environment/scene-level color rather than a full trace.

**Bias when restarting.** The bounce ray must restart with a small offset along $\mathbf n$ (or `-n`) to avoid re-hitting the surface immediately (the same self-shadow bias issue as Chapter 14).

## 15.6 Refraction and the "thick glass" look

A naive single refraction at a surface doesn't capture a glass object's body (internal reflections, absorption, dispersion). A common raymarched approximation:

1. At the entry surface, refract the ray and trace it *through the volume* of the object (marching inside).
2. At the exit surface, refract again back into air.
3. Optionally apply **absorption** along the interior path (Beer–Lambert), and **internal reflection** (Fresnel-driven).

This "path through the medium" is what gives glass/water its characteristic look. Dispersion (color-split by wavelength-dependent refractive index) can be approximated by tracing refraction with slightly different $\eta$ for R, G, B.

## 15.7 Summary table

| Operation | Vector form | Condition | Use |
|-----------|-------------|-----------|-----|
| Reflection | $\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n$ | always | Mirrors, metals |
| Refraction | $\mathbf t=\mu\mathbf d+(\mu\cos\theta_i-\cos\theta_t)\mathbf n$ | if discriminant $\ge0$ | Glass, water, lenses |
| Total internal reflection | use $\mathbf r$ | if discriminant $<0$ | Dens-to-rare media |
| Fresnel mix | $F(\theta)$ Schlick | all | Glass energy balance |

## Exercises

1. **(Derivation)** Derive the reflection vector by decomposing $\mathbf d$ into normal and tangential components.
2. **(Derivation)** Derive the refraction vector from Snell's law and the cosine identity.
3. **(Derivation)** Derive the critical angle and the condition for total internal reflection. Show that the discriminant is $1-\mu^2(1-\cos^2\theta_i)$.
4. **(Implementation)** Implement a Fresnel-mixed reflection/refraction shader on a sphere; explain the `if` branch for TIR.
5. **(Analytic)** Explain why a recursive raymarcher scales exponentially in bounce depth, and describe a cost-reduction strategy.
6. **(Design)** Build a "glass" material with absorption along the interior path; describe the Beer–Lambert attenuation and the color variation it gives.
