# Shader Breakdown 3 — Quilez's Smooth-Minimum Family (DD and CD)

The smooth minimum is the single most-used "soft boolean" in raymarching. Inigo Quilez published a family; this breakdown derives the **polynomial (CD)** family from first principles, compares the **exponential** and **sigmoid** (DD/D) forms, explains the connection to morphological offsetting, and extends them.

## 1. The goal

We want a function $\operatorname{smin}(a,b,k)$ that:

1. Approximates $\min(a,b)$ but is *differentiable* (at least $\mathcal C^1$, ideally $\mathcal C^n$),
2. Equals $\min(a,b)$ exactly when $|a-b|\ge k$ (away from the blend band),
3. Rounds the crease into a smooth transition over a band of width $k$,
4. Is a *conservative* field (approximation or bound) suitable for marching.

## 2. The polynomial (CD) family

The canonical **quadratic** smooth minimum (iq):

```glsl
float smin(float a, float b, float k){
    k *= 4.0;
    float h = max(k - abs(a-b), 0.0) / k;
    return min(a,b) - h*h*k*(0.25);
}
```

**Derivation.** Let $d=a-b$. Define $h=\operatorname{clamp}\big(\tfrac12+\tfrac12\tfrac{d}{k'},0,1\big)$ where $k'=k/4$ (the "4.0" scaling in the code absorbs a constant). The idea is to *interpolate* between $a$ and $b$ and *subtract a small amount* to round the corner. A clean way:

$$
\operatorname{smin}(a,b,k)=\operatorname{mix}(b,a,h)-k\,h(1-h).
$$

Here $h$ is a smoothweight (0 when $a\gg b$, 1 when $a\ll b$, i.e. it picks $b$ in the first case and $a$ in the second), and $-k\,h(1-h)$ is a negative **bell-shaped** correction that *lowers* the value near the center of the blend. Because $h(1-h)$ is a smooth parabola peaked at $h=1/2$, the correction is maximal at the midpoint and vanishes at the ends — exactly the rounding of the corner.

**Why the correction term.** Without it, `mix(b,a,h)` interpolates the values but the *junction* between the two branches is a sharp corner (non-differentiable). The $-k\,h(1-h)$ term makes the combination dip smoothly below the sharp corner, rounding it to a $\mathcal C^1$ (for the quadratic) or $\mathcal C^2$+ (for higher powers) curve.

**Order of smoothness.** The *quadratic* polynomial gives a $\mathcal C^1$ blend (the derivative is continuous). The *cubic* polynomial gives $\mathcal C^2$, the *quartic* $\mathcal C^3$, and so on. Higher-order polynomials are smoother but cost more and are only needed when the normals/shading would otherwise show a derivative discontinuity (a "kink").

**The code's scaling constants.** The factors (`k *= 4.0` for quadratic, `k *= 6.0` for cubic, `k *= 16/3` for quartic) normalize the blend width so that $k$ is the *half-width of the transition band*. Each family redefines $k$ so the blend spans a width proportional to $k$; the constants just make the effective band width match $k$ for the given polynomial degree.

## 3. The exponential smooth minimum

```glsl
float smin(float a, float b, float k){
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}
```

**Derivation.** This is a **LogSumExp**-style soft min. Since $\min(a,b)=-\max(-a,-b)$, and the LogSumExp $\log(e^{x_1}+e^{x_2})$ approximates $\max$, we get
$$
\operatorname{smin}_\text{exp}(a,b,k)=-k\log_2\!\big(2^{-a/k}+2^{-b/k}\big).
$$

**Properties.** It is $\mathcal C^\infty$ (infinitely smooth) — the most "liquid"/organic blend. But it **never exactly recovers $\min$** away from the band (it remains slightly below $\min$ for all $k$), so it "smears" the object everywhere. This makes it ideal for metaballs/goo (Chapter 16) but wrong when you need exact geometry with clean seams. It is a **bound** (it is $\le\min$), so it is safe for marching but reduces step size everywhere, not just at the seam.

## 4. The sigmoid / "DD" family

```glsl
float smin(float a, float b, float k){
    k *= log(2.0);
    float x = b-a;
    return a + x/(1.0 - exp2(x/k));
}
```

This is the "sigmoid"/rationale family. It is a smooth minimum derived from the logistic function and is $C^\infty$; it is a smooth interpolation with analytic derivatives. The "DD" family in iq's naming refers to a differential-geometry-friendly reparameterization that keeps the first two derivatives smooth while agreeing exactly with `min` outside the band.

## 5. The connection to morphological offsetting

The *sharp* union is $d=\min(a,b)$. Offsetting a union by a ball of radius $k$ (Minkowski sum) is the dilation
$$
d_{\text{dilation}}=\min(a,b)-k .
$$
The *smooth* union interpolates between the sharp union and the dilated union in the blend region. Concretely, the quadratic smooth min behaves like "dilate the union by $k$, but only in the transition band." This is exactly why it is a **bound**: it is a rounded version of the sharp union, which is a Minkowski sum locally, but its global field is only an approximation of the true distance (the rounding extends beyond the true offset in the transition region).

**The precise statement.** In the region where $|a-b|<k$, the smooth union is the distance to the *filleted* surface — a surface rounded at the intersection. Away from the band, it equals the sharp union. The fillet is the source of the *bound* character: at the fillet center the distance is slightly *less* than the true surface distance (it's inside the rounded region), so the field is conservative (safe) but not tight there — the marcher uses a slightly smaller step.

## 6. Field-class comparison

| Smooth min | Derivatives | Recovers `min` away from band? | Cost | Use |
|------------|-------------|-------------------------------|------|-----|
| Quadratic polynomial | $\mathcal C^1$ | Yes | Low | General |
| Cubic | $\mathcal C^2$ | Yes | Low | Smoother normals |
| Quartic | $\mathcal C^3$ | Yes | Med | Very smooth |
| Exponential | $\mathcal C^\infty$ | **No** | Med | Metaballs / organic |
| Sigmoid / DD | $\mathcal C^\infty$ | Yes | Med | Smooth + exact-seams |
| Circular | $\mathcal C^1$ | Yes | Med | "Natural" round fillet |

**The key caveat.** All smooth unions are fundamentally **approximations/bounds**, not exact SDFs, *even the ones that recover `min` away from the band*. In the blend band the field is a bound; the "recovers `min`" property only tells you the field is exact far from the seam. This is the rigorous reason to treat smooth unions as safe-but-conservative, and to expect slightly lower convergence speed near blends.

## 7. The thinking process

1. **Need.** "I want two shapes to melt together instead of meeting at a hard crease." → replace `min` with a smooth interpolation.
2. **Constrain.** "It must be differentiable." → use a smooth weight $h$ plus a bell-shaped correction that vanishes at the band's ends.
3. **Constrain.** "It must be an exact `min` away from the seam." → use a polynomial/family that returns exactly $\min$ for $|a-b|\ge k$.
4. **Constrain.** "It must be safe to march." → since it is $\le\min$ in the band, it's a bound → safe.
5. **Choose order.** "How smooth do the normals need to be?" → quadratic ($\mathcal C^1$) for most; cubic/quartic for smooth silhouettes; exponential for goo.

## 8. Extensions

### 8.1 Material blending with the weight
The smooth min naturally gives a *blend weight* $h$. By outputting $h$ you can blend *materials* (colors, roughness) across the joint. This is the `smin2` ("with mix factor") form that returns both the distance and the weight. **Order-dependence warning:** some forms are order-independent, others are not; for blending material you want the order-independent form so the result doesn't depend on the order of operations.

### 8.2 Smooth max and smooth difference
By symmetry,
$$
\operatorname{smax}(a,b,k)=-\operatorname{smin}(-a,-b,k),
\qquad
\operatorname{sdiff}(a,b,k)=\operatorname{smax}(a,-b,k).
$$
So all three boolean smooth ops come from one smooth-min. This is the standard way to implement smooth CSG.

### 8.3 Multi-input smooth min
The exponential form composes nicely: $\operatorname{smin}(a,b,c,k)=-k\log_2(2^{-a/k}+2^{-b/k}+2^{-c/k})$. This is exactly why the exponential form is used for multi-blob metaballs.

### 8.4 Tuning the blend for a specific look
- **Rounder** fillet → circular/exponential form (more "goo").
- **Sharp but smooth** → small $k$, quadratic.
- **Controlled ridge** (e.g. for a crease in a creature) → use a *negative* smooth min or a special "ridge" blend that pushes outward.

### 8.5 Performance-aware blend
The exponential and sigmoid forms use `exp`/`log` (expensive). The polynomial forms are cheaper (only abs/max/mul). On a GPU, **the polynomial form is both faster and often sufficient**, so it is the default in most raymarchers.

## Exercises

1. **(Derivation)** Derive the quadratic smooth min from `mix(b,a,h)-k h(1-h)` and show it's $\mathcal C^1$.
2. **(Derivation)** Derive the exponential smooth min from the LogSumExp formula and show it never exactly recovers `min`.
3. **(Derivation)** Show $\operatorname{smax}(a,b,k)=-\operatorname{smin}(-a,-b,k)$ and $\operatorname{sdiff}(a,b,k)=\operatorname{smax}(a,-b,k)$.
4. **(Analytic)** Explain why the smooth union is a *bound* and where a step would be conservative.
5. **(Analytic)** Compare the cost (transcendentals vs. polynomial) and the smoothness classes of the families.
6. **(Implementation)** Implement the quadratic and exponential smooth mins; use a two-sphere union and compare the crease.
7. **(Derivation)** Show the "with-material-weight" form gives an order-independent blend factor.
