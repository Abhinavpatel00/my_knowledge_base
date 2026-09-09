# Shader Breakdown 11 — iq's "Elastic": Soft Bodies, Soft Shadows, and AO

"Elastic" is a classic iq ShaderToy of a soft, elastic blob (a grid of spheres smooth-unioned) bouncing, with soft shadows and ambient occlusion. It is the canonical demonstration of the *soft-bodies + soft-shadow + AO* combination that defines the raymarched look — and it is a thorough exercise in the smooth min (Chapter 9), soft shadow (Chapter 14), and SDF AO (Chapter 14).

## 1. The fragment (reconstructed key parts)

```glsl
float map(vec3 p){
    quaternion-ish frame p = rot(p, time);
    float d = 1e9;
    int n = 5;
    for(int i=-n;i<=n;i++){
        vec3 c = vec3(float(i), 0.45, 0.45 + ... animated ...);
        d = smin(d, length(p-c) - r, 0.5);      // smooth-union many spheres
    }
    return d;
}

float softshadow(vec3 ro, vec3 rd, float k){  ... min(k*d/t) ... }
float calcAO(vec3 p, vec3 n){ ... }

void mainImage(...){
    ...
    float d = raymarch(ro, rd);
    vec3 n = normalize - finite diff;
    float sh = softshadow(p, l, 4.0);
    float ao = calcAO(p, n);
    ...
    float dif = clamp(dot(n,l),0,1);
    float amb = 0.5 + 0.5*n.y;
    vec3 col = skc * (dif*sh + amb*ao) + spec*sh*...
}
```

## 2. Mathematical formulation

### 2.1 The scene: a row of smooth-unioned spheres

Each sphere is a center $\mathbf c_i$ at an integer grid position, animated by a soft (damped) motion. The field is

$$
d(\mathbf p)=\operatorname{SMIN}_{k}\big(\ \lVert\mathbf p-\mathbf c_i\rVert-r\ \big),
$$

a **smooth union** (Chapter 9). The smooth min is what makes the run of spheres "melt" into a single elastic tube rather than a row of balls. Because smin is a **bound** (Chapter 9), the field is conservative — safe, but the marcher takes slightly smaller steps than an exact SDF.

### 2.2 The normal

Computed by central-difference or tetrahedral sampling (Chapter 12):
$$
\mathbf n=\operatorname{normalize}\ \nabla_{\varepsilon} d(\mathbf p).
$$

### 2.3 The soft shadow

$$
\operatorname{shadow}=\min_{t}\ \frac{d(\mathbf p+t\,\mathbf l)}{k\,t},
$$
with $k$ the softness. The march advances by the field value toward the light; the `min` over the path accumulates the "worst" occlusion. This is the exact soft-shadow model of Chapter 14 and Breakdown 4. The bias starting the march at a small $t$ avoids self-shadowing.

### 2.4 The ambient occlusion

$$
\operatorname{AO}=\sum_i \frac{\operatorname{occl}(d_i)}{2^i},\qquad
d_i\ \text{samples along }\mathbf n,
\qquad \operatorname{occl}(d_i)=\max\!\big(0,\ d_i-f(\mathbf p+\mathbf n d_i)\big).
$$
This darkens concave creases (where the smooth-union walls converge) and gives the characteristic "fluffy" shading at the base of the blob. It is an `APPROXIMATION` (Chapter 14).

### 2.5 The lighting

$$
\text{col}=\text{sky}\cdot\big(\text{dif}\cdot\text{shadow}+\text{amb}\cdot\text{AO}\big)+\text{spec}\cdot\text{shadow},
$$
where $\text{dif}=\max(0,\mathbf n\cdot\mathbf l)$, $\text{amb}=\frac12+\frac12 n_y$ (a hemisphere ambient), and spec is a Blinn-Phong/GGX highlight. The key points:

- **Diffuse** is attenuated by the **soft shadow** — so the parts of the blob the direct light can't reach (but ambient can) get the AO term.
- **Ambient** is attenuated by **AO** — so creases are darkened without needing a light-direction test.
- **Specular** is attenuated by the **shadow** — so a highlight never leaks into a shadowed region.

This factorization — directional light × shadow, ambient × AO — is the standard "fake global illumination" of raymarching (Chapter 13).

## 3. The thinking process

1. **Ideas.** "I want a soft, elastic, jelly-like object." → smooth-union spheres.
2. **Motion.** "It should bounce and squash." → animate the sphere centers with a soft (damped/spring) motion; each `smin` radius/animation is smooth in time (Chapter 22).
3. **Grounded.** "It must sit in the scene with soft shadows/contact darkening." → soft shadow (light) + AO (ambient).
4. **Material.** "It should look glossy/jelly." → speculare highlight (Blinn-Phong/GGX) × shadow, plus a Fresnel/Schlick rim.

## 4. Field-class analysis

| Stage | Operation | Field class |
|-------|-----------|-------------|
| sphere | $\lVert\mathbf p-\mathbf c\rVert-r$ | exact |
| smooth union | smin | bound |
| normals | finite diff | approximation |
| soft shadow | min of $d/t$ | approximation (occlusion heuristic) |
| AO | sum of occlusion | approximation |

So the *field* is a bound (from smin); the *lighting* is heuristic. Both are standard and safe: the field never overestimates distance (smin is conservative), so the marcher doesn't tunnel.

## 5. Extensions

- **Fissures/creases.** Use a *ridge*-like smin (negative blend) to draw sharp creases instead of round fillets.
- **Subsurface scattering.** Add a thickness-based translucent term (march *through* the blob and use the accumulated density as translucency). This is a "fake SSS" that gives the jelly its warm transmitted glow.
- **Anisotropic specular.** Use GGX (Chapter 13) with a roughness that varies across the blob (e.g. higher roughness toward the creases).
- **Dynamics.** Replace the hand-animation with a spring-mass or a simple physics integration, so the blob genuinely flexes.

## Exercises

1. **(Field class)** Classify the smooth-union field and explain why it's a bound.
2. **(Derivation)** Write the soft shadow and AO, and explain how they differ in their occlusion measure.
3. **(Derivation)** Derive the hemisphere ambient $\frac12+\frac12 n_y$ and the diffuse term.
4. **(Analytic)** Explain why specular is attenuated by shadow but ambient by AO.
5. **(Design)** Add a fake subsurface-scattering thickness term to the blob.
6. **(Implementation)** Implement the scene and vary the smin $k$; describe the transition from "row of balls" to "elastic tube."
