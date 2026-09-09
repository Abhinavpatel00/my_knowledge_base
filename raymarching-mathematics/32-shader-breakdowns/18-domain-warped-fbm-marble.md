# Shader Breakdown 18 — Domain-Warped FBM (iq): Marble, Lava, Clouds

Domain warping (Chapter 16) is the single most transformative procedural technique. iq's canonical "warping fBm" feeds one fBm field into the coordinates of another, producing swirling, marble-like, turbulent structure that looks far more complex than the underlying noise. This breakdown derives the two- and three-level warp and analyzes the resulting field class.

## 1. The fragment (reconstructed key parts)

```glsl
vec2 fbm2(vec2 p){ return vec2(fbm(p), fbm(p + 5.2)); }   // two-channel fBm

// two-level warp
float warp2(vec2 p){
    vec2 q = fbm2(p);                 // level 1: a displacement field
    return fbm(p + 2.0*q);            // level 2: warped fBm
}

// three-level warp (the famous "marble")
float warp3(vec2 p){
    vec2 q = fbm2(p);
    vec2 r = fbm2(p + 2.0*q);
    return fbm(p + 2.0*r);
}
```

## 2. Mathematics

### 2.1 The base fBm

The base object is Fractional Brownian Motion (Chapters 16, 17):
$$
\operatorname{fbm}(\mathbf p)=\sum_{i}a_i\,n(2^i\mathbf p+\text{offset}_i),\qquad a_i=\text{gain}^i.
$$
This is a smooth scalar field with a bounded derivative (a Lipschitz constant of order $\sum_i a_i 2^i$, roughly $\text{gain}^{-1}$-bounded). It has structure at many scales.

### 2.2 One-level warp

$$
W_1(\mathbf p)=\operatorname{fbm}\!\big(\mathbf p+\lambda\,\mathbf q\big),\qquad \mathbf q=(f_1(\mathbf p),f_2(\mathbf p)).
$$
The coordinates fed to the fBm are displaced by another fBm vector field $\mathbf q$. The map
$$
\mathbf p\mapsto\mathbf p+\lambda\mathbf q(\mathbf p)
$$
is a **coordinate transform** with Jacobian
$$
J=I+\lambda J_{\mathbf q}.
$$

### 2.3 Two- and three-level warp (the cascade)

$$
\mathbf q=\operatorname{fbm}_2(\mathbf p),\qquad
\mathbf r=\operatorname{fbm}_2(\mathbf p+2\mathbf q),\qquad
f=\operatorname{fbm}_2(\mathbf p+2\mathbf r).
$$
At each level, the *previous* field's output is used to displace the *next* field's input. This chained composition produces progressively more folded space. The growing Jacobian as you add levels is what makes the output look increasingly "turbulent."

**Why the Jacobian matters.** Each warp is a non-linear map whose Jacobian norm can be $>1$; with each level it can *increase*. A warp with $\lVert J\rVert>1$ folds space (non-injective), which is the source of both the *beautiful* marble-like folding and the *danger* of overestimating distance. Where space folds over itself, a scalar field can take multiple "sheets" and the geometry self-interpenetrates.

### 2.4 The field class

The warp is **not an isometry** (Chapter 10), so the composed field is a **bound/estimator**. For a *texture* (2D color), this doesn't matter — you're just evaluating a color, not marching a ray. But if you were to use a warped field as a *distance* for raymarching (e.g. a warped SDF), it would be a **bound**, and you'd need to bound $\lVert J\rVert$ (or scale the step by it) to stay safe. This is exactly the Chapter 10 lesson, made vivid.

## 3. The "thinking process"

1. **Ideas.** "I want marble/fluid/cloud-like texture." → fBm alone is too uniform.
2. **Warp.** "Feed one fBm's output into another's input." → coordinate displacement.
3. **Layer.** "Add more levels for more turbulence." → chain the warp.
4. **Amount.** "Control the swirl." → the warp strength $\lambda$ and the number of levels.

## 4. Field-class analysis

| Stage | Operation | Class |
|-------|-----------|-------|
| fBm | smooth scalar field | arbitrary scalar |
| warp map | $\mathbf p+\lambda\mathbf q$ | non-isometric |
| composed field | fBm of warped coords | bound/estimator (if used as distance) |

For a *texture* use, the class is irrelevant (you only need a color). For a *distance/SDF* use, the warp makes the field a bound/estimator and you must account for the Jacobian.

## 5. Extensions

- **Chained warps.** As above; each level adds folds. The famous iq fBm warping uses 3 levels.
- **Derivative warping.** Use *analytic* fBm gradients (Chapter 17) to both displace and get the warp's Jacobian, so you know how far the warp stretches space.
- **Time.** Animate the offset (e.g. `fbm2(p + t)`) so the marble flows; the motion is coherent because everything is smooth in time.
- **Domain-warp an SDF.** Warp the *input* of an SDF, then scale the step by $1/\sigma_{\max}(J)$ (Chapter 31a) to keep it safe.
- **Ridged warping.** Use `1-|noise|` in the fBm for ridge-like turbulence, or warp with a ridged fBm.

## Exercises

1. **(Derivation)** Derive the warp's Jacobian $I+\lambda J_{\mathbf q}$ and its spectral norm; state when it's non-injective.
2. **(Field class)** Classify the warped fBM and explain the distinction between texture use (color) and distance use (safety).
3. **(Derivation)** Write the 3-level cascade and explain the compounding Jacobian.
4. **(Analytic)** Explain why a warp $\lambda$ too large causes the field to fold (self-intersect), and the visual consequence.
5. **(Design)** Warp the input of an SDF and apply the safe-step factor.
6. **(Implementation)** Render a 3-level warped fBm marble texture with time.
