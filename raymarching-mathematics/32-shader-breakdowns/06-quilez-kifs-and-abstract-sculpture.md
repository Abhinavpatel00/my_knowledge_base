# Shader Breakdown 6 — Quilez-style KIFS, Shells, and Abstract Sculpture

This breakdown reconstructs the *Kaleidoscopic Iterated Function System* (KIFS) structure and the related **shell/onion** and **box-fold** techniques that power a large class of abstract fractal sculptures.

## 1. The structure of a KIFS

The essence of a KIFS is a loop that, at each iteration, applies three operations to the sample point:

```glsl
float map(vec3 p){
    float d = 1e9;                    // accumulate distance
    for(int i=0;i<8;i++){
        p = p*scale + offset;         // scale + translate
        p = abs(p) - c;               // mirror fold + shrink
        d = min(d, ...);              // record distance
    }
    return d*scale_factor;            // rescale so it's a bound
}
```

## 2. Mathematics: the affine self-similarity

At each level, the point is transformed by an **affine similarity**:
$$
p \mapsto s\,p+\mathbf o,
$$
then **folded** by $p_i\mapsto|p_i|-c$ (a mirror reflection about $p_i=c$). The composition is a **self-similarity**: the structure at one scale is a scaled-and-folded copy at the next. Because the scale $s<1$ (the structure gets smaller each iteration), the object is a **fractal** — it self-replicates into finer detail.

**The distance recorder.** At each iteration we record the distance to an *embedded* copy (e.g. `length(p)-r`) and take the min. The result is a distance to the *union* of all the scaled copies, i.e. the fractal surface. As the loop runs, $p$ is pushed toward the fractal's attractor; the accumulated min is close to zero when $p$ is on the fractal.

## 3. Why this is a distance *bound*, not exact

Because the scale $s$ is applied *each iteration*, the distance must be **rescaled**. At iteration $i$, the point has been scaled by $s^i$ (in the forward direction), so a distance $d$ recorded in the *current* scale corresponds to $d/s^i$ in the *original* scale. The final output needs a scale factor.

**The safety correction.** Let $s<1$. The whole field is roughly $D\propto d/s^N$ (for $N$ iterations). If you don't rescale, the field *overestimates* the distance to the *finest* structure but the *march* sees a too-large value → tunneling. The correct move is to **multiply the final value by $1/|s|^N$** (or, equivalently, track and divide by the accumulated scale). This makes the field a valid, conservative bound.

**More precisely.** Each iteration multiplies the *field's Lipschitz constant* by $|s|$ (forward scaling stretches space). So after $N$ iterations the field's gradient norm is $\sim|s|^N$; dividing by $|s|^N$ restores a unit-ish gradient. This is the exact "safe-step factor" logic of Chapter 31a applied to a repeated map.

## 4. The aesthetic: why KIFS looks like "abstract sculpture"

The folding `abs(p)-c` creates **mirror symmetry** at every scale — this is the kaleidoscopic effect. Each level reflects the space into a small fundamental region, and the repeated scaling/reflection produces a self-similar arrangement of "spikes"/"arms"/"petals." This is precisely why KIFS scenes look like crystalline, spiky abstract sculptures: the structure is *generated* by the fold, not modeled.

## 5. Related techniques

### 5.1 Box fold (Mandelbox ingredient)
`p = abs(p) - c` then `if(p.x>1) p.x = 2-p.x` — the **box fold** is a reflection that keeps space bounded and creates the classic Mandelbox clump. It's used both in the Mandelbox and in KIFS for symmetric structure.

### 5.2 Shell / onion (hollow the object)
$$
d_{\text{shell}}=\lvert d\rvert-t .
$$
This makes a hollow shell of thickness $t$: the surface set is $\{|d|=t\}$. Applied inside a KIFS *outer* distance, it turns a solid fractal into layered "onion" rings or a "shelled" structure. Combined with the loop it's a common trick for "hollow crystal."

### 5.3 Sphere fold
```
if(length(p) < minR) p = p * (fixedR*minR/minR);   // scale up
else if(length(p) < fixedR) p = p * (fixedR/length(p));   // normalize
```
This is a **non-isometric** radial fold that, in a Mandelbox, creates the "ball-and-arm" structure. It's the ingredient that makes a Mandelbox distinct from a KIFS.

## 6. The field-class table

| Technique | Isometry? | Field class | Safety |
|-----------|-----------|-------------|--------|
| Scale+translate (KIFS step) | uniform scale | exact (per step) | exact |
| `abs(p)-c` fold | reflection (isometry) | exact | preserved |
| Distance min | — | bound (if pieces are bounds) | conservative |
| box fold | isometry | exact | preserved |
| sphere fold | non-isometric | bound | needs rescale |
| shell `abs(d)-t` | — | exact | preserved |
| Mandelbox DE | — | estimator | use 0.5 factor |

## 7. The "thinking process"

1. **Symmetry.** "I want countless repeating, mirror-symmetric shapes." → use `abs(p)-c` (mirror fold) + `scale` (self-similarity).
2. **Iteration.** "I want it to self-replicate into finer detail." → put the fold+scale in a loop (KIFS).
3. **Distance.** "I need a distance to march." → record `min(length(p)-r)` of each copy; **rescale by the accumulated scale**.
4. **Safety.** "The scale shrinks the field; I must to compensate." → divide by $|s|^N$ at the end.
5. **Aesthetic.** "I want it hollow/layered." → apply `abs(d)-t` (shell) on top.

The chain: **mirror fold + scale + loop + min-record + rescale = abstract fractal sculpture.** The single most important math move in a KIFS is the **rescale**, without which the field tunnels.

## 8. Extensions

### 8.1 A "spiky" KIFS via $p\mapsto|p|-c$ then $p\gets p/\lVert p\rVert$ (radial normalize)
Normalizing after the fold pushes $p$ onto a sphere, creating spikes radiating from the center. This is the "Menger-like spiky ball" family.

### 8.2 Time-varying scale / rotation
Animate `scale`, `offset`, and a rotation inside the loop. The object morphs in time. Because the scale and rotation are isometries, the field remains a bound; the motion is smooth as long as the parameters are smooth in time.

### 8.3 Fractal interior with orbit-trapping color
Color the surface using the **orbit trap** — the `min` of the distance from the orbit to a small target set (a point, a line, a sphere) across iterations. This is exactly how the beautiful "metallic banded" colors of fractal art are produced (Chapter 19).

### 8.4 Combine shell + KIFS for "layered crystal"
`d = abs(kifs(p)) - t` gives a hollow, layered crystal. The look is a "shelled" fractal that reads as translucent crystal.

### 8.5 Mandelbox as a public special case
The Mandelbox is the same loop with a **box fold, sphere fold, scale, and add $c$**. Its DE is the KIFS DE with a scalar running derivative (Chapter 19/20). Understanding KIFS makes the Mandelbox a special case rather than a mystery.

## Exercises

1. **(Derivation)** Show that the KIFS fold+scale is a self-similarity and compute the accumulated scale after $N$ iterations.
2. **(Derivation)** Derive the rescale factor $1/|s|^N$ and argue why without it the field overestimates (tunnels).
3. **(Field class)** Classify the KIFS field and state the safety correction; explain what `min` does in the loop.
4. **(Analytic)** Explain why `abs(p)-c` yields mirror symmetry at every scale.
5. **(Design)** Build a spiky KIFS by normalizing $p$ after the fold; describe the visual and the field class.
6. **(Derivation)** Derive the orbit trap; explain how it produces the metal-banding colors.
7. **(Design)** Apply the shell `abs(d)-t` to a KIFS for a hollow crystal; describe how it changes the object.
