# Chapter 09 — Boolean Operations

Two signed distance fields can be combined into a new field representing a boolean combination of the two solids. This is constructive solid geometry (CSG). The three basic operations — union, intersection, difference — have exact SDF formulas. This chapter explains *why* they work, where they are exact, and where they are only bounds.

## 9.1 The basic operations

Let $A$ and $B$ be two solids with signed distance fields $d_A$ and $d_B$ (using the convention $d\le0$ is inside).

**Union:** $A\cup B$ has field
$$
d_{A\cup B}(\mathbf p)=\min\big(d_A(\mathbf p),\ d_B(\mathbf p)\big).
$$

**Intersection:** $A\cap B$ has field
$$
d_{A\cap B}(\mathbf p)=\max\big(d_A(\mathbf p),\ d_B(\mathbf p)\big).
$$

**Difference:** $A\setminus B$ has field
$$
d_{A\setminus B}(\mathbf p)=\max\big(d_A(\mathbf p),\ -d_B(\mathbf p)\big).
$$

## 9.2 Why union is `min` — a proof

**Claim.** If $d_A,d_B$ are exact signed distances, then $\min(d_A,d_B)$ is an exact signed distance for $A\cup B$.

**Proof.** The distance from $\mathbf p$ to $A\cup B$ is $\min(d(\mathbf p,A),d(\mathbf p,B))$... but we must be careful: the *signed* distance to the union is the signed distance to the nearer shape. For an exterior point, the distance to the union is the minimum of the distances to the two sets (the closer object). For an interior point of $A$, $d_A<0$ and represents the distance inside; the union's signed distance is $\min(d_A,d_B)$, which is the more negative of the two — i.e. the distance to the nearer boundary among all boundaries enclosing the point. If a point is inside both $A$ and $B$, $\min$ is the more negative, hence the distance to the nearest boundary (if that point is inside both, the nearest boundary is the closer of the two surfaces). Thus $\min$ correctly returns the signed distance to the union's boundary. $\blacksquare$

**Why `min` preserves the SDF property (Lipschitz).** The `min` of two 1-Lipschitz functions is 1-Lipschitz:

$$
\lvert\min(a,b)-\min(a',b')\rvert\le\max(\lvert a-a'\rvert,\lvert b-b'\rvert).
$$

So the union of two exact SDFs is an exact SDF, and its $\nabla$ norm is 1 almost everywhere — but it is *not* differentiable at the seam where $d_A=d_B$ (the "crease" where the two surfaces meet). At the seam the gradient of the union jumps between $\nabla d_A$ and $\nabla d_B$.

## 9.3 Why intersection is `max` and difference is `max(a,-b)`

**Intersection.** By complement/De Morgan duality, $A\cap B = \overline{\overline{A}\cup\overline{B}}$, and $\overline A$ has field $-d_A$. Hence

$$
d_{A\cap B}=\min(\text{-}d_A,\text{-}d_B)\cdot(-1)=-\min(-d_A,-d_B)=\max(d_A,d_B).
$$

**Difference.** $A\setminus B=A\cap\overline B$; plugging $\overline B=-d_B$ into the intersection formula:

$$
d_{A\setminus B}=\max(d_A,\ -d_B).
$$

**Interpretation.** Intersection takes the *larger* (less-negative) of the two fields — the point is inside the intersection only if it's inside both, so the distance to the intersection's boundary is the larger (closer to zero) of the two distances. Difference subtracts $B$: inside the result only if inside $A$ and outside $B$, which is what `-d_B<0` (i.e. $d_B>0$, outside $B$) enforces.

## 9.4 Continuity and differentiability

- **Exact booleans are $\mathcal C^0$.** They are continuous but generally not differentiable along the seams.
- The seams are the sets $d_A=d_B$. On these the *union* and *intersection* gradients are discontinuous, producing sharp creases (and hard specular edges) in the rendered image.

These seams are *real geometry* — the sharp intersection of two surfaces. They are desirable in many scenes.

## 9.5 Gradient discontinuities and artifact generation

Because the union/intersection fields are nondifferentiable along seams:

1. **Numerical normals** (central differences, Chapter 12) average the two branch gradients near the seam, producing a "smoothed" but slightly wrong normal over a 2-epsilon band. This creates a faint darkening or a "kink" band along the seam in the image.
2. **Color/material assignment** using a boolean is also discontinuous if you switch materials at the boundary, unless you smooth-blend them.

These are the "artifact generation" the prompt mentions. They are *approximations* of an underlying piecewise-smooth field.

## 9.6 Smooth boolean operations

To avoid the hard crease, we replace `min`/`max` with smooth counterparts. The most common family is the **smooth minimum** parameterized by a blend radius $k$. The idea: interpolate between `min` and a smooth "soft" function over a band of width $k$.

### 9.6.1 Polynomial smooth minimum (quadratic, iq)

Let $h=\operatorname{clamp}\!\Big(\tfrac{1}{2}+\tfrac{1}{2}\ \tfrac{b-a}{k},\ 0,1\Big)$. Then

$$
\operatorname{smin}(a,b,k)=\operatorname{mix}(b,a,h)-k\,h(1-h).
$$

**Derivation.** This is the minimum of $a$ and $b$ with a smooth $\mathcal C^1$ rounding of the corner over a transition band of half-width $k$. $h$ is a smoothstep-like weight that is $1$ when $a\ll b$ (so we pick $a$) and $0$ when $a\gg b$ (so we pick $b$); the term $-k\,h(1-h)$ is the bell-shaped "blend correction" that lowers the value slightly in the transition, rounding the crease into a smooth valley. The result is a $\mathcal C^1$ approximation to `min`, equal to `min` away from the band (for $|b-a|\ge k$).

**Exactness.** Smooth min is *not* an exact distance; it is an approximate field that is $< \min$ inside the band. It is generally a *distance bound* (or an *estimator*) — it underestimates the true distance, so it is safe for marching (never overshoots) but reduces step size near blends.

### 9.6.2 Exponential smooth minimum

$$
\operatorname{smin}(a,b,k)=-k\log_2\!\big(2^{-a/k}+2^{-b/k}\big).
$$

**Interpretation.** This is a "soft minimum" built from an exponential `LogSumExp`-like expression, giving a smooth, $C^\infty$ blend. It is a genuine soft-min (it is always $\le\min$ when $k>0$... actually $\le \min+a$ correction), and it is the most "blobby" — it never exactly recovers the sharp seam, which is good for organic shapes.

### 9.6.3 Power smooth minimum

$$
\operatorname{smin}_p(a,b)= \big(a^p+b^p\big)^{1/p},\quad p\to -\infty \Rightarrow \min,
$$

and for finite negative $p$ it is a smooth approximation. This generalizes because of the relationship between the $p$-norm and the "min" as $p\to-\infty$. Used when you want a controllable exponent.

### 9.6.4 Which to choose (comparison)

| Smooth op | Smoothness | Recovers `min` exactly? | Cost | Use case |
|-----------|-----------|------------------------|------|----------|
| Quadratic polynomial | $\mathcal C^1$ | Yes (outside band) | Low | General blends |
| Cubic polynomial | $\mathcal C^2$ | Yes | Low | Smoother normals |
| Exponential | $\mathcal C^\infty$ | No (blends everywhere) | Med | Organic/metaballs |
| Power | Varies | Yes | Low | Parameterized exponent |
| Circular | $\mathcal C^1$ | Yes | Med | Natural round blend |

## 9.7 Displacement-based blending and morphological operations

- **Offsetting (dilation/erosion).** $d(\mathbf p)-k$ (dilation by $k$) and $d(\mathbf p)+k$ (erosion by $k$) are *morphological* operations that keep the field an exact distance (if $d$ is exact). They correspond to Minkowski sum/difference with a ball. This is the basis of rounded boxes (§8.4), "onion"/"shell" hollowing, and thickness control.
- **Smooth union = dilation of a sharp union with a ball** in the region where the two surfaces are close — this is exactly why it is a *bound*: in the blend region the "rounded crease" surface is a Minkowski sum, which is exact, but the transition to the sharp region is only approximate — hence the careful statement of bounds.

## 9.8 The "onion" / "shell" operation

**Shell / onion.** Given a solid $d$ and thickness $t$, the hollow shell

$$
d_{\text{shell}}(\mathbf p)=\lvert d(\mathbf p)\rvert-t
$$

is the surface set within distance $t$ of the boundary. Note `abs(d)-t` is a *signed distance* to the pair of surfaces $d=\pm t$, but its interior is the shell region. This produces "onion" layers, hollow vessels, and in animation, a single object can be shelled repeatedly with KIFS (Chapter 16).

## 9.9 Exactness summary for booleans

| Operation | Exact SDF result? | Where | Safe bound? |
|-----------|-------------------|-------|-------------|
| Union (`min`) | Yes | Everywhere | Yes |
| Intersection (`max`) | Yes | Everywhere | Yes |
| Difference (`max(a,-b)`) | Yes | Everywhere | Yes |
| Smooth union (any) | Generally no | Blend band | Yes (it is $\le$ min) |
| Dilation/erosion | Yes | Everywhere | Yes |
| Shell (`abs`) | Yes | Everywhere | Yes |

The universal rule to remember: **`min` and `max` over exact SDFs preserve exact SDF (up to the seam's nondifferentiability); any *smooth* operation or *displacement* introduces approximation and must be re-checked against the taxonomy.**

## Exercises

1. **(Derivation)** Prove the union SDF is `min` and that min of two 1-Lipschitz functions is 1-Lipschitz.
2. **(Derivation)** Derive the intersection and difference formulas from the union formula via complementation/negation.
3. **(Analytic)** Where is the union's gradient discontinuous? Draw the crease set for two overlapping spheres.
4. **(Derivation)** Show that dilating by $k$ ($d\mapsto d-k$) is an exact distance (offset/tube property) for an exact $d$.
5. **(Implementation)** Implement `smin` (quadratic), `smax` (via $-smin(-a,-b)$), and a `smoothUnion` used on two spheres. Compare the crease.
6. **(Analytic)** Show that the exponential smooth min is $\mathcal C^\infty$ but does not exactly recover `min`; state the resulting field class (bound vs. estimator).
7. **(Design)** Use `abs(d)-t` (shell) plus a boolean to hollow a cube; describe the visual and the field class of the result.
