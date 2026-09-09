# Shader Breakdown 1 — XorDev's Kaleidoscopic Goo

This is the canonical XorDev-style minimal fragment. An authentic version (reconstructed from the public ShaderToy family that begins with the `modf(I/vec2(6,9),I)` tile-and-fold) is:

```glsl
void mainImage( out vec4 O, vec2 I ){
    I = ( 2.*I - iResolution.xy ) / iResolution.y;
    vec2 p = I;
    p = mod( p + 1.0, 2.0 ) - 1.0;              // centered repetition
    p = abs( p );                               // mirror fold
    P = ...                                      // base field
    O.g = 2.5 - length( p );                     // goo "distance"
    O *= 2.0 - O;                                // the goo map
}
```

We will reconstruct its mathematics, then extend it in several directions.

## 1. The visual target

A blob of "goo" that flows, folds, and melts, with smooth melty boundaries and a signature translucent-looking color ramp. The startling feature for a newcomer is that the *whole* structure arises from a couple of `mod`/`abs` operations plus a *single nonlinear color map*, and there is **no signed distance field and no ray march** — it is a flat 2D field rendered directly.

## 2. Expand into mathematics

### Step A — Coordinate normalization and aspect

`I = (2.*I - iResolution.xy)/iResolution.y` maps pixel coordinates to $[-1,1]\times[-1,1]$ and corrects aspect by dividing by `iResolution.y` (Chapter 23). So $I\in\mathbb R^2$ is the normalized, aspect-corrected screen coordinate.

### Step B — Centered repetition

`p = mod(p+1.0, 2.0) - 1.0` is **centered repetition** along both axes (Chapter 11):

$$
p_i'=\operatorname{mod}\!\big(p_i+\tfrac{a}{2},\,a\big)-\tfrac{a}{2},\qquad a=2.
$$

This tiles the domain into an infinite lattice of $2\times2$ cells. The map is an isometry *within* each cell (translation), so as a domain transform it is exact; the field is periodic with period 2.

### Step C — Mirror fold

`p = abs(p)` reflects each coordinate across $p_i=0$:

$$
p_i'=\lvert p_i\rvert .
$$

This is a **reflection** (an isometry) — it maps the lattice into its fundamental octant-half. Combined with the repetition, we get the "kaleidoscope": the structure is symmetric under $p_i\to-p_i$ and under translation by 2.

### Step D — The base field

`O.g = 2.5 - length(p)` is, up to a constant, the **distance to the origin in the folded coordinate**:

$$
g(\mathbf p)=c_0-\lVert\mathbf p\rVert .
$$

Because $p$ has been folded into a small fundamental region, the value $g$ is a "distance to the cell center" that *increases* as you move away from the center of each folded cell. The constant $2.5$ is a radial scale/offset.

### Step E — The goo map: $O \leftarrow O(2-O)$

The single line `O *= 2.0 - O` is the crux. Mathematically, applied component-wise (here to the green channel, or to the whole color), it is the **logistic-type map**

$$
x\mapsto x\,(2-x)=1-(1-x)^2 .
$$

**Analysis of this map.** Let $y=1-x$. Then $x(2-x)=1-y^2=1-(1-x)^2$. So the map is a **quadratic fold** of the deviation of $x$ from $1$:

- If $x=0$, then $x'=0$.
- If $x=1$, then $x'=1$ (a fixed point).
- If $x=2$, then $x'=0$.
- It is symmetric about $x=1$: $x'(2-t)=x'(t)$.
- It maps $[0,2]\to[0,1]$, and $[0,1]\to[0,1]$.

Crucially, this is a **smooting map**: near $x=1$ it is flat (derivative $2-2x=0$ at $x=1$), so it *pushes values toward 1* and creates a smooth, saturated "blob" with a melty edge. Because the input $g$ spans a range that crosses the fold, the output has a *soft, rounded* profile — the "goo."

**Why this is not a distance field.** The map $g\mapsto g(2-g)$ is a smooth, non-isometric, non-1-Lipschitz remapping. It is a *color/shape shaping* function, not a distance. The image has the *look* of a raymarched SDF (soft, absorbedy blobs) because the fold sharply raises and saturates the field at the "surface" — but there is no marching and no conservative step. It is a purely **scalar-field → color** construction. Recognizing this (and not calling it an SDF) is exactly the discipline of Chapter 06.

## 3. The complete mathematical model

Assembling all steps, the fragment is the composition

$$
\text{color}(\mathbf u)=
\varphi\circ g\circ M\circ R\circ T\circ N(\mathbf u),
$$

where:

- $N$ = normalization + aspect (maps pixel to $[-1,1]$),
- $T$ = centered repetition (`mod`),
- $R$ = mirror fold (`abs`),
- $M$ = the metric $\mathbf p\mapsto c_0-\lVert\mathbf p\rVert$,
- $g$ = a smooth palette (shader-defined),
- $\varphi$ = the goo map $x\mapsto x(2-x)$.

In one line: **normalize, repeat, fold, measure, shape.** The visual richness comes from *where the fold and measure meet*.

## 4. The "thinking process" (how XorDev arrives at this)

This is the core lesson. The mental chain is:

1. **Symmetry.** "I want many mirrored blobs." → Use `mod` (repeat) + `abs` (mirror). This is the kaleidoscope instinct.
2. **Base shape.** "I want round soft blobs." → Distance-then-shape: `c - length(p)` gives a radial field.
3. **Softness / melty edge.** "I want the blobs to melt, not have hard was. A hard `step`/`length` threshold looks cartoon." → Apply a *smooth, saturating* map. The fold `x(2-x)` is the cheapest saturating smooth step. It is a **one-line smooth threshold**.
4. **Minimalism.** "I want the whole thing in as few tokens as possible." → Once the structure is understood, every operation is *one* line and the whole scene collapses to the compact form.

The deepest insight: **the complexity is in the composition of four trivial operations, not in any one of them.** Each is mathematically trivial; their composition is not. This is the generative principle of Chapter 29 made concrete.

## 5. Field-class analysis and safety

| Stage | Field/operator | Distance class |
|-------|----------------|----------------|
| Repetition `mod` | periodization | exact (isometry per cell) |
| Fold `abs` | reflection | exact (isometry) |
| Metric `c-length` | distance to center | exact SDF (2D) |
| Goo map `x(2-x)` | quadratic shaping | **not a distance** |

So this whole shader is *not* a raymarcher. It is a 2D *field-remapping* trick that produces SDF-lookalike output. Several XorDev pieces are like this — they exploit the *shape* of a distance to make goo/soft surfaces without ever marching. Recognizing this distinction is important: if you lifted the `g` field into a 3D raymarcher, you'd need to treat `2.5-length(p)` as a genuine distance and *not* apply the goo map inside the field (the goo map would break safety).

## 6. Extensions

### 6.1 Extend to time: flowing goo

Animate the repetition offset or the cell centers. Because repetition is a translation-with-cut, adding a time-dependent offset to the *input* before the `mod` makes the lattice translate:

$$
\text{color}(\mathbf u,t)=
\varphi\circ g\circ M\circ R\circ T\circ N(\mathbf u+\mathbf v t).
$$

This makes the goo "flow" across the screen. Coherence: all operations are continuous in $t$ (no `floor(iTime)`), so the motion is smooth — the design rule of Chapter 22.

### 6.2 Extend to a moving/rotating kaleidoscope

Rotate the coordinate frame before folding:

$$
p=R(\omega t)\,N(\mathbf u).
$$

Since $R$ is an isometry, the exactness of the folding is preserved; only the orientation of the kaleidoscope swirls over time.

### 6.3 Extend to 3D: a raymarched goo

To make actual *3D* goo, keep the **field** as a genuine distance (no goo map inside), e.g.

```glsl
float map(vec3 p){
    p = mod(p+1.0,2.0)-1.0;
    p = abs(p);
    float d = length(p) - 0.7;
    d = max(d, 0.0);                 // goo "body"
    ...
    return d;
}
```

Then ray-march it, and apply the goo map *only* to the shading (e.g. a smooth threshold on the SDF-based AO or a curvature-based border), never to the marching step. This preserves safety while giving the same aesthetic in 3D.

### 6.4 Extend with noise displacement

Add FBM displacement to the distance before folding to get an "organic melt:" $d\gets d+\lambda\,\mathrm{fbm}(k\mathbf p)$. This is a displacement (Chapter 16), so it changes the field class to *bound* — keep $\lambda$ small and/or scale the step. The goo becomes "goo with a noisy, wobbly skin."

### 6.5 Extend the shaping map family

The map $x\mapsto x(2-x)$ is one member of a family. Generalizations:

- **Higher power:** $x\mapsto 1-(1-x)^m$ (sharper or softer fold as $m$ varies).
- **Smoothstep:** $\varphi(x)=\operatorname{smoothstep}(a,b,x)$, a $C^1$ threshold.
- **Logistic saturation:** $\varphi(x)=\frac{1}{1+e^{-k(x-c)}}$ (sigmoid), for a controlled soft edge.
- **Palette maps.** The "goo" color is often a gradient $\varphi$ applied to how deep you are inside the blob. Understanding $\varphi$ as a map lets you *design* the color/edge rather than tweaking it.

### 6.6 Inverse: reconstructing the class from the token

This is the reverse-engineering angle. If you see a fragment with `mod` + `abs` + a `-length` + a quadratic fold, you immediately know:

- It is a **kaleidoscopic field**, not a raymarcher.
- The "goo" is a **shaping map**, not a distance.
- To port it to 3D, you *keep* the distance part and *move* the shaping to the shading stage.

That single inference saves hours of confusion.

## Exercises

1. **(Derivation)** Analyze the map $x\mapsto x(2-x)$: find its fixed points, its symmetry, and its effect on the curvature of the field. Explain why it "softens" the edge.
2. **(Derivation)** Show that $x(2-x)=1-(1-x)^2$ and draw the fold.
3. **(Reverse engineer)** Given `p=mod(p+1.,2.)-1.; p=abs(p); d=2.5-length(p);` reconstruct each mathematical stage and identify the structure.
4. **(Field class)** Explain why the goo map is not a distance, and where you'd place it if you ported this to a 3D raymarcher.
5. **(Design)** Extend the goo to time by translating the input; argue temporal coherence (Chapter 22).
6. **(Design)** Build a 3D version that is an actual SDF, and place the goo shaping in the shading only.
7. **(Derivation)** Generalize the shaping map to $1-(1-x)^m$; analyze the derivative at $x=1$ and how the edge sharpness depends on $m$.
