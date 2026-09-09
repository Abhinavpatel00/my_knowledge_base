# Section 32 — Advanced Shader Breakdowns

This section is the "inverse" of the rest of the book: it takes *real, recognizable* fragments (XorDev-style minimal shaders and Quilez-style reference techniques) and **expands them into rigorous mathematics**, then derives **extensions**. It is designed around the reverse-engineering discipline of Chapter 27 and the generative method of Chapter 29.

For each breakdown we follow a fixed protocol:

```
ORIGINAL FRAGMENT
  → ANNOTATE
  → EXPAND INTO EQUATIONS
  → DERIVE THE EQUATIONS
  → IDENTIFY HIDDEN TRANSFORMS / APPROXIMATIONS
  → FIELD-CLASS ANALYSIS
  → RECONSTRUCT THE VISUAL LOGIC
  → EXTENSIONS
  → EXERCISES
```

## Contents

| # | Shader | Core math | Concepts |
|---|--------|-----------|----------|
| 1 | XorDev kaleidoscopic "goo" | `mod`+`abs` fold, the goo map $x(2-x)$ | field-vs-shaping, symmetry |
| 2 | XorDev rotating kaleidoscopic tunnel | composition of isometries + exact cylinder | radial fold, twist bound |
| 3 | Quilez smooth-minimum family | polynomial (CD), exponential, sigmoid (DD) | smin derivation, morphology |
| 4 | Quilez soft shadow & gradient bound | the $\min_t k d/t$ occlusion-angle model | soft shadow, $f/\lVert\nabla f\rVert$ |
| 5 | XorDev-style fBm organic melt | domain warp vs. displacement; smooth-union | bound/estimator |
| 6 | Quilez-style KIFS / abstract sculpture | self-similarity, `abs(p)-c` mirror fold, rescale | fractal, shell/onion, orbit traps |
| 7 | Advanced: curved-ray & Harnack | nonlinear sphere tracing ODE, Harnack bound | generalization |
| 8 | Triplanar / higher-dim / ray differentials | projection blending, 4D slicing, footprint | filtering |
| 9 | XorDev golf-DSL flow-field marchers (Cauldron, Fever, +) | decode the dialect; cone/sheet/bone-lattice fields | `1/d` glow, $L$-class certification |
| 10 | **iq "Seascape"** | heightfield ocean, fixed-point height march | heightfield, Fresnel, waves |
| 11 | **iq "Elastic"** | smooth-union blobs, soft shadow, AO | soft bodies, fake GI |
| 12 | **Menger sponge / cross folding (fb39ca4)** | `sdCross` + repeat + scale + difference | KIFS exactness, rescale |
| 13 | **Quaternion Julia (4D)** | quaternion square, running derivative, Hubbard–Douady DE | 4D slicing, DE |
| 14 | **Worley / Voronoi (F1, F2−F1)** | nearest-site geometry, crack field | cellular noise, $L$-class |
| 15 | **Metaballs** | potential field, not an SDF | potential vs distance |
| 16 | **Hexagonal / honeycomb grid** | triangular lattice, axial transform | six-fold symmetry |
| 17 | **Lightning / electric arcs** | random walk polyline, point-segment distance | stochastic geometry |
| 18 | **Domain-warped fBm (iq)** | coordinate warp, Jacobian cascade | marble/lava/clouds |
| 19 | **Ridged-noise terrain** | `1-|noise|` ridge, octave sum, graph normal | heightfield mountains |
| 20 | **Procedural city (repetition)** | `mod` tiling + per-cell hash | the "structure machine" |
| 21 | **Nebula / space clouds** | volumetric fBm + Beer–Lambert + light march | true volume |
| 22 | **Voronoi crystal cave** | Voronoi border surface, facet displacement | cellular solid, $L$-class |
| 23 | **Glass / dispersion / refraction** | Snell in/out, Beer–Lambert, Fresnel, chromatic + R/G/B | glass |
| 24 | **Rounded voxel grid (DDA)** | grid traversal, in-cell rounded-box SDF | hybrid, cost model |
| 25 | **Twist & bend (organic tube)** | twist/bend Jacobians, spectral norm | domain deformation |
| 26 | **Mechanical gear (radial repeat + CSG)** | radial fold + exact booleans | engineering |
| 27 | **Curl noise (divergence-free flow)** | curl of a potential, advection | fluid/incompressible |
| 28 | **Planet, terrain, atmosphere** | sphere + FBM displacement, analytic atmosphere | synthesis |
| 29 | **iq cosine palette** | $\mathbf a+\mathbf b\cos(2\pi(\mathbf c t+\mathbf d))$ | color mapping |
| 30 | **Hexgrid traversal + analytic AO** | DDA on hex lattice; polygon form factors | analytic atmosphere occlusion |
| 31 | **Ray differentials, material IDs, filtering** | footprint, side-channel material ID, band-limit | anti-aliasing, finishing |

## Artist / technique map

- **XorDev-style minimalism (golf DSL):** flows, goo, tunnels — the "structure machine," the `1/d` glow, the field-vs-shaping distinction.
- **Inigo Quilez:** Smins, soft shadow/AO, Seascape, Elastic, the cosine palette, KIFS/Menger, domain-warped fBm, hexgrid + analytic AO, grid traversal.
- **Community (fb39ca4, &c.):** Menger sponge, quaternion Julia, Voronoi, metaballs, glass, terrain, nebula.

## How to use this section

1. **Read a breakdown fully** before looking at its final shader — let the equations build the intuition.
2. **Do the exercises** — many require deriving a formula you'll reuse.
3. **Compare with Section 29** (Shader Invention): each breakdown is a *worked* instance of the "ask the questions" method.
4. **Use the field-class analysis** to know exactly which constructs are exact SDFs, bounds, or estimators.

## The recurring lesson

Nearly every striking shader reduces to **a few isometries and one exact primitive, shaped by a nonlinear remap — or a density/potential field treated as volume**. The complexity is in the composition, not in any single line. Recognizing whether the result is exact, a bound, or an estimator is what turns "I can't read that shader" into "I can invent that shader."
