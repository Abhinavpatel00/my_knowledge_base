# Chapter 25 — Performance

A raymarched shader is executed millions of times per frame. Performance is not about "keeping code fast" as a slogan — it is a *cost model* you can compute. This chapter treats performance mathematically and shows why small changes in step count multiply into massive GPU workloads.

## 25.1 The cost model

The dominant cost of a raymarched scene is

$$
\text{cost}\approx\text{pixels}\times\text{steps}\times\text{scene-evaluation cost}.
$$

Each factor is a number we can reason about:

- **pixels** = `iResolution.x * iResolution.y`. Fixed by resolution.
- **steps** = the number of field evaluations per ray (the sphere-tracing loop count, or the light/AO march counts). Determined by the *distance function quality* and the *termination logic*.
- **scene-evaluation cost** = the number of operations per field call (primitives, transforms, booleans, fractal iterations).

## 25.2 Why step count dominates — the arithmetic

Consider a single scene field call costing $C_f$ operations on the GPU. One frame renders $P$ pixels, each tracing $N_{\text{steps}}$ and maybe a shadow/AO pass. The total field evaluations per frame is roughly

$$
\text{eval}\approx P\cdot\big(N_{\text{step}}\cdot(1+N_{\text{light}}+N_{\text{ao}})\big).
$$

**Worked example.** For a `1920 × 1080` frame, $P\approx 2.07\times10^6$ pixels.

With $N_{\text{step}}=100$ steps and no shadows/AO, evaluations $\approx 2.07\times10^8$ per frame. At 60 fps that's $\approx1.2\times10^{10}$ evaluations/second. Each evaluation runs a field function that might cost $100$–$1000$+ operations (with a fractal it's much more). So **the step count is the single most controllable driver of cost.**

## 25.3 The comparison: 100 steps vs. 40 steps

$$
\text{cost}(100\text{ steps})=P\cdot 100\cdot C_f,\qquad
\text{cost}(40\text{ steps})=P\cdot 40\cdot C_f .
$$

The ratio is $100/40=2.5$. So **cutting the step count from 100 to 40 cuts the total cost to 40%** — a 2.5× speedup — purely by reducing the average march length. This is why tuning the *field* (better distance bounds, earlier escapes) and the *termination* (adaptive epsilon, larger efficient steps) pays off so much. Every extra step adds a full field evaluation for $2.07\times10^6$ pixels.

## 25.4 Reducing iterations

Ways to reduce $N_{\text{step}}$:

- **Better distance bound.** An exact SDF gives the largest valid step; a good bound gives large safe steps; a poor estimator gives many small steps.
- **Adaptive epsilon.** Grow the tolerance with depth so the marcher stops earlier.
- **Early exit.** Terminate when $t>T_{\max}$ or when a `max` step budget is hit.
- **Larger starting $t$.** If you know the scene min distance is $>0$ (e.g. camera is outside all objects), start the march at that minimum so you don't waste steps in empty space.

## 25.5 Bounding volumes and cheap distance bounds

A **bounding volume** (a cheap lower bound to the scene) lets the marcher skip empty regions quickly. The classic use: a **bounding sphere** or an **enclosing box** whose SDF is far cheaper than the scene's. If a ray is outside the bounding volume, it cannot hit the scene, so we can skip it.

```
If (boundingVolume(p) > large) → the ray is in empty space; take a big step.
```

**Hierarchical SDFs.** Build a hierarchy of bounding volumes. The top is coarse and cheap; tests descend to finer volumes only when necessary. This reduces the average field cost by only evaluating the scene where the ray actually intersects geometry. In practice, a "distance to the whole scene's bounding box/sphere" is used as a first-pass cheap test, and the full scene is only evaluated inside it.

## 25.6 Avoiding unnecessary operations

The scene-evaluation cost is controlled by avoiding expensive or redundant work:

- **Don't normalize unless needed.** `normalize` costs a `sqrt` and a division. Where a direction is *already* unit (e.g. a plane normal, a rotation matrix column), skip the normalize.
- **Avoid transcendental functions where possible.** `sin`, `cos`, `atan2`, `sqrt`, `pow` are expensive. Use cheap equivalents (e.g. `fract`, `abs`, `mix`, polynomial approximations) where accuracy permits. `pow(x,y)` is equivalent to `exp2(y*log2(x))`; use `exp2`/`log2` directly if you know the base.
- **Factor common expressions.** Compute a subexpression once and reuse it (e.g. a shared `length`, a rotation matrix, a hash).
- **Branch on cheap cheap-first.** Evaluate cheap primitives/fields before expensive ones, and `return` early from the field if a cheap test (like a max-distance) already determines the result.

## 25.7 Branch behavior and loop limits

**Warp divergence.** GPUs execute a fragment (a "warp") of pixels together. If different pixels take different branches, the warp must serialize them — so **branches cost when they diverge**. A `return` inside a fractal loop that exits for some pixels and not others causes divergence. Often it is cheaper to let all pixels run the same loop and just break on a uniform condition.

**Loop limits.** GLSL loops need a compile-time bound (`const`). The loop is unrolled/iterated to `MAX_STEPS`; a `break` is an early-out, but the loop body still exists for `MAX_STEPS` iterations in the worst case. Use a loop limit that's as low as possible for the scene — the difference between a 50-step and a 100-step loop is a 2× cost in the *worst* case (every ray hits the cap). A scene that rarely needs 100 steps is cheaper with a 50-step cap even if it never uses them.

## 25.8 Approximate functions and precision tradeoffs

- **`sqrt` vs. `length`.** `length` is a `sqrt` of a dot; if you only need a *squared* distance to compare (e.g. in a Voronoi nearest-site test), compare squared distances and skip the `sqrt` — save a `sqrt` per site.
- **Low-precision (`half`, `mediump`).** Using `mediump` for parts of the computation doubles throughput but loses precision; it can cause banding. Prefer `highp` for positions and normals where precision matters; use `mediump` for color-only intermediate values.
- **Polynomial approximations.** Replace a transcendental with a cheap polynomial in a bounded range (e.g. a fast sine, a rational `sqrt`). Use where accuracy is non-critical.

## 25.9 Temporal techniques

- **Temporal accumulation.** Reuse the previous frame and jitter per frame to reduce aliasing (Chapter 23) without adding per-pixel samples.
- **Progressive refinement.** Render coarse then refine over frames (for stills/offline).
- **Temporal re-use of marching results.** When the camera moves slowly, many pixels' results change little; reuse the previous frame's hit/miss and only re-march where changed.

These amortize cost across frames rather than within one.

## 25.10 A worked cost budgeting table

| Factor | Value | Effect on cost |
|--------|-------|----------------|
| Resolution | $1024^2$ → $2048^2$ | 4× |
| Steps | 100 → 40 | 0.4× |
| Shadow pass | none → 1 nested march | +100% per pixel |
| Fractal iterations | 8 → 16 | ~2× field cost |
| Field ops | 200 → 100 | 0.5× |

The lesson: **a single-stage change (like adding a shadow march or doubling fractal iterations) can double or halve the total cost**, which is why the step count and field complexity are the two knobs that dominate.

## Exercises

1. **(Calculation)** Compute the per-frame field evaluations for a `1920×1080` scene with 100 steps, no shadows vs. 40 steps with a nested light march (20 samples). Compare.
2. **(Derivation)** Show that if the average number of steps is $N$ and each step costs $C_f$ operations, the total per-pixel cost is $N C_f$, and analyze how a better bound reduces $N$.
3. **(Design)** Give a bounding-volume scheme for a scene with many objects and explain the cost saving.
4. **(Analysis)** Explain why warp divergence makes `return` in a loop expensive and how to structure the loop to avoid it.
5. **(Design)** Replace a `length` nearest-site test with a squared-distance compare to save `sqrts`; describe the precision trade-off.
6. **(Analytic)** Argue why cutting steps from 100 to 40 is a 2.5× speedup, and why this dominates over a 10× change in field complexity.
