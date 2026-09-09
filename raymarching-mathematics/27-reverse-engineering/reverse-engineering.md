# Chapter 27 — Reverse Engineering Shaders

Reverse engineering an unknown shader is the skill of reading a fragment and reconstructing the **mathematical model** it encodes. This is the inverse of the whole book: instead of going from math to code, you go from code to math. This chapter provides a systematic process and works a full example.

## 27.1 The systematic process

Given an unknown shader, work top-down:

```
Shader
  → identify camera
  → identify ray
  → identify coordinate normalization
  → identify domain transforms
  → identify primitive/field
  → identify repetition/folding
  → identify iteration
  → identify lighting
  → identify color mapping
  → identify animation
```

Each stage identifies a *mathematical object*. Let's make each precise.

### Step 1 — Camera
Look for `ro`, `rd`, `fragCoord`, `iResolution`, `uv`. Reconstruct the camera basis and the projection. Determine perspective vs. orthographic, FOV, aspect handling. Output: camera origin $\mathbf o$, ray direction $\mathbf d(\text{pixel})$.

### Step 2 — Ray generation
Confirm the ray $\mathbf r(t)=\mathbf o+t\mathbf d$. Note whether the ray is normalized.

### Step 3 — Coordinate normalization
Identify the mapping from pixel to world, and whether the aspect ratio is corrected. Note the orientation/sign conventions.

### Step 4 — Domain transforms
Find every `rot`, `abs`, `mod`, `fract`, `mix`, `clamp`, and nonlinear warp. Each is a *space transform*. Output: the composite map $T$ (or its components).

### Step 5 — Primitive / field
Identify the base primitive SDF (sphere, box, cylinder, torus, capsule) and its parameters. If the field returns a distance estimate (fractal DE), identify it.

### Step 6 — Repetition / folding
Find `mod` (repetition), `abs` (folding/mirror), and radial/polar wrap. Reconstruct the symmetry group.

### Step 7 — Iteration
If there's a `for` loop, identify the iteration (fractal map, KIFS, or a soft-shadow/AO/light march). Determine what's accumulated.

### Step 8 — Lighting
Identify the normal computation, the light model (Lambert/Blinn-Phong/GGX), the shadow (hard/soft), the AO, the Fresnel/Schlick, the reflection/refraction. Output: the lighting equation.

### Step 9 — Color mapping
Identify how the hit point's coordinates, normals, iterates, or orbit traps map to color. Output: the color function.

### Step 10 — Animation
Find `iTime` dependence. Identify the animated parameters and whether the motion is coherent (continuous in $t$).

## 27.2 Worked example: a small raymarch

**Original fragment** (a simple sphere):

```glsl
void mainImage(out vec4 o, in vec2 fragCoord){
    vec2 uv = (2.0*fragCoord - iResolution.xy)/iResolution.y;
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    float t = 0.0;
    for(int i=0;i<100;i++){
        vec3 p = ro + rd*t;
        float d = length(p) - 1.0;
        if(d<1e-4) break;
        t += d;
    }
    vec3 n = normalize(vec3(length(ro+rd*t+vec3(1,0,0))-1.0,
                            length(ro+rd*t+vec3(0,1,0))-1.0,
                            length(ro+rd*t+vec3(0,0,1))-1.0));
    vec3 col = 0.5 + 0.5*n;
    o = vec4(col,1.0);
}
```

**Annotate / rewrite cleanly:**

- Camera: `uv` normalized to $[-1,1]$, aspect-corrected by dividing by `iResolution.y`. `ro=(0,0,-2)`, `rd=normalize(vec3(uv,1))`. So the camera looks along $+z$, image plane at $z=-1$, perspective.
- March: sphere-trace with $d=\lVert p\rVert-1$, base $\varepsilon=1e-4$, 100 steps.
- Normal: *forward differences* along the axes (using 3 extra field evals, not central). It's a first-order (forward-difference) normal, slightly biased but fine here.
- Color: `0.5+0.5*n` — maps the normal to a color (a "normal color" debug shading).

**Translate to equations:**

$$
\mathbf r(t)=\mathbf o+t\mathbf d,\quad \mathbf o=(0,0,-2),\quad \mathbf d=\operatorname{normalize}(u,v,1),\quad d_{\text{sphere}}=\lVert\mathbf p\rVert-1.
$$

$$
t\gets t+d_{\text{sphere}}\quad\text{if}\ d<1e-4\ \text{stop}.
$$

$$
\mathbf n\approx\frac{\big(d(\mathbf p+\epsilon\mathbf e_x),d(\mathbf p+\epsilon\mathbf e_y),d(\mathbf p+\epsilon\mathbf e_z)\big)}{\lVert\cdot\rVert}\ \text{normalized}.
$$

$$
\text{color}=\frac12+\frac12\mathbf n .
$$

**Derive/identify:**

- The field is an **exact SDF** (unit sphere), so sphere tracing is safe.
- The normal is a **forward-difference** (first-order) normal; it's biased, but for a smooth sphere it's fine (the bias is a small tilt).
- The color is a **normal-shading debug** (not a real lighting model).

**Hidden transformations / approximations:**

- The aspect ratio correction by `iResolution.y` (not `iResolution.x`) is used (both axes normalized by the same value) — correct.
- There's no shadow, no AO, no Fresnel — it's a minimal debug shader.
- The normal uses an *axis-aligned* forward difference, so it has a small "directional" bias (it's slightly asymmetric).

**Reconstruct the visual logic.** The image is a shaded sphere: gray with normal-based coloring (so it looks like a smooth ball lit by "normal direction = color"). The whole thing is the canonical "first sphere" — the base case.

## 27.3 A more complex example (structure)

Consider a fragment containing:

```glsl
p = p - vec3(0.,0.,time);
p = mod(p+1.5, 3.)-1.5;
float a = atan(p.z, p.x);
a = mod(a, .5)-.25;
p.xz = vec2(cos(a)*r, sin(a)*r);
float d = sdTube(p, 1.0);
```

**Reconstruction:**

- `p -= time` : translation (moving the scene along $z$; a fly-through).
- `mod(p+1.5, 3.)-1.5` : centered repetition along each axis (Chapter 11) — a tiled tunnel.
- `atan(p.z,p.x)`, `mod(a,.5)-.25`, then rebuild `p.xz` : **angular (radial) repetition** into an $n$-fold sector, using polar coordinates. This is a **kaleidoscopic / radial fold**.
- `sdTube` : an infinite cylinder (tube) — a tunnel wall.

So the shader is a **repeated, radially-folded tunnel** that the camera flies through. The visual logic: an infinite, symmetric corridor that self-symmetrizes every angle — i.e. a star/triangular tunnel. Mathematical structure: **cylinder primitive + axial repetition + radial repetition**.

## 27.4 Common "hidden" patterns to look for

- **A `mod` that looks like repetition.** Check the period and the centering.
- **An `abs` that's a mirror fold.** Combined with a `-c`, it's a reflection map.
- **`atan` + `mod` + rebuild.** That's polar/radial repetition (a "kaleidoscope").
- **A `for` loop that isn't a fractal.** Could be a soft shadow march, an AO march, a light march, or a noise/FBM octave loop. Check what's accumulated.
- **A color that uses `n` or `iter`.** If it uses the normal, it's a debug/lighting; if it uses the iteration count, it's escape-time coloring or orbit-trapping.
- **A `sqrt` inside a loop, divided by another.** Likely a fractal DE.

## 27.5 The reverse-engineering write-up format

For every example (as the prompt specifies), produce a table:

| Step | Original code | Mathematical object |
|------|---------------|---------------------|
| Camera | `...` | $\mathbf o,\mathbf d$ |
| Ray | `...` | $\mathbf r(t)$ |
| Normalization | `...` | aspect/FOV |
| Transform `abs` | `...` | reflection fold |
| Transform `mod` | `...` | repetition |
| Primitive | `...` | cylinder/box/etc. |
| Iteration | `...` | fractal/light march |
| Lighting | `...` | model |
| Color | `...` | color mapping |
| Animation | `...` | $\mathbf c(t)$ |

Then: identify **hidden transformations** (e.g. a `.y` component reused as a coordinate), identify **approximations** (forward-difference vs. analytic normal, a non-conservative DE), and reconstruct the visual logic.

## Exercises

1. **(Process)** Identify the camera, ray, field, and normal for a provided fragment.
2. **(Translate)** Convert a `rot`/`mod`/`abs` chain into equations.
3. **(Identify)** Given a loop that accumulates a `min` of `d/(k*t)`, determine it's a soft shadow; reconstruct the math.
4. **(Derive)** For a fragment with `atan` + `mod`, derive the radial repetition and the number of arms.
5. **(Recognize)** Identify an orbit trap in a color function that tracks the minimum distance to a trap set.
6. **(Reverse engineer)** Given an unknown shader, step through the pipeline and describe the visual logic concisely.
