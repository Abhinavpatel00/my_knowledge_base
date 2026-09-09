# Chapter 26 — Shader Golf

Extremely compact shaders are not written by hacking tokens. They are written by **compressing the mathematics**. The shortest shaders are the ones whose geometry has been reduced to a single elegant recurrence. This chapter teaches the *mathematical* compression that underlies golf, and the discipline of expanding a golfed shader back into readable mathematics.

## 26.1 The golf pipeline (mathematical compression)

The shortest shaders come from identifying and exploiting *structure*:

```
complex geometry
  → coordinate transform
  → repetition
  → symmetry
  → shared expressions
  → compact function
```

Each step *removes* redundant computation by reusing a field, a transform, or a symmetry. The resulting code is short *because the mathematics is compressed*, not because the tokens were minimized.

## 26.2 Example: an infinite tunnel in a few lines

Consider the classic "rotate space, take a radius" infinite tunnel. The mathematical structure:

1. **Base primitive:** an infinite cylinder (tunnel) — `length(p.xz)-r`.
2. **Repetition:** tile along the axis (a corridor).
3. **Twist/rotation:** rotate the sample to create a spiral.

A golfed shader might be:

```glsl
vec3 p = ro + rd*t;
p.xz = rot(p.xz, 0.1);       // rotate for spiral
p = mod(p, 2.0)-1.0;         // repeat (tile) the tunnel
float d = length(p)-0.3;      // the tunnel wall
```

Expanding into math:

- `p = mod(p,2)-1` is **centered repetition** (Chapter 11) — an exact SDF along each axis.
- `rot` is **domain rotation** — an isometry, exact.
- `length(p)-r` is the **infinite cylinder** SDF.

So the whole golfed shader is just "repeat a rotated cylinder." The compactness comes from the fact that repetition + rotation + cylinder are each *one line*, and the combination produces a spiral tunnel. Length was achieved by *choosing a structure with few operations*, not by removing characters.

## 26.3 The discipline: expand before compressing

The rule that makes golf educational:

> **Expand the shader mathematically first, then compress it again.**

For any golfed shader:

1. **Recognize the field.** What function is being evaluated? Is it a cylinder, box, torus, or a repeated/transformed version?
2. **Identify the transforms.** Which coordinates are rotated, folded, repeated, twisted?
3. **Identify the symmetries.** Where is `abs`, `mod`, `rotared` folding the space?
4. **Write the equations.** Turn each line into a mathematical operation.
5. **Verify the distance class.** Is it exact? A bound? An estimator?
6. **Re-compress.** Now that you understand the structure, you can make it *even better* — but now deliberately, knowing what you're sacrificing.

## 26.4 The toolbox of "golfable" operations

Operations that both compress code *and* are mathematically meaningful:

| Operation | Why it golfs | Mathematics | Distance class |
|-----------|--------------|-------------|----------------|
| `length` | a `sqrt` + normalization in one token | Euclidean norm | exact (for the primitive) |
| `abs` | a mirrored fold in one token | reflection | exact (isometry) |
| `mod` | infinite repetition in one token | periodization | exact along axis |
| `rot` | domain rotation in one token | isometry | exact |
| `mix` | interpolation/blend | lerp | bound |
| `clamp` | range limiting | min/max | often a bound |
| `fract` | lattice cell position | fractional part | exact (map input) |

**The general "shared expression" trick.** If `p` is used multiple times, or if a sub-expression (like a rotation of `p`) is reused, compute it once. This reduces the *arithmetic* as well as the tokens.

## 26.5 Worked golf examples

### Simple sphere

```glsl
float d = length(p) - 1.0;
```

Math: $d=\lVert\mathbf p\rVert-1$. One line. The golf is *the sphere itself*.

### Box via the L-shape

```glsl
vec3 q = abs(p)-.5;
float d = length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
```

Math: the box SDF (Chapter 08). Three lines, but it's a *complete* exact SDF. The compression is that the "outside" and "inside" terms are both captured by `q`.

### Repeated/rotated octahedron

```glsl
p = abs(p);
float d = (dot(p,p) .5) ... // an octahedron via a fold
```

Math: `abs(p)` is a mirror fold; the octahedron's distance is a fold of the $L^1$ ball. This is a *kaleidoscopic* fold — pure symmetry.

## 26.6 The mathematical origin of "XorDev-style" minimalism

The terse shaders associated with artists like XorDev are minimal *because they leverage symmetry and repetition to the extreme*: a few `abs`, `mod`/`fract`, and `rot` operations, combined with a single primitive field, generate an entire complex environment. The visual richness comes almost entirely from the *repetition and folding* of a tiny base field (the "structure machine" of Chapter 11).

The educational takeaway: **understand the structure** (which primitive, which transform, which repetition), and you can read and even *invent* such shaders. The shader's brevity is a symptom of the mathematics being compressed.

## 26.7 The cost of golf: what you give up

Golfing for its own sake can hide *bugs* or *unsafe fields* (a too-short shader might be an overestimating estimator that tunnels through geometry). The discipline is to **prioritize mathematical correctness over token count.** A golfed shader is only worth understanding if it's *both* short *and* correct. The book teaches golf as a *compression of correct mathematics*, never as a replacement for correctness.

## Exercises

1. **(Expand)** Take a minimal sphere-tracer and expand each line into its mathematical definition including the camera and ray generation.
2. **(Expand)** Take the `vec3 q=abs(p)-.5; length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)` box and expand to the box SDF derivation.
3. **(Recognize)** Given `p=mod(p+3.,6.)-3.; float d=length(p.xz)-1.;` identify the primitive and repetition; state the distance class.
4. **(Compress)** Write a spiral tunnel in a few lines, then expand it; explain each transform.
5. **(Analyze)** In a golfed shader, identify where the field may be a *bound* rather than exact, and explain the consequence.
6. **(Design)** Using only `abs`, `mod`, `rot`, and a cylinder, build a kaleidoscopic structure; describe the visual.
