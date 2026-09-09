# Chapter 14 — Shadows and Ambient Occlusion

Shadows and ambient occlusion (AO) are what give a raymarched image its sense of depth and groundedness. Both are computed by *marching from the hit point*, which is possible precisely because we have a distance field. This chapter derives both.

## 14.1 Hard shadows

A point $\mathbf p$ on a surface is in **hard shadow** from a light at direction $\mathbf l$ if the ray from $\mathbf p$ along $\mathbf l$ hits geometry before reaching the light.

**Algorithm.** March a ray from $\mathbf p$ in direction $\mathbf l$. If it hits any surface at a parameter $t$ less than the distance to the light, the point is occluded:

```
hard shadow:
  t0 = bias
  t = t0
  for k in {0..N}:
      d = fshadow(p + t * l)
      if d < eps_s: return 0.0         # occluded
      t += d
      if t > lightDist: return 1.0     # reaches light
  return 1.0
```

**The bias.** Because the hit point $\mathbf p$ is only *approximately* on the surface (within $\varepsilon$), starting the shadow ray at $t=0$ could immediately detect self-intersection. A small bias $t_0$ (proportional to $\varepsilon$) offsets the start so the shadow ray doesn't hit the surface it just left.

**Self-shadowing.** The shadow ray must *not* occlude on the surface it originates from. This is precisely why the bias exists; without it, every point shadows itself.

## 14.2 Soft shadows: why distance fields enable them

Hard shadow is a binary test. **Soft shadows** smoothly interpolate from lit to shadowed, depending on how much geometry the light ray passes near. Distance-field soft shadows are built on the fact that a point that passes *close* to geometry should be *partially* occluded.

**The key quantity.** While marching the shadow ray, maintain the accumulated minimum of the ratio of the *field distance to the distance traveled so far*:

$$
\operatorname{shadow}=\min\left(\operatorname{shadow},\ \frac{d_{\text{current}}}{k\,t}\right),
$$

where $t$ is the march parameter (light distance) and $k$ is a **softness** parameter. By tracking *how close the ray has come* to geometry relative to how far it has traveled, we get a smooth occlusion factor.

**Why this quantity makes sense.** Consider the ray from $\mathbf p$ toward the light. At each step, the field value $d$ gives the distance to the nearest surface. If the ray passes very close to an occluding surface, then for that step $d$ is small *relative to* $t$, so $d/(k t)$ is small — signaling partial occlusion. If the ray stays far from all geometry, $d/(k t)$ stays near 1 across the whole path, and the point is fully lit. Taking the minimum over the path accumulates the *worst* (closest) approach, which is what determines the shadow softness.

**Derivation of the soft-shadow function.** The standard form (due to iq) is

$$
\operatorname{softshadow}(\mathbf p,\mathbf l)=\min_{t\in[0,T]}\frac{d(\mathbf p+t\mathbf l)}{k\,t}.
$$

with a $t$-dependent scaling to avoid the `1/0` at $t\to0$. The parameter $k$ controls how quickly the transition from lit to shadowed occurs.

**Geometric meaning of the accumulation.** The ratio $d/t$ is the "opening angle" of the shadow-casting occlusion: if the ratio is near 1, the occluder subtends a small angle; near 0, a large angle. So $k$ controls the light's **apparent radius**: larger $k$ → softer shadow (as if from an extended light source). This is exactly the physical intuition: soft shadows come from *area lights*.

**Numerical details.** A common approximation that avoids the near-0 $t$ divergence:

```
float softshadow(vec3 ro, vec3 rd, float k){
    float res = 1.0;
    float t = ... ; // small start, e.g. some bias
    for(int i=0;i<...;i++){
        float d = map(ro + rd*t);
        res = min(res, k*d/t);
        t += d;      // or t += clamp(d, ...);
        if(res<0.005 || t>maxT) break;
    }
    return clamp(res,0.0,1.0);
}
```

**Why `min` and not `luminance`.** The shadow factor is the *minimum over the path* because an occluder that the ray passes very close to, even briefly, should dominate — light blocked by a thin-but-close object is nearly fully occluded, whereas light blocked far away leaves only a partial shadow. The `min` captures "the worst occlusion along the path."

## 14.3 Soft shadow parameters and their meaning

| Parameter | Meaning | Visual effect |
|-----------|---------|---------------|
| $k$ (softness) | Scaling of $d/t$ | Larger $k$ → wider, softer penumbra. |
| $T$ (max light distance) | How far to march | Larger $T$ → more (and longer) occluders counted. |
| Step budget | Sparse march | Fewer steps → aliasing/banding in penumbra. |
| Start bias | Offset from surface | Avoids self-shadowing. |

**Analysis of artifacts.** A low step budget makes the soft-shadow function non-monotonic and causes **banding/aliasing** in the penumbra, because the march samples the occlusion at discrete points. Increasing steps or using a better march reduces this.

## 14.4 Ambient occlusion

**What AO approximates.** Ambient occlusion models the *amount of ambient (non-directional) light* that reaches a point, reduced by nearby geometry blocking the environment. On a surface point with outward normal $\mathbf n$, nearby protruding geometry occludes the hemisphere above the surface, reducing ambient light. AO is an approximation to the integral of visibility over the hemisphere above the point.

**The SDF-based AO.** March outward along the normal and accumulate the occlusion from nearby geometry:

```
float ao(vec3 p, vec3 n, float t0, float t1, float rad){
    float occ = 0.0;
    float s = 1.0;
    for(int i=0;i<...;i++){
        float d = t0*i / ...;   // sample distance from p along normal
        float sdf = map(p + n*d);
        occ += (d - sdf) * ...;   // how "buried" is this sample
        ...
    }
    return ...;
}
```

The standard form (iq) is

$$
\operatorname{AO}(\mathbf p)=\sum_{i}\frac{\text{occlusion measure at } d_i}{2^{i}},\qquad d_i\ \text{increasing},
$$

with the occlusion at sample $d_i$ computed as $\max(0,d_i - f(\mathbf p+\mathbf n d_i))$: a sample is occluded if the field value is *less than* the sample distance (meaning geometry is closer than the sample point). As $\mathbf p+\mathbf n d_i$ gets "buried" (field value small), the occlusion grows.

**How the geometry works.** At distance $d_i$ along the normal, the SDF value $f(\mathbf p+\mathbf n d_i)$ tells us how close the nearest surface is. If $\mathbf p+\mathbf n d_i$ is far from any geometry, $f$ is about $d_i$ (the point is in free space, no occlusion). If geometry protrudes up to the sample point, $f\approx0$ there — the sample is *on/near* geometry — so occlusion is high. The measure $\max(0, d_i - f)$ is the "inundation depth": how much the sample is below the local geometry.

**BIas.** A small bias subtracts from the occlusion so that the surface itself doesn't count; this prevents the AO from blackening the point that just cast the ray.

**Falloff and integration interpretation.** AO is a discrete approximation to an integral of *visibility* over the ambient hemisphere, weighted by occlusion with distance. The choice of the sample distances $d_i$ and the falloff (often $1/2^i$, i.e. an exponentially decreasing weight as you march farther) mirrors an integration over distance, with nearer occluders weighted more. This is why AO is strongest in creases and concave regions, where geometry is close on the sample side.

## 14.5 AO parameters and interpretation

| Parameter | Meaning | Visual effect |
|-----------|---------|---------------|
| $t_0$ (start offset) | First sample distance from surface | Avoids surface self-AO. |
| Samples / spacing | How many samples along the normal | More samples → smoother, costlier AO. |
| Falloff weight | $1/2^i$ | Near geometry dominates; far geometry fades. |
| Radius | How far to cast the AO rays | Larger radius → broader, softer GI look. |

**Approximation note.** SDF AO is a *heuristic* approximation to the ambient occlusion integral. It is not physically exact; it captures the *qualitative* darkening in concave regions and is a "visual hack" that happens to be well-motivated by the geometry. The book labels it as an APPROXIMATION.

## 14.6 Combining shadows and AO

Together:

- **Shadows** attenuate the directional light reaching a point, based on geometry between the point and the light.
- **AO** attenuates the ambient light reaching a point, based on nearby geometry around the point.

A typical shader computes:

```
float sh = softshadow(p, l, softness);
float ao = calcAO(p, n, ...);
vec3 color = albedo * (diffuse * sh + ambient * ao) + specular * sh ...
```

In raymarching, both are computed by marching from $\mathbf p$ using the same distance field, which is a huge advantage: no shadow maps, no precomputed AO, all analytic/per-pixel.

## Exercises

1. **(Derivation)** Derive the hard-shadow algorithm and explain the two termination conditions.
2. **(Derivation)** Justify the soft-shadow function $\min_t d(\mathbf p+t\mathbf l)/(k t)$, and explain the role of $k$.
3. **(Analytic)** Explain why the soft-shadow uses the *minimum* over the path and not an average.
4. **(Derivation)** Explain the AO occlusion measure $\max(0,d_i-f)$ geometrically.
5. **(Analytic)** Identify the trade-off between step count and penumbra banding in soft shadows.
6. **(Implementation)** Implement hard and soft shadows and AO on a simple scene; tune $k$ and the AO radius.
7. **(Design)** Use AO to darken concave creases (e.g. the junction between two spheres in a smooth union); describe the parameter that controls the crease-darkness.
