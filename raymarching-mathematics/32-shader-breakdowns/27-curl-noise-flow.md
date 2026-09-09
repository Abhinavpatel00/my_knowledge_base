# Shader Breakdown 27 — Curl Noise and Divergence-Free Flow Fields

**Curl noise** is the standard way to build a *divergence-free* (incompressible) vector field — the natural space for fluids, smoke, and flow. It is the vector calculus cousin of the noise techniques, and it is what makes procedural flow look "real" rather than fake (fluid cannot compress, so the flow doesn't bunch up and shimmer). This breakdown derives curl noise and its use in advecting flows.

## 1. The fragment (reconstructed key parts)

```glsl
// 2D curl: build a velocity that is divergence-free from a scalar potential
vec2 curlNoise2(vec2 p){
    float pot = fbm(p);                       // a scalar potential
    return vec2( d(pot)/d(p.y), -d(pot)/d(p.x) );   // rot of the potential
}

// 3D curl: v = curl(Psi)
vec3 curlNoise3(vec3 p){
    // Psi = a vector potential (3 channels of fbm)
    vec3 e = vec3(0.1, 0.0, 0.0);
    vec3 ddx = vec3( fbm(p+ddx.xyz)-fbm(p-ddx.xyz) );
    ... cross products of the gradients ...
}
```

## 2. Mathematics

### 2.1 Divergence-free fields

A vector field $\mathbf v$ is **divergence-free** (incompressible, "solenoidal") if
$$
\nabla\cdot\mathbf v=0.
$$
Fluid that is incompressible must satisfy this: it can't accumulate mass in a region, so the flow neither bunches up nor spreads out. This is what gives fluid/natural motion its "no sudden concentration" character.

### 2.2 The 2D curl

In 2D, any divergence-free field can be written as the **rotated gradient** (curl) of a scalar potential $\psi$:
$$
\mathbf v=\Big(\frac{\partial\psi}{\partial y},\ -\frac{\partial\psi}{\partial x}\Big).
$$
**Verify it's divergence-free:**
$$
\nabla\cdot\mathbf v=\frac{\partial}{\partial x}\frac{\partial\psi}{\partial y}-\frac{\partial}{\partial y}\frac{\partial\psi}{\partial x}=0
$$
(the mixed partials cancel). So *any* scalar potential $\psi$ gives a divergence-free 2D field. Taking $\psi=\operatorname{fbm}(\mathbf p)$ gives a "curl of fbm": a divergence-free flow derived from the noise.

**Interpretation.** This is the standard "curl noise." It's a formula for the velocity field, and because it's divergence-free, particles/patterns advected along $\mathbf v$ swirl and drift without clumping. It's the basis of most "flow" textures.

### 2.3 The 3D curl

In 3D, the divergence-free field is the curl of a **vector potential** $\mathbf\Psi$:
$$
\mathbf v=\nabla\times\mathbf\Psi.
$$
Using the standard curl formula, and taking $\mathbf\Psi$ to be three channels of fBm, gives a 3D divergence-free flow. The partial derivatives are usually computed with central differences (or analytically from the noise's gradient).

### 2.4 Use in shading

Curl noise advects a field or a particle's position over time:
$$
\frac{\partial \mathbf x}{\partial t}=\mathbf v(\mathbf x,t)=\operatorname{curl}\big(\operatorname{fbm}(\mathbf x+\text{time offset})\big).
$$
This is used for smoke, water, nebula, and any "flowing medium." The time offset moves the noise's phase so the flow drifts; because $\mathbf v$ is divergence-free, it doesn't "bunch up" into a blobby mess.

## 3. The thinking process

1. **Ideas.** "I want natural, fluid flow (smoke, water, nebula)." → a divergence-free field.
2. **Math.** "How do I guarantee incompressibility?" → use the curl (rot) of a potential.
3. **Noise.** "Where does the structure come from?" → fBm as the potential.
4. **Advect.** "Move material along the flow." → $\dot{\mathbf x}=\mathbf v$.

## 4. Field class

| Quantity | Class |
|----------|-------|
| $\psi=\text{fbm}$ | arbitrary scalar |
| $\mathbf v=\nabla\times\psi$ | divergence-free vector field |
| $\dot{\mathbf x}=\mathbf v$ | advection ODE |

Curl noise is **not a distance field** — it's a *velocity* field used for advection, not for marching a surface. It's a tool for shading/animation, orthogonal to the SDF machinery. (In Chapter 16 we noted this distinction.)

## 5. Extensions

- **Advect a texture.** Warp the sample coordinate by integrating the flow: `p = p + curl(p, t) * dt`. Bunching-free motion.
- **Turbulence by multiple scales.** Sum curl noises at several octaves (a "curl-fBm").
- **Steady vs. MHD flows.** Add a time-varying phase, or combine curl noise with a base velocity for "swirling wind."
- **2D flow for "particles".** In a raymarch, offset the start point of a procedural pattern by a curl-integrated displacement for "flowing ink."
- **Curved-ray via curl.** This is a natural way to do the *curved-ray* marching (Breakdown 7): the ray bends along a divergence-free flow.

## Exercises

1. **(Derivation)** Show the 2D curl $\mathbf v=(\partial\psi/\partial y,-\partial\psi/\partial x)$ is divergence-free (mixed partials cancel).
2. **(Derivation)** Write the 3D curl $\nabla\times\mathbf\Psi$ component-wise.
3. **(Analytic)** Explain why divergence-free means "no bunching," and its visual benefit.
4. **(Design)** Advect a texture by a curl field; describe the "flowing ink" look.
5. **(Design)** Combine curl noise with the curved-ray method for a bending ray.
6. **(Implementation)** Render a 2D curl flow texture.
