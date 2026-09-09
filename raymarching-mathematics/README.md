# The Mathematics of Raymarching

### A Rigorous Mathematical Text on Signed Distance Fields, Procedural Geometry, and Advanced Shader Construction

This is a mathematics-first reference work for people who want to **invent** raymarched shaders, not copy them.

It is deliberately *not* a programming tutorial. Almost every technique here is developed in this order:

```
INTUITION → GEOMETRY → MATHEMATICAL DEFINITION → DERIVATION → PROPERTIES
         → NUMERICAL CONSEQUENCES → ALGORITHM → GLSL → OPTIMIZATION
         → VISUAL EFFECTS → VARIATIONS
```

A raymarched shader is not primarily a piece of GLSL. It is a **mathematical model evaluated millions of times by a GPU**. The shader is the executable form of that model. The central discipline of this book is to keep the mathematics visible, so that the reader can reason backward from a desired visual to the field whose zero-set generates it:

```
VISUAL IDEA
    → GEOMETRIC STRUCTURE
    → COORDINATE SYSTEM
    → MATHEMATICAL REPRESENTATION
    → DISTANCE / IMPLICIT FUNCTION
    → DOMAIN TRANSFORMATION
    → RAY INTERSECTION
    → NORMAL / DERIVATIVES
    → LIGHT TRANSPORT
    → COLOR / MATERIAL
    → ANIMATION
    → OPTIMIZATION
    → FINAL SHADER
```

---

## How to use this corpus

This is a **documentation corpus**: a set of ordinary Markdown files organized into chapters. It is intentionally free of any web-framework boilerplate so that it can be dropped into Nextra, Docusaurus, MkDocs, Astro Starlight, or served as plain Markdown.

- Each directory `NN-name/` is one thematic section.
- Files inside are logical chapters; many are titled `NN-name.md` so navigation is predictable, but real pages can be split further.
- Math is written in LaTeX (rendered by `$...$` / `$$...$$`).
- Code fragments are GLSL ES (ShaderToy-compatible) and always follow the mathematics.
- ASCII diagrams are used where they carry geometric meaning.

The intended reading order is **Level 0 → Level 19** (see the Preface). The book **does not** jump from sphere tracing to Mandelbulbs. Each subject is built from the one before it.

**For the advanced reader:** after the main sequence, Sections **31**, **32**, and **33** are the graduate-level tier. Section 31 replaces the "practical bound" intuition with a *rigorous* foundation (convergence certificates, the eikonal equation, Harnack tracing, curved-ray marching). Section 32 is the inverse of the whole book: it expands real XorDev- and Quilez-style fragments into equations, derives them, and extends them. Section 33 is the engine-scale capstone: how Claybook and Dreams build a *world* out of SDFs, simulate fluid against it (full SPH discretization with an SDF boundary), and make the whole thing real-time (sparse tiles, mip-filtered grids, point-cloud splatting), with the memory/precision and discretization-error mathematics worked out. The intended audience for those sections is someone comfortable with the material through Level 14 and with graduate-level real analysis and ODE/PDE basics.

---

## Table of contents

| # | Section | Summary |
|---|---------|---------|
| 00 | Preface | Conventions, prerequisites, learning progression, the book's philosophy |
| 01 | Mathematical Foundations | Infima, continuity, Lipschitz, Euclidean structure, notation |
| 02 | Linear Algebra | Vectors, dot/cross products, matrices, rotations, quaternions, orthonormal bases |
| 03 | Analytic Geometry | Points, lines, planes, distances, intersections, convex hulls |
| 04 | Coordinate Systems | Cartesian, polar, cylindrical, spherical; Jacobians; when to change systems |
| 05 | Implicit Surfaces | Level sets, gradient orthogonality, regularity, smoothness |
| 06 | Distance Fields | SDF vs. UDF vs. DE vs. scalar fields; exactness; medial axes |
| 07 | Raymarching | Sphere tracing derived from first principles; safety; termination |
| 08 | SDF Primitives | Every primitive derived from its geometry |
| 09 | Boolean Operations | min/max, smooth booleans, morphology, and their exactness |
| 10 | Domain Transformations | Distance-preserving vs. distance-bounding transforms |
| 11 | Repetition & Symmetry | mod, folding, radial/hierarchical repetition (the "structure machine") |
| 12 | Differential Geometry | Gradients, normals, curvature, ray differentials |
| 13 | Lighting | Lambert, Blinn-Phong, GGX, Fresnel, Schlick, microfacet intuition |
| 14 | Shadows & AO | Hard/soft shadows, SDF ambient occlusion, bias |
| 15 | Reflection & Refraction | Reflection equation, Snell, TIR, iterative paths |
| 16 | Procedural Fields | Frequency, amplitude, FBM, domain warping, ridge/turbulence |
| 17 | Noise | Value/Perlin noise, hashing, gradients, derivative noise |
| 18 | Voronoi | Nearest-site geometry, borders, cellular patterns, architecture |
| 19 | Fractals & DEs | Escape-time maps, Mandelbulb, Mandelbox, distance estimation |
| 20 | Distance Estimators | Running derivative, Hubbard–Douady, precision analysis |
| 21 | Volumetrics | Density fields, participating media, light marching, fog |
| 22 | Animation | Time as a parameter; phase, frequency, easing, traveling waves |
| 23 | Camera Mathematics | Perspective/orthographic, ray generation, orbits, ray differentials |
| 24 | Numerical Analysis | Floating point, catastrophic cancellation, epsilon, banding |
| 25 | Performance | The cost model, bounds, early exit, precision tradeoffs |
| 26 | Shader Golf | Mathematical compression, not token golf |
| 27 | Reverse Engineering | A systematic reconstruction process for unknown shaders |
| 28 | Complete Projects | 12 projects from sphere tracer to ShaderToy-style artwork |
| 29 | Shader Invention | The generative design methodology (the book's core) |
| 30 | Reference | Formulary: SDFs, transforms, noise, lighting, GLSL, checklists |
| 31 | **Advanced Distance Theory** *(graduate-level)* | Convergence certification, the eikonal equation, Harnack tracing, curved-ray marching |
| 32 | **Advanced Shader Breakdowns** | Real XorDev / Quilez fragments expanded into rigorous math, derived, and extended |
| 33 | **Fluid Simulation & SDF Engines** | SPH discretization, SDF fluid–solid coupling, Claybook's world SDF, Dreams' CSG→splat pipeline, performance/numerics |

### Appendices (in `30-reference/`)

| Appendix | Contents |
|----------|----------|
| A | Notation |
| B | Vector identities |
| C | Matrix identities |
| D | Trigonometric identities |
| E | Common SDF formulas |
| F | Common transformations |
| G | Common noise equations |
| H | Common lighting equations |
| I | Raymarching algorithms |
| J | Distance estimator patterns |
| K | GLSL mathematical reference |
| L | Numerical stability checklist |
| M | Performance checklist |
| N | Shader debugging checklist |
| O | Recommended literature & papers |

---

## The one idea

> **A raymarched shader is a mathematical model evaluated millions of times by a GPU.**

Everything else in this book is a consequence of that sentence. If you keep it in mind, you will never be tempted to copy code again — you will instead be asking: *what mathematical system, evaluated at this point, produces this value?*

```
MATHEMATICS → GEOMETRY → FIELD → RAY INTERSECTION → DIFFERENTIAL INFORMATION
           → LIGHT TRANSPORT → COLOR → TIME → IMAGE
```

That direction — from visual imagination to mathematical construction and back — is the true subject of this text.
