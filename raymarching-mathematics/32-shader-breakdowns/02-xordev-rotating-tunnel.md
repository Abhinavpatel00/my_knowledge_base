# Shader Breakdown 2 — XorDev-style Rotating Kaleidoscopic Tunnel

A second hallmark XorDev structure: an infinite, rotating, radially-symmetric tunnel built from almost nothing. Let's analyze a representative fragment and reconstruct it rigorously.

## 1. The fragment

```glsl
void mainImage( out vec4 O, vec2 I ){
    vec2 uv = ( 2.*I - iResolution.xy ) / iResolution.y;
    vec3 ro = vec3( 0., 0., -2. );
    vec3 rd = normalize( vec3( uv, 1. ) );
    float t = 0.;
    for( int i=0; i<80; i++ ){
        vec3 p = ro + rd*t;
        p = rotXZ( p, iTime*0.3 );           // rotate about z (view axis)
        p.y = mod( p.y + 2., 4. ) - 2.;       // axially repeat along y
        float a = atan( p.z, p.x );           // azimuth
        a = mod( a + 0.3927, 0.7854 ) - 0.3927;  // radial fold into 8 sectors
        p.xz = vec2( cos(a), sin(a) ) * length(p.xz);
        float d = length( p.xz ) - 1.0;        // cylinder = tunnel wall
        if( d < 1e-3 ) break;
        t += d;
    }
    vec3 p = ro + rd*t;
    vec3 n = calcNormal(p);
    vec3 col = ... lighting ...
    O = vec4(col,1.);
}
```

## 2. Reconstruct the mathematics

### Step A — Camera and ray
`uv` normalized and aspect-corrected; `ro=(0,0,-2)`, `rd=normalize(vec3(uv,1))`. This is a perspective camera looking along $+z$ (Chapter 23):
$$
\mathbf r(t)=\mathbf o+t\mathbf d,\qquad \mathbf o=(0,0,-2),\qquad \mathbf d=\operatorname{normalize}(u,v,1).
$$

### Step B — Rotation (isometry)
`rotXZ(p, iTime*0.3)` rotates the point about the $z$-axis by an angle that grows with time:
$$
\mathbf p\mapsto R_z(\omega t)\,\mathbf p,\qquad \omega=0.3 .
$$
The rotation is an **isometry** for each fixed $t$ (orthogonal matrix), so it preserves the distance property and is smooth in time — the motion is a clean rigid rotation (Chapter 10, 22).

### Step C — Axial repetition (isometry per cell)
`p.y = mod(p.y+2.,4.)-2.` is centered repetition along $y$ with period 4 (Chapter 11):
$$
p_y'=\operatorname{mod}\!\big(p_y+\tfrac{4}{2},\,4\big)-\tfrac{4}{2}.
$$
This tiles the tunnel lengthwise into an infinite corridor.

### Step D — Radial (angular) folding
`a = atan(p.z,p.x)` computes the azimuth $\theta=\operatorname{atan2}(p_z,p_x)$. Then `a = mod(a+0.3927, 0.7854) - 0.3927` folds it into a sector of angular width $0.7854=\pi/4$, i.e. an **8-fold** radial wrap:
$$
\theta'=\operatorname{mod}\!\Big(\theta+\tfrac{\pi}{8},\ \tfrac{\pi}{4}\Big)-\tfrac{\pi}{8},
\qquad \theta'\in\Big[-\tfrac{\pi}{8},\tfrac{\pi}{8}\Big).
$$
Then `p.xz = vec2(cos(a),sin(a))*length(p.xz)` rebuilds the Cartesian point at that folded angle, preserving its amplitude. This is an **isometric angular reflection** of space into an 8-fold sector — a kaleidoscopic radial fold (Chapter 11). It is exact because the azimuth rotation is an isometry and the sector fold is a reflection.

### Step E — Tunnel wall (exact SDF)
`d = length(p.xz) - 1.0` is the infinite-cylinder SDF (Chapter 08):
$$
d=\lVert\mathbf p_{xz}\rVert-r,\qquad r=1 .
$$
This is exact, and its gradient is unit almost everywhere (smooth off the axis).

### Step F — The march
Standard sphere-trace: step by $d$, terminate when $d<\varepsilon$ ($1e-3$) or the 80-step budget is hit. Because the field is exact (all component transforms are isometries and the cylinder is exact), the march is **safe** — no tunneling, no need for a scale factor.

## 3. Field-class analysis

| Stage | Operation | Isometry? | Exact SDF? |
|-------|-----------|-----------|------------|
| Camera/ray | perspective | yes (recalc) | n/a (not a field) |
| Rotation | $R_z(\omega t)$ | yes | preserved |
| Axial repeat | `mod` | yes (per cell) | preserved |
| Radial fold | `mod`/`abs` of angle | yes | preserved |
| Cylinder | `length(p.xz)-r` | — | exact |

**Conclusion.** The *entire* field is an **exact SDF**. This is why it renders cleanly with sharp edges and no artifacts, and why the step count stays low. The "rotating kaleidoscopic tunnel" is a composition of isometries + one exact primitive — the cheapest kind of scene.

## 4. The "thinking process"

1. **Symmetry.** "I want a tunnel." → a cylinder (`length(p.xz)-r`) is the natural primitive.
2. **Symmetry again.** "I want it to repeat infinitely." → `mod` on the axis (axial repetition).
3. **Symmetry yet again.** "I want it to look kaleidoscopic / star-shaped." → fold the azimuth into $n$ sectors (radial repetition).
4. **Motion.** "I want it to spin." → rotate the frame with `iTime` (isometry).
5. **Minimalism.** Every step is one operation; the whole thing is a handful of lines. The richness is entirely from *composition of isometries*, not from modeling.

The chain is a beautiful illustration of Chapter 29's philosophy: **identify the symmetry group (rotational + translational), choose the coordinates (axial + radial), and build a single sector.** The rest is repetition.

## 5. Extensions

### 5.1 Vary the number of facets (8 → $n$)
The sector width is $2\pi/n$. For $n$ arms use `a = mod(a + PI/n, 2.*PI/n) - PI/n`. So the "facetedness" of the tunnel is a single integer parameter. This is the classic "how many spokes do you want?" knob.

### 5.2 Add a twist along the axis
Replace the rigid rotation with a *height-dependent* twist:
$$
\theta_{\text{twist}}=k\,p_y.
$$
Then the tunnel corkscrews. This breaks the isometry (it's a twist, Chapter 10), so the field becomes a **distance bound**; you must scale the step by $1/\sqrt{1+(k\,\lVert\mathbf p_{xz}\rVert)^2}$ or accept the bound. This is the *only* place the field stops being exact, so it's the one place you must be careful.

### 5.3 Add a second repetition scale (KIFS)
After the axial repeat, *scale* and repeat again:
$$
p\gets s\,p+\text{offset},\quad\text{fold},\quad\text{repeat}.
$$
This builds a self-similar (fractal) tunnel — a **KIFS** (Chapter 11). Because scaling is exact (uniform) but the fold+offset is not, the field becomes a *bound*; multiply the final DE by the per-level scale to keep it safe.

### 5.4 Deform the cross-section
Replace the circular cross-section with a polygon (torus-like) or a star by modulating the radius with the folded angle:
$$
r\gets r_0+\delta\cos(n\theta').
$$
This makes the tunnel "corrugated" or gear-shaped. The modulation is a displacement → the field becomes a bound; the cross-section still renders fine.

### 5.5 Volumetric fog along the tunnel
Add exponential fog based on distance (Chapter 21) to give the corridor depth. This is a *volumetric* addition — it does not touch the field class (the field remains exact), but it adds a smooth depth cue.

### 5.6 Animate the radius (breathing tunnel)
Animate $r$ with time: `r = 1.0 + 0.2*sin(iTime)`. The tunnel "breathes." Because the cylinder SDF is continuous in $r$, the field is continuous in $t$ (coherent — Chapter 22).

### 5.7 Port to a surface-based material
The tunnel wall can be textured procedurally by evaluating a pattern on the folded/hit coordinates (e.g. a stripe along the azimuth, or a crystal pattern), which is a *material* function, not a distance — keep it out of the field.

## Exercises

1. **(Derivation)** Verify the radial fold maps $\theta$ into $[-\pi/n,\pi/n]$ for $n$ arms and preserve amplitude.
2. **(Field class)** Prove the whole field is an exact SDF by verifying each transform is an isometry.
3. **(Derivation)** Compute the Jacobian of a height-twist and its spectral norm; state the safe-step factor that keeps it safe.
4. **(Design)** Change the number of arms from 8 to $n$ and describe the visual change; explain the single parameter.
5. **(Design)** Add a KIFS scale-fold to make a fractal tunnel; describe the field class and the safety correction.
6. **(Derivation)** Deform the cross-section with $\cos(n\theta')$; identify the resulting field class and how to keep it safe.
7. **(Reverse engineer)** Given a fragment with `mod`+`atan`+`mod`+rebuild+`length` and a `rot` by `iTime`, reconstruct the whole pipeline in terms of isometries and a cylinder.
