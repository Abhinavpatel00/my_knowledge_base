# Chapter 31a — Convergence Theory and Certified Distance Bounds

This is the graduate-level treatment of *why* sphere tracing converges and *how to certify* that an arbitrary procedural field is a safe distance bound. We state Hart's convergence theorem precisely, generalize it to the class of *signed distance function estimates* (SDFE), and give the operator-theoretic tools to compute Lipschitz constants for composite scenes.

## 31a.1 The exact statement of the sphere-tracing guarantee

Let $\Omega\subset\mathbb R^3$ be a closed set with signed distance $d$ (so $d<0$ inside, $d>0$ outside, $d=0$ on $\partial\Omega$), and let $\mathbf r(t)=\mathbf o+t\mathbf d$ with $\lVert\mathbf d\rVert=1$.

**Theorem (Hart, 1995 — convergence).** Suppose $d$ is $1$-Lipschitz on $\mathbb R^3$. Define the iteration
$$
t_0=0,\qquad t_{n+1}=t_n+d(\mathbf r(t_n)).
$$
Then:

1. If the ray intersects $\partial\Omega$, the sequence $\{t_n\}$ converges to the *first* intersection parameter $t_*$.
2. If the ray does not intersect $\partial\Omega$, the sequence diverges (so detection by a threshold $t>T_{\max}$ terminates it).

**Sketch of the two claims.** For (1): by the 1-Lipschitz property, $d(\mathbf r(t_n))\ge0$ and, as shown in Chapter 07, the interval $[t_n,t_n+d(\mathbf r(t_n))]$ cannot cross a solution. Hence $\{t_n\}$ is monotone non-decreasing and bounded above by $t_*$, so it converges to some $t_\infty\le t_*$. If $t_\infty<t_*$, then continuity gives $d(\mathbf r(t_\infty))>0$; but then a step from $t_\infty$ still moves forward, contradiction. Hence $t_\infty=t_*$. $\blacksquare$ (Claim (2) is immediate: if there's no intersection, $d$ stays positive and $t_n\to\infty$.)

**The essential hypothesis is 1-Lipschitzness.** The theorem uses *only* this, not the eikonal property $\lVert\nabla d\rVert=1$. So any 1-Lipschitz $d$ whose zero set is $\partial\Omega$ suffices. This is exactly why a *conservative bound* ($\hat d\le d$) works too: $\hat d$ is still Lipschitz and its step still cannot overstep (it just undershoots). This is the rigorous basis for the taxonomy of Chapter 06.

## 31a.2 Signed distance function estimates (SDFE)

The taxonomy's "distance bound" row can be formalized. A **signed distance function estimate** (SDFE) is a function $f$ such that there exists a pointwise bound
$$
\lvert f(\mathbf p)\rvert\le d(\mathbf p,\partial\Omega)
$$
up to a controlled constant, generalizing the notion so that CSG operations remain closed. This is the formalism of Bálint (2023).

**The practical relevance.** Many community SDFs — smooth-min blends, displacement, domain-warped fields, fractal DEs — are *not* exact distances but are SDFEs. The new theoretical content is that the *class* of SDFEs is large and, crucially, **closed under the CSG operations**. That is, a CSG tree built from SDFE primitives with `min`/`max` (and certain smooth operations) is still an SDFE, so sphere tracing still converges — just possibly with loss of "tightness" (precision) at seams and interior regions.

**Why this matters for the practitioner.** You can compose a scene from *approximate* pieces and trust convergence, but you must quantify the *precision loss*. For intersection (`max`) the resulting estimate is "as precise as the least precise argument *inside* the intersection," while on the *exterior* the precision can degrade substantially. This is the formal version of the "smooth union is a bound, sharper away from the blend" intuition.

## 31a.3 The operator-theoretic Lipschitz bound

The core computational tool, already foreshadowed in Chapter 10, is:

**Proposition (composition bound).** Let $T:\mathbb R^3\to\mathbb R^3$ be differentiable with Jacobian $J_T$ and let $d$ be differentiable with $\lVert\nabla d\rVert\le1$. Then
$$
\lVert\nabla(d\circ T)\rVert
\le\lVert J_T^T\rVert_{\mathrm{op}}\ \lVert\nabla d\rVert
=\sigma_{\max}(J_T),
$$
where $\sigma_{\max}(J_T)$ is the **spectral norm** (largest singular value) of $J_T$.

**Derivation.** The chain rule gives $\nabla(d\circ T)=J_T^T\nabla d(T)$. Taking norms and using the definition of the operator (spectral) norm,
$$
\lVert J_T^T\nabla d\rVert\le\lVert J_T^T\rVert_{\mathrm{op}}\,\lVert\nabla d\rVert\le\sigma_{\max}(J_T)\cdot1.
$$

**Consequence.** If $\sigma_{\max}(J_T)\le1$ everywhere, then $d\circ T$ is $1$-Lipschitz — a *certified* safe bound (and exact if $T$ is an isometry, i.e. $\sigma_{\max}=\sigma_{\min}=1$). If $\sigma_{\max}(J_T)>1$ somewhere, the safe step is $(d\circ T)/\sigma_{\max}$. This is a *pointwise* certificate; we can compute it globally by bounding $\sigma_{\max}$ over the relevant region.

**Computing $\sigma_{\max}$ for the classic transforms.** For a diagonal matrix $\operatorname{diag}(s_1,s_2,s_3)$, $\sigma_{\max}=\max_i|s_i|$ (non-uniform scaling). For a shear, $\sigma_{\max}=\sqrt{1+\lambda^2+|\lambda|}$ type expression. For a twist $\theta=k\,y$, the Jacobian has rows that grow like $k\,\lVert\mathbf p_{xz}\rVert$, so $\sigma_{\max}\sim\sqrt{1+(k\lVert\mathbf p_{xz}\rVert)^2}$ — the field is a bound whose safety factor degrades with distance from the axis.

## 31a.4 Certified bounds via automatic differentiation

For a scene that is a *computation* (a composition of primitives, transforms, and booleans), the Lipschitz constant can be certified by propagating forward **bounds on the Jacobian's operator norm** alongside the field value. This is the basis of **Segment Tracing** (Keinert et al.), which computes a *local* Lipschitz bound over a segment to improve the step.

**The technique.** Rather than a single global Lipschitz constant, track, for each "cell" or each segment of the ray, a bound on $\lVert\nabla d\rVert$ over that region. Then the safe step over the segment is $d/L_{\text{local}}$ with $L_{\text{local}}$ the *local* bound. Because many fields are nearly 1-Lipschitz locally (they only stretch in a few places), this gives much larger steps than a conservative global constant.

**The general certification algorithm.** For each primitive, record a Lipschitz constant (e.g. sphere = 1, box = 1, plane = 1). For each compositor, compute the composite bound:

- `min`/`max`: $\lVert\nabla\min(a,b)\rVert\le\max(\lVert\nabla a\rVert,\lVert\nabla b\rVert)$ (the gradient of the min/max is one of the two).
- `+`: $\lVert\nabla(a+b)\rVert\le\lVert\nabla a\rVert+\lVert\nabla b\rVert$ (triangle inequality).
- A transform $T$: multiply by $\sigma_{\max}(J_T)$ (the composition bound).
- A displacement $+g$: add $\lVert\nabla g\rVert$ (usually a known bound, e.g. $\sigma_{\max}(J_g)$).

These compose to give a *certified* bound $L(\mathbf p)$ for the whole scene, and the safe step is $d(\mathbf p)/L(\mathbf p)$ — a pointwise-conservative, locally-adaptive step. This is the mathematically *correct* answer to "how do I keep a warped/booleanded scene safe?" and it is far tighter than a global constant.

## 31a.5 The "safe-step" inequality, precisely

Let $L$ be a pointwise-certified Lipschitz field bound: $\lVert\nabla d(\mathbf q)\rVert\le L$ for all $\mathbf q$ in a ball of radius $\rho$ around the current point. Then, for a unit ray, the surface cannot be closer than $d(\mathbf p)/L$ in the direction of travel. The proof is the mean-value inequality applied over the segment, exactly as in Chapter 07 but with $L$ replacing $1$:

$$
\lvert d(\mathbf r(t_*))-d(\mathbf r(t))\rvert\le L\,(t_*-t),
\qquad d(\mathbf r(t_*))=0\ \Rightarrow\ d(\mathbf r(t))\le L(t_*-t).
$$

So the largest safe step is $d/L$.

## 31a.6 Convergence rate and step count

The convergence rate of sphere tracing is **linear** (a fixed-point iteration on a Lipschitz map), not quadratic like Newton's method. The typical behavior near the surface is geometric with a ratio that depends on how fast the surface "blows up" the field's variation. This is precisely why, once close to the surface, adding more iterations yields diminishing returns — which is why a bounded step budget plus a tolerance $\varepsilon$ is the right design, and why *adaptive* refinement (bisection near the surface) is better than extra sphere-tracing iterations.

**The quantitative gap.** If the field is a bound with $L>1$, the *number* of steps grows (linearly) with $L$; but the *geometric convergence ratio* also degrades. So a poorly-bounded field is both slower per step and slower to converge — the double penalty.

## 31a.7 Summary of the certified-bounds toolkit

| Tool | Result |
|------|--------|
| Hart's theorem | 1-Lipschitz ⇒ converge to first hit / diverge |
| SDFE closure (Bálint) | CSG of SDFEs is an SDFE (converges, precision loss) |
| Composition bound | $\Vert\nabla(d\circ T)\rVert\le\sigma_{\max}(J_T)$ |
| Segment/local Lipschitz | adaptive $L(\mathbf p)$, larger steps |
| min/max bound | $L\le\max(L_a,L_b)$ |
| sum bound | $L\le L_a+L_b$ |
| Safe step | $d(\mathbf p)/L(\mathbf p)$ |

## Exercises

1. **(Proof)** Prove the full Hart convergence theorem, being careful about the "no intersection ⇒ divergence" case.
2. **(Derivation)** Derive the composition bound using the chain rule and the spectral norm.
3. **(Derivation)** Review the Shearing/twist Jacobian and compute $\sigma_{\max}$; state the certified safe-step factor.
4. **(Analytic)** Sketch why a CSG tree of SDFEs is an SDFE, and identify where precision is lost.
5. **(Implementation)** Implement a forward-certification that propagates a Lipschitz constant through a scene of primitives, transforms, and booleans; use it to set an adaptive step.
6. **(Design)** Compare a globally-conservative step $d/L_{\text{global}}$ vs. a locally-certified step $d/L(\mathbf p)$; argue the local one needs fewer steps.
