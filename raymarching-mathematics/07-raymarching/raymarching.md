# Chapter 07 — Raymarching

This chapter derives the ray-marching algorithm from first principles. We begin with the ray, state the intersection problem, explain why generic root-finding is hard, and then derive sphere tracing from the 1-Lipschitz property of distance fields. The safety guarantee, the termination conditions, and the failure modes are all consequences of that derivation.

## 7.1 The ray equation

A ray from a camera origin $\mathbf o\in\mathbb R^3$ in the unit direction $\mathbf d$ is

$$
\mathbf r(t)=\mathbf o+t\mathbf d,\qquad t\ge0,\qquad \lVert\mathbf d\rVert=1 .
$$

Because $\lVert\mathbf d\rVert=1$, the parameter $t$ measures **arclength**: the point $\mathbf r(t)$ is exactly $t$ units from $\mathbf o$ along the ray. (This is not a convention we may ignore — the whole safety argument in §7.4 assumes it.)

**Interpretation.** As $t$ advances from $0$, $\mathbf r(t)$ sweeps a half-line. The set $\{\mathbf r(t):t\ge0\}$ is the set of points the camera ray visits in order.

## 7.2 The intersection problem

Given a signed distance field $d:\mathbb R^3\to\mathbb R$ with surface $d=0$, find the **first** $t\ge0$ with

$$
d(\mathbf r(t))=0.
$$

Equivalently, define the scalar function of the ray parameter,

$$
g(t)=d(\mathbf o+t\mathbf d).
$$

We want the smallest nonnegative root of $g$. This is a 1D root-finding problem, but it is not an ordinary one.

## 7.3 Why generic root-finding is hard here

For procedurally generated geometry, we cannot rely on the standard tools:

- **No closed form.** $g$ is not a low-degree polynomial; it is the composition of many nonlinear operations (booleans, domain warps, repetitions, fractal iteration). There is no algebraic expression to solve.
- **Many roots.** The ray can cross the surface many times (a mineral cave, a fractal, an interlaced lattice). We want the *first* crossing, which is the most delicate to find — Newton's method happily finds some later root.
- **Grazing/oscillation.** Thin features, near-tangent rays, and high-frequency displacement make $g$ oscillate rapidly. Newton's method and bracketing can skip over a thin crossing entirely.
- **No derivative.** We can compute $d$, but we may not have a clean formula for $d'$. Finite-difference derivatives are noisy, and also expensive inside a loop.

These are the failures of *general* root-finding. The remedy is to exploit a property we *do* have: the 1-Lipschitz (or bounded) nature of the distance field.

## 7.4 Deriving sphere tracing from the 1-Lipschitz property

This is the central derivation of the book. We need the following guarantee:

> **Claim.** If $d$ is 1-Lipschitz, then along a unit ray, the surface cannot be closer than $d(\mathbf r(t))$ in the direction of travel. So we may advance the parameter by exactly $d(\mathbf r(t))$ without overshooting any solution.

**Proof.** Suppose the ray hits the surface at some parameter $t_*>t$. That is, $d(\mathbf r(t_*))=0$. Consider two parameters $t$ and $t_*$. The corresponding points are $\mathbf r(t)$ and $\mathbf r(t_*)$, which are a distance $\lVert\mathbf r(t_*)-\mathbf r(t)\rVert=\lvert t_*-t\rvert$ apart (because the ray is unit-speed). By the 1-Lipschitz property,

$$
\lvert d(\mathbf r(t_*))-d(\mathbf r(t))\rvert\le\lVert\mathbf r(t_*)-\mathbf r(t)\rVert=t_*-t .
$$

Since $d(\mathbf r(t_*))=0$ and $d(\mathbf r(t))>0$, this gives

$$
d(\mathbf r(t))\le t_*-t,
$$

i.e. the surface is at least $d(\mathbf r(t))$ farther along the ray. Therefore advancing to $t+d(\mathbf r(t))$ cannot pass the surface. $\blacksquare$

This is exactly the guarantee of **sphere tracing** (Hart, 1995). The name comes from the geometric picture: at each step, the value $d(\mathbf r(t))$ defines a sphere of that radius centered at $\mathbf r(t)$, and the sphere is guaranteed to contain no surface point:

```text
        ray
  o ---*-----*-----*-------SURFACE
        \     \     \
         \     \     \   each step is a sphere of radius
          \     \     \  d(point) that is empty of geometry
           \     \     \
            step  step  step
```

## 7.5 The sphere-tracing iteration

Initialize $t_0=0$. Repeatedly

$$
t_{n+1}=t_n+d(\mathbf r(t_n)).
$$

Terminate when either $d(\mathbf r(t_n))<\varepsilon$ (hit), $t_n>T_{\max}$ (missed), or $n$ exceeds a step budget. The sequence $t_n$ is strictly increasing (as long as the field is positive) and, by §7.4, always stays strictly below the first crossing. In the limit, $t_n$ converges to the first root.

**Pseudocode.**

```
t = 0
for n in 0..MAX_STEPS:
    p = o + t*d
    delta = d(p)
    if delta < EPS: return t      # hit
    t = t + delta
    if t > FAR:      return far   # miss
return far                        # budget exceeded
```

## 7.6 Why the step can be large — the "unbounding sphere"

The single number $d(\mathbf r(t))$ is simultaneously a *lower bound* on remaining distance and a *safe step*. There is a tension: a step this large is only valid because the field is a *distance*, not merely an implicit function. If the field measures "signed distance to the surface," then the step is both large (fast) and safe (correct). If the field is only an *estimator* that overestimates distance somewhere, the step is no longer safe.

This is the precise mathematical content of the distinction between an exact SDF and an estimator in the taxonomy (Chapter 06): **the estimator is safe only insofar as it never overestimates the true distance.**

## 7.7 The roles of the parameters

- **$\varepsilon$ (epsilon, hit threshold).** When $d<\varepsilon$ we declare a hit. $\varepsilon$ sets the *spatial accuracy* of the surface estimate. Too large → the surface is visibly chunky; too small → the marcher iterates an extra step or two near the surface (expensive) and can suffer from numerical noise (finite precision). Typical $\varepsilon$ is $1$–$10\times10^{-4}$ in scene units.
- **$T_{\max}$ (maximum distance).** A ray that reaches $T_{\max}$ without a hit has missed the scene. If the scene is unbounded (infinite corridors, tiled worlds) $T_{\max}$ is just a practical cutoff so the loop terminates.
- **$N_{\max}$ (maximum steps).** Bounded step count bounds worst-case GPU cost. It is *required* in GLSL because the compiler needs a constant loop bound; the `break` on $t>T_{\max}$ is an early-out.

## 7.8 Why the budget and step quality interact

The number of steps to reach a surface is, roughly,

$$
N\approx\int\frac{dt}{d(\mathbf r(t))}
$$

for the relevant stretch. A field with a large, correct value at each point gives few steps; a field that frequently returns near-zero values (fine as a *bound* but "stingy") gives many steps. The worst case is a field that is *correct but tiny* everywhere — then $d$ is small, steps are small, and the algorithm is slow. This trade-off between correctness and speed is central to Chapter 25.

## 7.9 Failure modes and their analysis

| Failure | Cause | Remedy |
|---------|-------|--------|
| **Overshoot / tunneling** | Field overestimates distance (an estimator that is not a bound, $L>1$). | Use a *true* bound; if you must use an overestimate, scale it down by some factor, accepting extra steps. |
| **Grazing miss (thin feature)** | Ray passes very close to a thin structure; $d$ stays positive but small, and $\varepsilon$ may be too large to register a hit, or the step is small so the ray "leans" past. | Reduce $\varepsilon$; consider narrower step over the critical stretch; or use a smaller Lipschitz-safe scale factor on the field. |
| **Near-surface oscillation** | Near a wedge/crease the field is $\mathcal C^0$ and the numerically estimated value jitters, so the marcher alternates between hit and no-hit. | Use an epsilon band and a "clamp" of $d$ to a small positive floor so $t$ strictly increases. |
| **Budget exhaustion** | The scene needs more steps than allowed. | Raise budget (cost), or improve the field to give larger steps (better bound), or accept a "far" miss. |
| **Float precision** | In large scenes, $t$ large, $p=o+t d$ loses precision, so the field's error exceeds $\varepsilon$. | Re-center coordinates near the camera (reduce $|t|$), use `T_MAX` modest, or reparameterize. |

## 7.10 Adaptive epsilon and termination nuance

A **fixed** $\varepsilon$ is a compromise: close to the camera, a small $\varepsilon$ is overkill; far away, a fixed $\varepsilon$ is not enough. Many marchers use an **adaptive** threshold associated with the ray parameter, e.g.

$$
\varepsilon(t)=\varepsilon_0(1+k\,t),
$$

so that the tolerance grows proportionally with distance — reflecting the fact that a tiny surface detail far away is sub-pixel and not worth resolving. This is a heuristic, not a derived optimum, but it reduces step count dramatically in deep scenes. The term $k$ is a "tolerance slope" tuned per scene.

## 7.11 What happens if the field is not a distance

The derivation in §7.4 used **only** the 1-Lipschitz property. If the field is

- an **exact** SDF → safe, maximum speed;
- a **distance bound** $\hat d\le d$ → safe (it never under-steps below the true bound), but may take more steps;
- an **estimator** overestimating somewhere → **not safe**, can tunnel;
- an **arbitrary** scalar field → **no guarantee at all**.

In practice we often accept the risk of estimators (fractals) and mitigate with a scale factor or by clamping the field to be conservative. The book is explicit about which of these is happening at every point.

## 7.12 Refining the intersection

Once the marcher finds a small $d$, the parameter $t$ is close to the root but not exact. Standard practice:

- **Binary refinement / bisection.** Once inside a bracket $[t_a,t_b]$ where the sign of the field (or the magnitude) brackets the surface, run a few bisection iterations to converge to high precision.
- **Newton on the estimate.** With a good normal, one Newton step $t\leftarrow t-d(\mathbf r(t))/(\partial g/\partial t)$ can polish the intersection, at the cost of a derivative (Chapter 12).

The intersection point is then $\mathbf p=\mathbf r(t)$, and it is handed to the normal and lighting stages.

## Exercises

1. **(Derivation)** Reproduce the proof in §7.4 that a unit ray cannot be advanced past the first solution when the field is 1-Lipschitz.
2. **(Derivation)** Show that if the field instead satisfies $\lvert d(\mathbf p)-d(\mathbf q)\rvert\le L\lVert\mathbf p-\mathbf q\rVert$ for a general $L$, then the safe step is $d/L$. Conclude that $L>1$ requires shrinking steps; $L<1$ (a "bound") is safe but slow.
3. **(Derivation)** Give the monovariant guarantee that $t_n$ is strictly increasing and bounded above by the first root, so the iteration converges.
4. **(Implementation)** Implement the sphere-tracing loop in GLSL; explain how each of $\varepsilon$, $T_{\max}$, $N_{\max}$ appears and why a `const` loop bound is needed.
5. **(Analytic)** Analyze the step count $N\approx\int dt/d$ for a sphere of radius $r$ viewed at distance $L$ from its center. How does $N$ scale with $L/r$?
6. **(Design)** A field is a distance estimator that overestimates the true distance by up to 20% somewhere. What can you do to keep the march safe without losing much speed? Give the scale factor and the resulting worst-case speed penalty.
