# Preface

## Who this book is for

This book is for a reader who wants to **create** raymarched imagery — the abstract, procedural, surreal, geometric, organic, fractal, and volumetric work common in sophisticated ShaderToy-style art — and who wants to understand it as mathematics rather than as a bag of tricks.

The prerequisites are modest but real:

- Calculus through gradients, partial derivatives, and the chain rule.
- Basic linear algebra: vectors, dot and cross products, matrices, matrix-vector products.
- A working knowledge of a C-like language (GLSL, HLSL, C, or any of them) sufficient to read pseudocode.
- Patience. The material is deep on purpose.

The intended reader should finish this book able to do more than *raymarch a sphere*. They should be able to

> formulate an entirely new mathematical field whose zero-set generates the structure they imagined.

That is the standard this text holds itself to.

## The governing philosophy

Most "raymarching tutorials" present a sequence of GLSL functions and let the reader infer the underlying mathematics. That is backwards. The dominant metaphor of this book is:

> The shader is the *executable form* of a mathematical model.

A fragment shader evaluates some function at every pixel, every frame. The interesting object is the function. The skeleton of that function — from camera through ray, field, intersection, normal, lighting, color, time — is a mathematical pipeline. Every stage can be written down as an equation before it is ever written as code.

Consequently, this book's core discipline is:

```
MATHEMATICS → GEOMETRY → FIELD → RAY INTERSECTION → DIFFERENTIAL INFORMATION
           → LIGHT TRANSPORT → COLOR → TIME → IMAGE
```

## A taxonomy the book insists on

Authors in this space use *implicit surface*, *scalar field*, *level set*, *signed distance field*, *unsigned distance field*, *distance estimator*, *distance bound*, *density field*, *potential field*, *height field*, and *occupancy field* almost interchangeably. **This book does not.** These are different objects with different safety properties for a ray marcher, and conflating them is the most common source of subtle artifacts and silent unsafety.

The four degrees of freedom that matter:

| Object | Definition | What a ray marcher may do safely |
|--------|-----------|---------------------------------|
| **Exact SDF** | $d(\mathbf p)=\min_{\mathbf q\in S}\lVert\mathbf p-\mathbf q\rVert$ signed | Step by the full value; provably never overshoots. |
| **Distance bound** | $\hat d(\mathbf p)\le d(\mathbf p)$, signed bound | Step by $\hat d$; still never overshoots. |
| **Distance estimator** | $D(\mathbf p)\approx d(\mathbf p)$ (often $\le$ but not proven) | Step by $D$ *if* it is a true bound; otherwise risky. |
| **Arbitrary scalar field** | $f(\mathbf p)\in\mathbb R$ | Nothing, in general. |

The fourth column is the entire reason the first three must be kept separate. We will revisit this taxonomy throughout. (See Chapters 05, 06, and 20.)

## Learning progression

This book is arranged so each level builds on the previous one. Do not skip ahead.

```
LEVEL 0   Mathematical prerequisites                       (Ch 01–04)
LEVEL 1   Vectors + geometry                               (Ch 02–03)
LEVEL 2   Implicit surfaces                                (Ch 05)
LEVEL 3   Distance fields                                  (Ch 06)
LEVEL 4   Ray marching                                     (Ch 07)
LEVEL 5   SDF primitives                                   (Ch 08)
LEVEL 6   SDF composition                                  (Ch 09)
LEVEL 7   Coordinate transformations                      (Ch 10)
LEVEL 8   Differential geometry                           (Ch 12)
LEVEL 9   Lighting                                         (Ch 13)
LEVEL 10  Procedural deformation                          (Ch 16)
LEVEL 11  Noise + fields                                  (Ch 17)
LEVEL 12  Fractals + DEs                                  (Ch 19–20)
LEVEL 13  Volumetrics                                     (Ch 21)
LEVEL 14  Advanced rendering                              (Ch 14–15)
LEVEL 15  Shader architecture                             (Ch 23, 25)
LEVEL 16  Reverse engineering                             (Ch 27)
LEVEL 17  Shader invention                                (Ch 29)
LEVEL 18  Shader optimization                             (Ch 25)
LEVEL 19  Shader golf                                     (Ch 26)
```

## Conventions

- Vectors are boldface: $\mathbf p$, $\mathbf n$, $\mathbf d$. Scalars are italic: $t$, $r$, $k$.
- The Euclidean norm is $\lVert\mathbf x\rVert=\sqrt{\mathbf x\cdot\mathbf x}$.
- The dot product is $\mathbf a\cdot\mathbf b$; the cross product is $\mathbf a\times\mathbf b$.
- $S\subset\mathbb R^3$ denotes a surface or solid. $d(\mathbf p,S)$ is the (unsigned) distance; $f_S$ denotes a signed field.
- $\nabla f$, $J_f$, $H_f$ denote the gradient, Jacobian, and Hessian.
- Level zero is a point $\mathbf o$; the ray is $\mathbf r(t)=\mathbf o+t\mathbf d$, always with $\lVert\mathbf d\rVert=1$ unless stated otherwise.
- GLSL examples target GLSL ES / ShaderToy. ShaderToy supplies `iResolution` (pixel), `iTime`, `iMouse`, and the fragment input `fragCoord`.
- "Safe" always means: *the marching step cannot pass through the surface, given a distance bound.*

## About the code policy

Code is subordinate to mathematics. Every substantial GLSL function is introduced as

```
MATHEMATICAL EQUATION → PSEUDOCODE → GLSL
```

It is never the reverse. Where a function is a known result from a named author or paper, the text derives it from first principles and cites the origin. Where a formula is standard mathematics, the text derives or proves it directly. Nothing is presented as "trust me."

## Sourcing and intellectual honesty

This work synthesizes publicly available material into a single coherent mathematical framework. The primary technical roots are John C. Hart's *Sphere Tracing* (1995) work; the implicit-surface and distance-function material of Iñigo Quilez and the ShaderToy community; the distance-estimation theory of Douady–Hubbard and Hart *et al.*; fractal construction work for the Mandelbulb (White/Nylander) and Mandelbox (Tom Lowe / Buddhi / the Fractal Forums community); and standard texts in geometry, differential geometry, numerical analysis, and physically based rendering.

Where sources disagree, the book states the disagreement and the assumptions behind each formulation rather than merging them silently.

On the matter of copying: this is a *derivation-based* text. It does not reproduce verbatim passages from any source; it understands, derives, and re-explains. Quotations are limited to mathematical formulas, which are not copyrightable, and to brief attributions.

## A note on the difficulty

Some parts of this book are genuinely hard. Where a derivation needs advanced mathematics, the prerequisite mathematics is introduced *first*. This book will not replace a difficult derivation with *"here is the formula; trust me."* Doing so would defeat its entire purpose.

---

**Next:** [Chapter 01 — Mathematical Foundations](../01-mathematical-foundations/foundations.md)
