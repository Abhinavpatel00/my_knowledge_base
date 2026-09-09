# Shader Breakdown 4 — Quilez's Soft Shadow and the Gradient Distance Bound

This breakdown derives the classic soft-shadow formula from its geometric meaning, analyzes the `f/|∇f|` gradient distance estimate, and connects the two to the "penumbra" artifact.

## 1. The soft-shadow formula

The canonical soft shadow (iq):

```glsl
float softshadow(vec3 ro, vec3 rd, float k){
    float res = 1.0;
    float t = 0.01;
    for(int i=0;i<<;i++){
        float d = map(ro + rd*t);
        res = min(res, k*d/t);
        t += d;
        if(res < 0.001 || t > 100.0) break;
    }
    return clamp(res, 0.0, 1.0);
}
```

## 2. Derivation from the occlusion-angle intuition

Consider a point $\mathbf p$ on the surface, a light direction $\mathbf l$, and a ray from $\mathbf p$ toward the light. Let $t$ be the arc-length traveled and let $d$ be the distance field at the current point. **The quantity $d/t$ is (a scaled) tangent of the angle the ray must turn to just graze the nearest occluder.** If at some point the occluder subtends a large angle (the ray passes very close to geometry), then $d/t$ is small; if the ray stays far from all geometry, $d/t\approx1$. So

$$
\operatorname{shadow}(\mathbf p,\mathbf l)=\min_{t}\ \frac{d(\mathbf p+t\mathbf l)}{k\,t}
$$

approximates the *fraction of the light's solid angle that is unoccluded* by nearby geometry. The minimum over the path picks out the closest pass — the dominant occluder — which is exactly the physically relevant quantity for a hard-edged but soft-ashed shadow.

**Why `min` and not an average.** A thin object passing very close to the ray's path occludes a large fraction of the light (it "chokes" the beam) even though it only overlaps a small stretch of the path. The `min` captures this: it's the *worst* occlusion along the way. Physically, this is a first-order model of penumbra from a light of angular radius $\propto k$; it is an **APPROXIMATION**, not the exact area-light integral.

**The parameter $k$. Increasing $k$** makes the shadow's penumbra wider (softer) — as if from a larger light source. **Decreasing $k$** sharpens it. This is the "light radius" parameter discussed in Chapter 14.

## 3. The bias and the divergence near $t=0$

The ratio $d/t$ diverges as $t\to0$ (if $d>0$). The *start* of the march (`t = 0.01`) and the term `k*d/t` keep this finite. But more importantly, the point $\mathbf p$ is only *approximately* on the surface (within $\varepsilon$), so starting at $t=0$ would put the shadow marshal's ray immediately inside the surface it just left — **self-shadowing**. The small start offset is the **bias**.

**The bias is a subtle trade-off.** If too large, you miss real shadows (the ray is pushed past the true shadow-casting occluder). If too small, you get self-shadowing acne. The correct bias is proportional to the marching tolerance $\varepsilon$ and to the field's local Lipschitz behavior.

## 4. The banding artifact and its cause

Because the shadow is a `min` over a *discretely sampled* path, the value jumps between discrete samples as you move a pixel. This produces **banding/rings** in the penumbra — a numerical artifact of undersampling the path. Two fixes:

1. **More samples** (finer march) — reduces banding but costs more.
2. **Smoother accumulation** — e.g. limit how much `res` can change per step, or use a smoothed min. This trades a bit of sharpness for a cleaner gradient.

This is a direct example of the numerical-analysis principle of Chapter 24: the *field* is fine; the *sampling* of the path introduces the artifact.

## 5. The `f/|∇f|` gradient distance bound

A closely related technique is the **gradient distance estimate** (iq, Chapter 31b):

$$
\hat d(\mathbf p)=\frac{f(\mathbf p)}{\lVert\nabla f(\mathbf p)\rVert}.
$$

This is used to (a) render an implicit field with *uniform thickness* (dividing by $\lVert\nabla f\rVert$ before coloring), and (b) as a first-order *distance* for a non-distance field.

**Why it appears in soft shadows.** The same principle — "how far can I go before the field changes by $f$?" — is the basis for using `d` in the soft-shadow step and for the `k*d/t` term. The soft shadow's `d/t` is literally a gradient-normalized quantity in disguise: the safe approach to the shadow-casting occluder is governed by how fast the field changes relative to how far you've gone.

**The failure mode.** If $\lVert\nabla f\rVert>1$, the field *overestimates* the step, so `d` in the shadow march can be too large and the shadow ray can tunnel past an occluder — a "leaky" shadow. To keep it correct, use a *scaled* step $d/L$ (with $L\ge\lVert\nabla f\rVert$) in the shadow march, as in Chapter 31a.

## 6. The "thinking process"

1. **Need.** "I want shadows with soft, gradual edges instead of hard binary cuts." → the binary hard-shadow test must be replaced with a *continuous* occlusion measure.
2. **Geometric intuition.** "How much of the light's disk does the nearest occluder block?" → the closer the ray passes to geometry, relative to how far it's traveled, the more it blocks. So accumulate `min(d/t)`.
3. **Parameterize.** "How soft? how far does the penumbra extend?" → the $k$ parameter sets the effective light radius.
4. **Numerical.** "How do I avoid self-shadowing and banding?" → bias the start, and sample densely / smooth the accumulation.

## 7. Extensions

### 7.1 Better soft shadows via a quadratic-friendly form
A refinement computes `res = min(res, ...)` using a *smooth* function of the distance, or accumulates a look-ahead so the min doesn't fall into a deep local hole. This improves the penumbra gradient.

### 7.2 Distance-based AO and combined shadow
The same "march along a direction and accumulate occlusion" framework gives AO (march along the normal; accumulate the "buried" amount). Combining shadow (march toward light, accumulate `min(d/t)`) and AO (march along normal, accumulate `max(0, t-d)/...`) is the standard precomputed-free occlusion model.

### 7.3 Use the gradient distance bound for thickness
For a field like `f = p.y + sin(p.x)`, dividing by `|∇f|` before the `smoothstep` threshold gives a uniform-thickness band. This is the direct application of the gradient estimate, and it removes the "variable thickness" artifact of naive implicit coloring.

### 7.4 Anisotropic / soft-area-light shadows
To model an *area light*, sample the shadow toward several directions around the light and average. This is a Monte-Carlo approximation of the true area-light shadow and is the physically-motivated extension, at higher cost.

### 7.5 Contact hardening
A fancier approach mixes the sharp and soft shadow based on distance (the "contact hardening" model of Wyman & Parker). It is a *heuristic* that blends $k$ with distance to make near contact shadows sharp and far shadows soft.

## Exercises

1. **(Derivation)** Derive the soft-shadow objective $\min_t k\,d(\mathbf p+t\mathbf l)/t$ from the occlusion-angle intuition.
2. **(Analytic)** Explain the `min` vs. average choice and why an occluder at a single close point should dominate.
3. **(Derivation)** Derive the gradient distance estimate $\hat d=f/\lVert\nabla f\rVert$ and state when it's exact.
4. **(Analytic)** Identify the origin of the penumbra banding and the two remedies.
5. **(Derivation)** Explain the self-shadowing bias trade-off and how to set it relative to $\varepsilon$.
6. **(Implementation)** Implement the soft shadow; vary $k$ and observe the penumbra sharpness.
7. **(Design)** Extend to a *two-sample area-light* shadow and compare the cost/quality vs. the single-sampled soft shadow.
