# Shader Breakdown 13 — Quaternion Julia Set: A 4D Distance Estimator

Quaternion Julia sets are the natural 3D fractals built from the quaternion extension of the complex quadratic $z\mapsto z^2+c$. They are 4D objects, so the shader slices them by fixing one coordinate (Chapter 8/19). This breakdown derives the **quaternion square**, its **running derivative**, and the **distance estimator (DE)**, and shows how the slice is rendered.

## 1. The fragment (reconstructed key parts)

```glsl
vec4 quatSq(vec4 q){
    return vec4(
        q.x*q.x - q.y*q.y - q.z*q.z - q.w*q.w,   // scalar (real) part
        2.0*q.x*q.y,                             // i
        2.0*q.x*q.z,                             // j
        2.0*q.x*q.w );                           // k
}

float juliaDE(vec4 z, vec4 c){
    vec4 zn = z;
    float dr = 1.0;                       // running derivative magnitude
    for(int i=0;i<100;i++){
        dr = 4.0 * dot(zn,zn) * dr;       // |d/dc of z^2| * dr
        zn = quatSq(zn) + c;
        if(dot(zn,zn) > 4.0) break;
    }
    return 0.3 * log(dot(zn,zn)) * sqrt(dot(zn,zn)/dr);
}

void mainImage(...){
    // slice: fix w = chosen constant
    vec4 z = vec4(normalize-coords, slice);
    float de = juliaDE(z, c);
    ... raymarch ...
}
```

## 2. Mathematics

### 2.1 The quaternion and its square

A quaternion is $q=w+xi+yj+zk$, identified with $(w,x,y,z)$. The square is obtained from the quaternion product $qq$. Using the basis relations $i^2=j^2=k^2=ijk=-1$, the square is

$$
q^2=\big(q.\text{scalar}^2-x^2-y^2-z^2,\ 2\,q.\text{scalar}\,x,\ 2\,q.\text{scalar}\,y,\ 2\,q.\text{scalar}\,z\big).
$$

Let the scalar part be $w$ and the vector part $\mathbf v=(x,y,z)$. Then in vector form,

$$
q^2=(w^2-\lVert\mathbf v\rVert^2,\ 2w\mathbf v).
$$

**Interpretation.** The scalar part is $w^2-\lVert\mathbf v\rVert^2$ (like the real part of $z^2=x^2-y^2$ in 2D) and the vector part is $2w\mathbf v$ (the "i·2xy" term generalized). The quaternion square is the natural 4D analog of the complex square, and it is exactly what gives the 4D Julia set its structure.

### 2.2 The iteration and the "bailout"

The iteration is
$$
z_{k+1}=z_k^2+c,
$$
starting from some $z_0$ (the ray's point, with a fixed slice component as $w$). We stop when $\lVert z_n\rVert^2>4$ (the bailout, analogous to the 2D $|z|>2$). The scalar and vector parts of $c$ are free parameters that determine the fractal.

### 2.3 The running derivative

The DE needs the derivative of $z_n$ with respect to $c$. Differentiating $z^2$ w.r.t. $c$:
$$
\frac{\partial z}{\partial c}\ \text{scales by}\ 2z \ \text{each step}.
$$
The code tracks the **magnitude** of this derivative, `dr`, updated as
$$
dr_{k+1}=4\,\lVert z_k\rVert^2\,dr_k .
$$
The factor $4\lVert z\rVert^2$ is $\lVert\ 2z\ \rVert^2$ — the squared magnitude of the derivative of $z\mapsto z^2$ with respect to the (4D) point. (This is a *scalar* running derivative, the first-order magnitude of the Jacobian; the exact Jacobian is a $4\times4$ matrix, but the scalar is the standard cheap approximation, as in Chapter 20.)

### 2.4 The distance estimator

The DE is
$$
\text{DE}=0.3\,\log\!\big(\lVert z_n\rVert^2\big)\sqrt{\frac{\lVert z_n\rVert^2}{dr}}\,.
$$
Writing $\lVert z_n\rVert=r$ and $dr$ the accumulated derivative, this is
$$
\text{DE}\approx0.3\cdot\log(r^2)\cdot\frac{r}{\sqrt{dr}}=0.6\,\frac{r\log r}{\sqrt{dr}},
$$
which is the **Hubbard–Douady** form $\propto r\log r/|z'|$ (Chapter 20), with the running derivative's magnitude under the root. The $0.3$ constant (rather than the 2D $0.5$) is a tuned safety/scale factor for the 4D case. It is an **estimator** — a conservative approximation, safe to march but not exact.

### 2.5 Slicing 3D from 4D

The Julia set lives in $\mathbb R^4$. To render a 3D image, fix one coordinate — conventionally we look at the 3D "slice" $w=\text{const}$, or we project the 4D ray onto the 3D subspace. The raymarch evaluates `juliaDE` at $\mathbf z=(x,y,z,\text{slice})$, treating the slice as constant. Because the field is a function of all 4 coordinates but we only vary 3 (and fix the 4th), we're taking the **restriction to a 3D affine slice** — and the restriction of an SDF/DE to a slice is a valid 3D field (the metric is inherited, Chapter 8).

## 3. Field-class analysis

| Quantity | Class |
|----------|-------|
| quaternion square | exact map |
| running derivative `dr` | scalar approximation of the Jacobian |
| DE | **distance estimator** (conservative via the 0.3 factor) |
| slice | exact restriction of field to 3D |

So the quaternion Julia is a **distance estimator**, like the Mandelbulb — the 0.3 factor keeps it a *conservative* estimate (safe to march) but it's not an exact SDF. This is the rigorous reason the 3D fractal renders with slight step-conservatism but no tunneling.

## 4. The "thinking process"

1. **Ideas.** "I want a smooth, swirling 3D fractal." → the quaternion Julia, a 4D object.
2. **Algebra.** "How do I square in 4D?" → the quaternion square (scalar $w^2-\lVert\mathbf v\rVert^2$, vector $2w\mathbf v$).
3. **Distance.** "How do I know how far from the surface?" → accumulate the running derivative and apply the Hubbard–Douady DE.
4. **Slice.** "I can only see 3D." → fix one coordinate; the restriction is a valid 3D field.
5. **Safety.** "I must not tunnel." → the 0.3 factor makes the DE conservative.

## 5. Extensions

- **Exact Jacobian via dual numbers.** Replace the scalar `dr` with a full derivative (dual numbers, Chapter 20) for a tighter, less conservative DE.
- **Different algebra.** Use **triplex**/trigonometric power (Mandelbulb) instead of quaternion square, or the **bicomplex**/pseudo-quaternion variants — each is a different 4D algebra giving a different fractal.
- **Animated `c`.** Loop `c` in the 4D parameter space; the fractal morphs. Because `c` enters the field smoothly, the motion is coherent (Chapter 22).
- **Coloring via orbit traps.** Track the min distance of the orbit to a trap set (Chapter 19) for the "metallic banding."
- **Fully 4D camera.** Move the camera *in* the 4th dimension and slice at a time-varying $w$; this is a smooth "fly-through" of the 4D object's cross-sections.

## Exercises

1. **(Derivation)** Derive the quaternion square from the basis relations.
2. **(Derivation)** Derive the running-derivative update $dr_{k+1}=4\lVert z\rVert^2 dr_k$.
3. **(Derivation)** Show the DE reduces to the Hubbard–Douady form $\propto r\log r/|z'|$.
4. **(Analytic)** Explain why fixing one coordinate gives a valid 3D field (the slice restriction).
5. **(Field class)** Classify the quaternion Julia DE and explain the role of the 0.3 factor for safety.
6. **(Design)** Replace the scalar `dr` with a dual-number Jacobian; describe the change in DE tightness and cost.
