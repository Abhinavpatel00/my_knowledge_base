# Shader Breakdown 9 — XorDev's Golf-DSL Flow-Field Marchers (Cauldron, Fever, and a third variant)

These three fragments belong to a single family: XorDev's signature **escape-time flow-field marchers**, written in his private golf dialect and compressed to a few dozen tokens each. They are *not* ordinary raymarchers of an exact SDF. They are a **volumetric, displacement-marched, light-accumulating** renderer whose "distance" is a hand-built, periodic pseudo-field. This breakdown decodes the dialect, reconstructs readable GLSL, and then gives the full mathematics.

A note on provenance. The signatures `p=z*normalize(FC.rgb*2.-r.xyy)`, `O=tanh(...)`, and the `for(float i,z,d;...)` accumulator are XorDev's own golf idiom, and `FC.rgb*2.-r.xyy` / `o=tanh(o/…)` match his published shaders. The token-level spelling is private/community shorthand (a "0," means `0`; `.rgb`/`.xyy` are swizzle-packings; `f3`/`f4`/`nor`/`len` are `vec3`/`vec4`/`normalize`/`length`). Where a golf swizzle admits more than one reading, I reconstruct the *semantically standard* GLSL and state the equivalence; the mathematics below is independent of the exact packing.

## 1. The golf-DSL legend

| Token | Standard meaning |
|-------|------------------|
| `f3`, `f2`, `f4` | `vec3`, `vec2`, `vec4` |
| `nor` | `normalize` |
| `len`, `length` | `length` |
| `T`, `t` | `iTime` |
| `R`, `r` | `iResolution` |
| `C`, `FC` | `fragCoord` (pixel coordinate; `.rgb`/`.xyy` are swizzle packings of the ray frame) |
| `O`, `o` | `fragColor` (output) |
| `@(N)` | `for(int i=0;i<N;i++)` |
| `,` after a statement | statement separator (golf: joins loop bodies) |
| `f4(5,0,2,)` | `vec4(5.0,0.0,2.0,0.0)` (empty = 0) |
| `mat2(a,b,c,d)` | the 2×2 matrix `[[a,c],[b,d]]` (GLSL column-major) |
| `p.zy += 3` | `p.z += 3; p.y += 3` |
| `p += s/d` | a displacement/domain warp, amplitude scaled by `1/d` |

## 2. The three fragments, decoded to standard readable GLSL

### Cauldron (reconstructed)

```glsl
void mainImage(out vec4 O, vec2 C){
    float z = 0.0, d = 0.0;                     // z = ray param, d = field
    for(int k = 0; k < 40; k++){
        vec3 p = z * normalize( 2.0*C.rgb - R.xyy );   // point on the ray
        p.z += 3.0; p.y += 3.0;                          // translate the frame
        d = 2.0; for(int j = 0; j < 7; j++) d /= 0.8;    // d ← 2·1.25^7 ≈ 9.54
        p += 0.6 * p.y * cos( p.yzx * d - vec3(T,0,0)*6.0 ) / d;  // swirl warp
        z += d = 0.02 + abs( length(p.xz) + 0.4*p.y - 1.0 ) / 9.0; // field + advance
        O += ( sin( vec4(5.0,0.0,2.0,0.0) - p.y ) + 2.0 ) / d;     // accumulate light
    }
    O = tanh( O*O / 15e5 );
}
```

### Fever (reconstructed)

```glsl
void mainImage(out vec4 O, vec2 C){
    float z = 0.0, d = 0.0;
    for(int k = 0; k < 70; k++){
        vec3 p = z * normalize( 2.0*C.rgb - R.xyy );
        p.xy *= mat2( cos(z*0.5 + vec4(0.0,33.0,11.0,0.0)) );  // z-dependent rotation
        p.z -= T;                                               // scroll the scene
        d = 2.0; for(int j = 0; j < 5; j++) d += d;             // d ← 2^6 = 64
        p += sin( p.yzx * d + z ) / d;                          // swirl warp
        z += min( abs(cos(p.y)), d = length( 1.0/tan(p.xz) ) ) / 4.0;  // field + advance
        O += vec4( 1.1 + sin(p), 0.0 ) / d;                     // accumulate light
    }
    O = tanh( O / 2e2 );
}
```

### Third variant (already standard-ish GLSL, decoded fully)

```glsl
void mainImage(out vec4 o, vec2 FC){
    vec3 v;
    float z = 0.0, d = 0.0;
    for(float i = 0.0; i < 50.0; i++){
        vec3 p = z * normalize( FC.rgb*2.0 - r.xyy );
        p.z -= t;
        z += d = 0.5 * length( max( v = cos(p) - sin(p).yzx, v.yzx * 0.2 ) );
        o.rgb += ( cos(p) + 1.2 ) / d;
    }
    o /= o + 1000.0;
}
```

The three share one skeleton. In **Section 3** we write the skeleton as equations; in **Sections 4–6** we isolate what makes each distinct (the field, the warp, the color).

## 3. The mathematical formulation of the flow-field marcher

Let the ray be
$$
\mathbf p(z)=z\,\mathbf d,\qquad \mathbf d=\operatorname{normalize}\big(\text{screen-map}\big),\qquad \mathbf o=\mathbf 0,
$$
where $z$ is a scalar ray parameter (arclength, since $\lVert\mathbf d\rVert=1$). The shader iterates a **parametrized point-and-field recursion**:

$$
\begin{aligned}
\mathbf p_n &= z_n\,\mathbf d+\mathbf s_n, &&\text{(position, with a shift }\mathbf s_n\text{)} \\
\mathbf p_n &\leftarrow \mathbf p_n + \boldsymbol\phi(\mathbf p_n), &&\text{(domain warp / swirl)} \\
D_n &= g(\mathbf p_n), &&\text{(field evaluated at warped point)} \\
z_{n+1} &= z_n + D_n, &&\text{(advanced by a "step")} \\
L_{n+1} &= L_n + \frac{h(\mathbf p_n)}{D_n}, &&\text{(accumulated radiance)}
\end{aligned}
$$
and the final tonemap is $\;O=\Psi(L)$ with $\Psi$ a smooth saturating map ($\tanh$ or $L/(L+k)$).

### 3.1 The ambient ray and the screen map

`normalize(2.0*C.rgb - R.xyy)` is the golf packing of the standard ShaderToy ray:
$$
\mathbf d=\operatorname{normalize}\Big(\tfrac{2\,\text{fragCoord}_{xy}-\text{iResolution}_{xy}}{\text{iResolution}_y},\ 1\Big).
$$
(The `.xyy`/`.rgb` swizzles produce an equivalent direction up to an overall scale; the key facts are that the ray is (a) normalized, so $z$ is arclength, and (b) depends on the pixel and the aspect ratio.) The origin is the origin.

### 3.2 The field $g$: the heart of the effect

This is where the three differ, and it is what determines the whole look. Each $g$ is a *pseudo-distance*: not an exact SDF, but a function with small values near a periodic family of surfaces, so that the marcher slows near those surfaces and the `1/d` accumulation glows there.

We analyze each field's **Lipschitz constant** and thus its **field class** (exact / bound / estimator), using the certification tools of Chapter 31a:

If $\lVert\nabla g\rVert\le L$, then the *safe* step is $g/L$. A factor $<1$ on $g$ therefore makes it a conservative **bound** (safe, but slow); a factor $>1$ or an uncontrolled gradient makes it an **estimator** (fast, but can tunnel).

### 3.3 The radiative accumulation and the glow

The radiance accumulator is
$$
L=\sum_{n}\frac{h(\mathbf p_n)}{D_n}.
$$
This is a discrete approximation to a **volumetric line integral** along the ray (Chapter 21),
$$
L\approx\int \frac{h(\mathbf p)}{D}\,dz,
$$
but with an unusual weight: *dividing by the field value* rather than by the transmittance. Near a surface, $D\to0$, so the integrand $\sim h/D$ blows up. This is the "glow": the bright filaments are where the ray grazes a near-zero of $D$. It is a **physically-inspired but non-physical** weighting — a deliberate artistic choice, not a derived light-transport model. We label it as an `APPROXIMATION` / `VISUAL HACK`.

### 3.4 The tonemap $\Psi$

The accumulator $L$ is unbounded (it can exceed $10^3$, and the number of iterations multiplies it). $\Psi$ maps it into $[0,1]$. Two forms appear:

- **$\tanh$:** $\Psi(L)=\tanh(\gamma L)$. This is a smooth, symmetric saturation: for small $L$, $\tanh(\gamma L)\approx\gamma L$ (linear); for large $L$, $\tanh(\gamma L)\to1$. It **never** blows up, has a natural soft shoulder, and is order-preserving. (Cauldron applies $\tanh(O^2/\sigma)$ with $\sigma=1.5\times10^6$ — the square adds contrast by sharpening mid-tones; Fever applies $\tanh(O/\sigma)$ with $\sigma=200$.)
- **Reinhard-type:** $\Psi(L)=L/(L+k)$ with $k=1000$. This is the classic filmic response: $\Psi(0)=0$, $\Psi\to1$ as $L\to\infty$, with a soft band whose "knee" is at $L=k$.

Both are monotone, bounded, and $\mathcal C^\infty$; both are *tonemapping operators* that map unbounded accumulated light to a displayable range. The exact knee ($\sigma$ or $k$) and the sharpening (the square in Cauldron) are **aesthetic parameters**, and the math of the map is the same regardless.

## 4. Field-by-field analysis

### 4.1 Cauldron's field: a displaced cone

The pre-warp "distance" is
$$
g(\mathbf p)=\frac{\Big\lvert\,\lVert\mathbf p_{xz}\rVert+0.4\,p_y-1\Big\rvert}{9}+0.02 .
$$

**Geometry.** The set $\lVert\mathbf p_{xz}\rVert+0.4\,p_y=1$ is a **cone** (a surface of revolution whose radius grows linearly with $-p_y$). The `abs` makes it the unsigned distance to that cone. Dividing by $9$ shrinks the field; the $0.02$ is a floor so the marcher never advances by zero.

**Gradient / Lipschitz.** Let $u(\mathbf p)=\lVert\mathbf p_{xz}\rVert+0.4p_y$. Then $\nabla u=(\hat{\mathbf p}_{xz},0.4)$ and
$$
\lVert\nabla u\rVert=\sqrt{1+0.4^2}=\sqrt{1.16}\approx1.077.
$$
After the `abs` and division by $9$, $\lVert\nabla g\rVert\approx 1.077/9\approx0.12<1$. **So $g$ is a conservative lower bound — a legitimate distance bound, safe for the marcher.** The cost is that the step is small (only $\sim12\%$ of the true distance), so it needs many iterations. This is the exact trade-off the "safe step = $d/L$" rule predicts.

**The warp.** `0.6 * p.y * cos(p.yzx*d - (T,0,0)*6) / d` is a displacement whose amplitude is
$$
\lambda = \frac{0.6\,p_y}{d},
$$
and whose phase depends on $d$ and time. Because $d$ grows (the warm-up loop sets $d\approx9.54$), the amplitude is small and the warp is a gentle swirl. The warp makes the field a **bound** (it is not an isometry), but since it is mild and the base field is already reduced by $/9$, the marcher stays safe.

### 4.2 Fever's field: a periodic sheet lattice

The "distance" is
$$
g(\mathbf p)=\frac{\min\!\Big(\big\lvert\cos(p_y)\big\rvert,\ \big\lVert\,(1/\tan p_x,\ 1/\tan p_z)\,\big\rVert\Big)}{4}.
$$

**The first term.** $\lvert\cos(p_y)\rvert$ is the distance (up to a factor) to the plane family $\cos(p_y)=0$, i.e. $p_y=\frac{\pi}{2}+k\pi$. It is 1-Lipschitz: $\nabla(\cos p_y)=(-\sin p_y,0,0)$, $\lVert\cdot\rVert=\lvert\sin p_y\rvert\le1$.

**The second term.** $\lVert(\cot p_x,\cot p_z)\rVert$ is a distance to the lattice $\{\tan p_x=\infty\}\cup\{\tan p_z=\infty\}$, i.e. $p_x=\frac{\pi}{2}+k\pi$ and $p_z=\frac{\pi}{2}+k\pi$. Its gradient is $\lVert(1/\sin^2 p_x,0,1/\sin^2 p_z)\rVert$-scaled, which **exceeds 1** where the tangents are near zero — so the field can *overestimate* there.

**The `min`.** Taking the minimum of the two sub-fields selects whichever surface family is nearer. The `/4` shrinks the whole thing toward a safe bound, but because the second term's gradient is unbounded, `g` is best classified as an **estimator with a safety heuristic** (the `/4` keeps it mostly conservative). In practice XorDev tunes the `/4` so that grazing near the sheets glows but rarely tunnels.

**The warp.** `sin(p.yzx*d + z)/d` is a swirl whose amplitude $1/d$ shrinks as $d$ grows — a self-quenching warp. The rotation `p.xy *= mat2(cos(z*0.5 + (0,33,11,0)))` rotates the transverse plane by an angle that increases with $z$ — a **spiral** (the ray corkscrews as it marches).

### 4.3 Third variant's field: a triply-periodic "bone" lattice

The field is
$$
g(\mathbf p)=0.5\,\Big\lVert \operatorname{max}\big(\mathbf v,\ 0.2\,\mathbf v^{.yzx}\big)\Big\rVert,
\qquad
\mathbf v=\cos(\mathbf p)-\sin(\mathbf p)^{.yzx},
$$
where $\cdot^{.yzx}$ is the cyclic shift $(a,b,c)\mapsto(b,c,a)$.

**Component-wise.** Writing $\mathbf p=(x,y,z)$,
$$
\mathbf v=\big(\cos x-\sin y,\ \cos y-\sin z,\ \cos z-\sin x\big).
$$
This is a **cyclic 3-oscillator field**: each component compares a cosine along one axis with the sine along the next. The zero set of $\mathbf v$ is a **triply-periodic surface** — a "woven" surface, since each $v_i=0$ is a graph. The `max` with $0.2\,\mathbf v^{.yzx}$ overlays a **second, cyclically-shifted copy**, creating a honeycomb/bone-like lattice (the "max of two interlocking sheets").

**Why the 0.5 factor.** The `max` can produce a value larger than the true distance to the woven surface, so the marcher might overshoot. The `0.5` is a **global safety discount** — a heuristic to keep the field conservative. This is the classic "use a factor $<1$ on your distance estimate so you never tunnel" move, exactly as in Chapter 31a. But because the gradient of `max(v, 0.2 v-shifted)` is not uniformly bounded above 1, this is an **estimator**, safe in practice thanks to the 0.5 margin, not a certified bound.

## 5. The collection of the three: what is exact, what is a bound, what is an estimator

| Shader | Field | Raw gradient | Class | Safety factor |
|--------|-------|--------------|-------|---------------|
| Cauldron | cone distance $/9$ | $\approx0.12$ | **distance bound** | conservative (safe, slow) |
| Fever | `min` of sheet distances $/4$ | unbounded in second term | **estimator** | `/4` heuristic |
| Third | max of trig lattice × 0.5 | unbounded | **estimator** | `0.5` heuristic |

None of the three is an **exact SDF**, and none pretends to be. This is the crux: XorDev's golf shaders are *aware* they are not distances; they use the *shape* of a field and a safety discount to get a distinctive look without the cost of a rigorous SDF. The resulting images are visually "raymarched" but are really **pseudo-volumetric flow-field accumulations**.

## 6. The math of the glow (why it looks "lit")

The brightness of a filament is where the ray approaches a zero of $g$. Over one loop step, the radiance added is $h/D$. As $D\to0$ (the ray grazes the surface), the added light $\sim h/D$ grows. So:

- **Thin bright filaments** = the ray grazes a zero set of the field (a sheet, a cone, a bone-lattice surface).
- **Dark voids** = the ray stays far from any zero set, where $D$ is large and $h/D$ is small.
- **The tint** comes from the channel offsets $h(\mathbf p)$ (e.g. `sin(vec4(5,0,2,0)-p.y)+2` in Cauldron, `1.1+sin(p)` in Fever, `cos(p)+1.2` in the third): each channel is modulated by a different phase of a periodic function of position, giving a *position-dependent* hue.

The `1/D` accumulation is best understood as an **inverse-distance glow**: it is a heuristic that replaces physically-derived emissive/transmittance weighting with a "closer to surface = brighter" rule.

## 7. The "thinking process" (XorDev's reasoning)

1. **"I want glowing, flowing filaments."** → Accumulate light weighted by `1/D` (inverse distance), so the ray glows where it grazes a surface.
2. **"I want a periodic, organic surface, made of math."** → Use a *periodic* field built from `sin`/`cos`/`tan`, and a `max`/`min`/`abs` to combine components. No explicit geometry.
3. **"I want it to not blow up when it grazes."** → The `1/D` with a tiny floor, plus a final `tanh`, keeps the accumulation bounded.
4. **"I want it to flow / swirl."** → Domain-warp each step by `sin(p)/d` and rotate the frame with `z`.
5. **"I want it in the fewest tokens."** → Golf the dialect: `f3`/`nor`/`len`, swizzles, comma-joined loop bodies.

The deep lesson (Chapter 29): **the look is generated by a small number of composable operations — a periodic field, a safety discount, an inverse-distance glow, a tonemap — not by modeling.** Each is a few tokens; their composition is the art.

## 8. Extensions and generalizations

### 8.1 Make it a real SDF (rigorous)
Replace the hand-tuned fields with exact distance bounds:
- Cauldron's cone → `abs(length(p.xz)/sqrt(1.16) + 0.4*p.y/sqrt(1.16) - 1/...)` normalized so the gradient ≈ 1, giving an *exact* cone SDF.
- Fever's sheets → exact capsule/box lattice SDFs combined with `min`.
- Third's bone lattice → build a **true triply-periodic minimal surface** SDF (a known closed form) and march it.

### 8.2 Add lighting, shadows, and AO
Once you have a (near-)distance, you can compute normals (Chapter 12), soft shadows (Chapter 14), and AO from the *same* field — turning the glow into a genuinely lit surface.

### 8.3 Make the glow physically motivated
Replace `h/D` with a physically-based **emission × transmittance** accumulation:
$$
L=\sum_n \sigma_a\,e(\mathbf p_n)\,T_n\,\Delta z,\qquad T_n=\prod_{j<n}e^{-\sigma_t\rho(\mathbf p_j)\Delta z},
$$
for a density $\rho$ (Chapter 21). This changes the look from "thin glowing filaments" to "proper volumetric fire/nebula."

### 8.4 Animate the warp more richly
Advect the warp by a flow field (curl noise, Chapter 16) and let the phase depend on a noise-driven quantity, so the "flow" looks turbulent rather than sinusoidal.

### 8.5 Boundary of the field class: quantify the discount
For each heuristic factor (the `0.5`, the `/4`), compute the actual maximum of $\lVert\nabla g\rVert$ over the region of interest (Chapter 31a) and *certify* that the factor makes it a bound. Then you know the safety margin and can shrink the factor only as far as it stays safe.

### 8.6 De-golf into a maintainable shader
Expand the golf into named functions (`map`, `calcNormal`, `render`), with the field class documented. This is the "expand the shader mathematically, then rebuild it" discipline of Chapter 26.

## Exercises

1. **(Decode)** Convert each golf token in Cauldron and Fever into standard GLSL; annotate every line with its mathematical meaning.
2. **(Derivation)** Compute $\nabla u$ and its norm for the cone $u=\lVert\mathbf p_{xz}\rVert+0.4p_y-1$; verify the Cauldron field is a bound.
3. **(Derivation)** Compute the Lipschitz constant of Fever's `min` field and identify where it exceeds 1; explain why `/4` helps but doesn't certify it.
4. **(Derivation)** Write $\mathbf v=\cos(\mathbf p)-\sin(\mathbf p)^{.yzx}$ component-wise and describe the zero set of each $v_i$; explain the `max` overlay.
5. **(Analytic)** Derive why `1/D` accumulation produces "glowing filaments," and state the field class of each shader.
6. **(Analytic)** Derive the tonemap $\tanh(\gamma L)$ and $L/(L+k)$: monotonicity, range, knee. Explain what the square in Cauldron's $\tanh(O^2/\sigma)$ does.
7. **(Design)** Convert one of these three into a real SDF by replacing the field; then apply lighting and AO. Describe the change in look.
8. **(Design)** Replace the `1/D` glow with a physically-based emission×transmittance accumulation and describe the result.
