# Mathematical Formulation of the Golfed Raymarching Shader

The shader is

```glsl
vec3 p,a;
for(float i,z,d,s;z+i++<2e2;o+=max(cos(p.x*.4+vec4(0,2,4,0)),5./s/s)/d/d)
    p=z*normalize(FC.rgb*2.-r.xyy),
    p.z+=9.,
    s=length(p=dot(a=normalize(cos(vec3(0,2,4)-t*.5+s*.3)),p)*a-cross(a,p)),
    z+=d=min(abs(dot(p,sin(p).yzx))*.2+max(d=s-5.,.1),abs(--d)+.2)*.2;
o=tanh(o/3e4);
```

> **Important implementation note.** The mathematical derivation below assumes the intended scalar state starts at $i_0=z_0=d_0=s_0=0$. The compact shader declaration does not itself make those initialization semantics explicit. The derivation therefore describes the intended recurrence rather than relying on unspecified language behavior.

## 1. Mathematical Overview

The shader can be understood as a composition of four major systems:

1. A camera ray parameterization.
2. A radius-dependent rotation field.
3. A hybrid implicit distance estimator.
4. A singular glow accumulation followed by nonlinear tone mapping.

At the highest level,

$$
\boxed{
\text{ray}
\rightarrow
\text{domain warp}
\rightarrow
\text{implicit field}
\rightarrow
\text{distance estimate}
\rightarrow
\text{ray march}
\rightarrow
\text{radiance accumulation}
\rightarrow
\text{tone mapping}
}
$$

The important idea is that the shader is not built from one mysterious geometric equation. It is built by composing comparatively simple mathematical operators.

---

## 2. Ray Parameterization

Let the normalized camera direction be

$$

\hat{\omega}
=
\frac{2FC-r_{xyy}}{\left\|2FC-r_{xyy}\right\|},
$$

where

$$
r_{xyy}=(r_x,r_y,r_y).
$$

The ray-space point at accumulated distance $z$ is

$$
\boxed{
q(z)=z\hat{\omega}+9e_z
}
$$

with

$$
 e_z=(0,0,1).
$$

Since $\hat{\omega}$ is normalized,

$$
\left\|\hat{\omega}\right\|=1.
$$

Therefore $z$ acts as a unit-speed affine ray parameter.

The derivative is

$$
\frac{dq}{dz}=\hat{\omega}.
$$

So the ray is a straight line in the unwarped coordinate system.

---

## 3. The Hidden Structure of the Rotation

The shader constructs the vector

$$
(a\cdot q)a-a\times q.
$$

Assume

$$
\|a\|=1.
$$

Rodrigues' rotation formula is

$$
R_a(\theta)q
=
q\cos\theta
+(a\times q)\sin\theta
+a(a\cdot q)(1-\cos\theta).
$$

Set

$$
\theta=-\frac{\pi}{2}.
$$

Then

$$
\cos\theta=0,
\qquad
\sin\theta=-1,
$$

and therefore

$$
R_a\left(-\frac{\pi}{2}\right)q
=
-a\times q+a(a\cdot q).
$$

Hence

$$
\boxed{
(a\cdot q)a-a\times q
=
R_a\left(-\frac{\pi}{2}\right)q.
}
$$

The shader is therefore performing an exact $90^\circ$ rotation around the unit axis $a$.

The corresponding rotation matrix is

$$
\boxed{
R_a\left(-\frac{\pi}{2}\right)=aa^T-[a]_\times
}
$$

where

$$
[a]_\times
=
\begin{pmatrix}
0&-a_z&a_y\\
 a_z&0&-a_x\\
-a_y&a_x&0
\end{pmatrix}.
$$

It satisfies

$$
R_a^TR_a=I,
\qquad
\det R_a=1,
$$

so

$$
R_a\in SO(3).
$$

Thus the transformation itself is a rigid rotation.

---

## 4. Why $s$ Simplifies to a Radius

The shader writes

$$
 s
=
\left\|
(a\cdot q)a-a\times q
\right\|.
$$

Because the expression inside the norm is a rotation of $q$,

$$
\left\|
(a\cdot q)a-a\times q
\right\|
=
\|q\|.
$$

Hence

$$
\boxed{s=\|q\|.}
$$

With

$$
q=z\hat{\omega}+9e_z,
$$

we get

$$
s^2
=
\left\|z\hat{\omega}+9e_z\right\|^2.
$$

Expanding,

$$
s^2
=z^2\|\hat{\omega}\|^2
+18z\hat{\omega}_z
+81.
$$

Since $\|\hat{\omega}\|=1$,

$$
\boxed{
s
=
\sqrt{z^2+18z\hat{\omega}_z+81}
}
$$

Therefore the apparently complicated state variable $s$ is simply the radial distance of the current point from the origin.

This is a major simplification.

---

## 5. Construction of the Rotation Axis

Define

$$
\mathbf{1}
=
\begin{pmatrix}
1\\1\\1
\end{pmatrix}
$$

and

$$
\phi(s,t)
=
\begin{pmatrix}
0\\2\\4
\end{pmatrix}
-
\frac{t}{2}\mathbf{1}
+
0.3s\mathbf{1}.
$$

Explicitly,

$$
\phi(s,t)
=
\begin{pmatrix}
-\frac{t}{2}+0.3s\\
2-\frac{t}{2}+0.3s\\
4-\frac{t}{2}+0.3s
\end{pmatrix}.
$$

The shader then constructs

$$
 c(s,t)=\cos\phi(s,t),
$$

componentwise, and normalizes it:

$$
\boxed{
 a(s,t)
=
\frac{c(s,t)}{\|c(s,t)\|}.
}
$$

Thus the rotation axis varies with both radius and time.

The temporal phase velocity is

$$
\frac{\partial\phi}{\partial t}
=-\frac12\mathbf{1},
$$

while the radial phase velocity is

$$
\frac{\partial\phi}{\partial s}
=0.3\mathbf{1}.
$$

Therefore moving outward in space and advancing in time both shift the orientation field.

---

## 6. The Nonlinear Domain Warp

Let

$$
q=q(z)
$$

and define

$$
\boxed{
x(q,t)
=
R_{a(\|q\|,t)}\left(-\frac{\pi}{2}\right)q.
}
$$

This is a position-dependent rotation field.

For a fixed radius $s$, the transformation is a rigid rotation, so

$$
\|x\|=\|q\|=s.
$$

The nonlinearity does not come from the rotation itself. It comes from the fact that the rotation axis changes with position through

$$
a=a(\|q\|,t).
$$

This is a classic domain-warp construction:

$$
\boxed{
\text{complex visible geometry}
=
\text{simple field}\circ\text{nonlinear coordinate map}.
}
$$

---

## 7. The Cyclic Trigonometric Implicit Field

After the rotation, write

$$
x=(x,y,z).
$$

The shader evaluates

$$
\operatorname{dot}\left(x,\sin(x)^{yzx}\right).
$$

The permutation $yzx$ means

$$
\sin(x)^{yzx}
=
\begin{pmatrix}
\sin y\\
\sin z\\
\sin x
\end{pmatrix}.
$$

Therefore the scalar field is

$$
\boxed{
 g(x,y,z)
=
x\sin y+y\sin z+z\sin x.
}
$$

The corresponding implicit surface family is

$$
\boxed{
 g(x,y,z)=0.
}
$$

This differs fundamentally from a sphere such as

$$
x^2+y^2+z^2-R^2=0.
$$

Here the coordinates are cyclically coupled:

$$
x\leftrightarrow y,
\qquad
y\leftrightarrow z,
\qquad
z\leftrightarrow x.
$$

That coupling creates a periodic, non-separable geometry.

---

## 8. Differential Geometry of the Base Surface

For

$$
g(x,y,z)=x\sin y+y\sin z+z\sin x,
$$

the gradient is

$$
\boxed{
\nabla g
=
\begin{pmatrix}
\sin y+z\cos x\\
 x\cos y+\sin z\\
 y\cos z+\sin x
\end{pmatrix}.
}
$$

Whenever

$$
\nabla g\neq0,
$$

the implicit function theorem guarantees that $g=0$ locally defines a smooth two-dimensional manifold.

Its unit normal is

$$
\boxed{
 n_g=
\frac{\nabla g}{\|\nabla g\|}.
}
$$

The shader does not calculate this analytic normal, but this gradient is the underlying differential-geometric object controlling the local orientation of the implicit surface.

---

## 9. The Two Competing Geometric Fields

The distance estimator contains two branches.

Define

$$
F_1(x)
=
0.2|g(x)|+\max(s-5,0.1),
$$

where

$$
s=\|x\|,
$$

and define

$$
F_2(x)=|s-6|+0.2.
$$

The final scalar field is

$$
\boxed{
D(x)
=
0.2\min\left(F_1(x),F_2(x)\right).
}
$$

Explicitly,

$$
\boxed{
D(x)
=
0.2
\min
\left[
0.2\left|x\sin y+y\sin z+z\sin x\right|
+\max(\|x\|-5,0.1),
|\|x\|-6|+0.2
\right].
}
$$

The two branches represent different geometric mechanisms.

---

## 10. Interpretation of the First Branch

The first branch is

$$
F_1(x)
=
0.2|g(x)|+\max(s-5,0.1).
$$

The term

$$
|g(x)|
$$

measures algebraic proximity to the zero set

$$
g(x)=0.
$$

It is not, in general, the exact Euclidean distance to that surface.

A first-order approximation to the distance from $x$ to an implicit surface is

$$
\boxed{
\operatorname{dist}(x,g=0)
\approx
\frac{|g(x)|}{\|\nabla g(x)\|}.
}
$$

The shader omits the denominator and instead uses the heuristic scaling factor $0.2$.

The radial term is

$$
\max(s-5,0.1).
$$

For $s>5$ this becomes

$$
s-5,
$$

while for $s\le5$ it is clamped to $0.1$.

Therefore the first branch is approximately

$$
\boxed{
\text{periodic surface proximity}
+
\text{radial envelope}.
}
$$

---

## 11. Interpretation of the Second Branch

The second branch is

$$
F_2(x)=|s-6|+0.2.
$$

The zero set of $|s-6|$ is

$$
s=6,
$$

which is the sphere of radius $6$ centered at the origin.

Thus

$$
\boxed{
F_2
=
\text{distance-like measure to a spherical shell}
+0.2.
}
$$

The minimum operator allows this shell and the trigonometric structure to compete for control of the final field.

---

## 12. The Minimum as a Union Operator

Suppose two fields $D_A$ and $D_B$ approximate distances to two shapes. Then a standard constructive-union operation is

$$
D_{A\cup B}(x)
\approx
\min(D_A(x),D_B(x)).
$$

Therefore

$$
\boxed{
D(x)=0.2\min(F_1(x),F_2(x))
}
$$

can be interpreted as a procedural union or lower envelope.

More explicitly,

$$
D(x)=
\begin{cases}
0.2F_1(x), & F_1(x)\le F_2(x),\\
0.2F_2(x), & F_2(x)<F_1(x).
\end{cases}
$$

The switching surface satisfies

$$
F_1(x)=F_2(x).
$$

That surface is where the two geometric descriptions exchange control.

---

## 13. Reconstructed Ray-Marching Recurrence

Let the intended initial state be

$$
 z_0=0,
\qquad
 s_0=0,
\qquad
 i_0=0.
$$

At iteration $n$,

$$
q_n=z_n\hat{\omega}+9e_z,
$$

$$
s_n=\|q_n\|,
$$

$$
a_n=
\frac{
\cos\left(
\begin{pmatrix}
0\\2\\4
\end{pmatrix}
-\frac t2\mathbf{1}
+0.3s_n\mathbf{1}
\right)
}{
\left\|
\cos\left(
\begin{pmatrix}
0\\2\\4
\end{pmatrix}
-\frac t2\mathbf{1}
+0.3s_n\mathbf{1}
\right)
\right\|
},
$$

and

$$
 x_n
=
(a_n\cdot q_n)a_n-a_n\times q_n.
$$

Then

$$
 g_n
=
 x_{n,x}\sin x_{n,y}
+x_{n,y}\sin x_{n,z}
+x_{n,z}\sin x_{n,x}.
$$

Define

$$
 A_n
=
0.2|g_n|+\max(s_n-5,0.1),
$$

and

$$
 B_n
=|s_n-6|+0.2.
$$

The marching distance is

$$
\boxed{
 d_n=0.2\min(A_n,B_n).
}
$$

The ray parameter is then advanced by

$$
\boxed{
 z_{n+1}=z_n+d_n.
}
$$

This is the central numerical recurrence.

---

## 14. Why This Is Ray Marching

The classical ray equation is

$$
q(z)=q_0+z\hat{\omega}.
$$

An ordinary ray tracer may seek an exact solution of

$$
F(q(z))=0.
$$

Ray marching instead repeatedly evaluates a distance-like field and advances along the ray:

$$
\boxed{
z_{n+1}=z_n+D(q_n).
}
$$

The fundamental assumption of sphere tracing is that $D$ is sufficiently conservative that a step of size $D$ does not cross the surface.

For a true signed distance field,

$$
\|\nabla D\|=1
$$

almost everywhere.

The field here is not an exact SDF. It is better viewed as a heuristic procedural distance estimator.

---

## 15. Lipschitz Perspective

A function $D$ is Lipschitz with constant $L$ if

$$
|D(x)-D(y)|
\le
L\|x-y\|.
$$

When a distance field is sufficiently well behaved, the Lipschitz constant controls how quickly the field can change in space.

For a true Euclidean signed distance field, one has the important property

$$
\|\nabla D\|=1
$$

almost everywhere, corresponding to a local Lipschitz constant of $1$.

For

$$
g=x\sin y+y\sin z+z\sin x,
$$

the gradient magnitude is not bounded by $1$ in any useful global sense.

Consequently

$$
|g(x)|
$$

is not itself a safe Euclidean distance.

The shader's factors such as $0.2$ can be interpreted as empirical contraction factors that make the ray marcher less aggressive.

They are useful heuristics, not proofs of geometric safety.

---

## 16. The Iteration Budget

The loop condition is approximately

$$
z+i<200.
$$

With $i_n=n$, the recurrence is therefore terminated while

$$
\boxed{
z_n+n<200.
}
$$

This is different from a fixed iteration count

$$
n<N_{\max}.
$$

Here both marching depth and iteration count consume the same budget.

Large steps increase $z_n$ rapidly and therefore shorten the number of remaining iterations.

Small steps allow more iterations.

Thus the computational budget is coupled to geometric complexity.

---

## 17. Radiance Accumulation

The color contribution is approximately

$$
\frac{
\max\left(\cos(0.4x_x+\phi),5/s^2\right)
}{d^2},
$$

where the RGB phase vector is

$$
\phi=(0,2,4).
$$

Define the RGB numerator

$$
H(x,s)
=
\max\left[
\begin{pmatrix}
\cos(0.4x_x)\\
\cos(0.4x_x+2)\\
\cos(0.4x_x+4)
\end{pmatrix},
\frac5{s^2}
\begin{pmatrix}
1\\1\\1
\end{pmatrix}
\right],
$$

where the maximum is taken componentwise.

The accumulated color after $N$ steps is therefore

$$
\boxed{
O_N
=
\sum_{n=0}^{N-1}
\frac{H(x_n,s_n)}{d_n^2}.
}
$$

The $1/d_n^2$ term strongly emphasizes samples close to the procedural geometry.

---

## 18. Singular Kernel Interpretation

The glow kernel is

$$
K(d)=\frac1{d^2}.
$$

As $d\to0^+$,

$$
\lim_{d\to0^+}\frac1{d^2}=+\infty.
$$

Thus the shader intentionally uses a singular proximity response.

A continuous analogue is

$$
\boxed{
C
\sim
\int
\frac{H(x(z))}{D(x(z))^2}\,dz.
}
$$

The shader approximates such an integral using an adaptive sequence of samples.

Importantly, this is not a physically based volume-rendering equation. It is a procedural glow model in which proximity to the field is converted into high intensity.

---

## 19. Continuous Interpretation

Let

$$
q(z)=z\hat{\omega}+9e_z.
$$

Define

$$
s(z)=\|q(z)\|,
$$

and

$$
a(z,t)=
\frac{
\cos((0,2,4)^T-\tfrac t2\mathbf{1}+0.3s(z)\mathbf{1})
}{
\left\|
\cos((0,2,4)^T-\tfrac t2\mathbf{1}+0.3s(z)\mathbf{1})
\right\|
}.
$$

Then

$$
x(z,t)
=
R_{a(z,t)}\left(-\frac\pi2\right)q(z).
$$

Define

$$
D(z,t)
=
0.2\min\left[
0.2|g(x(z,t))|+\max(s(z)-5,0.1),
|s(z)-6|+0.2
\right].
$$

The continuous rendering model is then conceptually

$$
\boxed{
C(\hat\omega,t)
\approx
T
\left[
\int
\frac{H(x(z,t),s(z))}{D(z,t)^2}\,dz
\right].
}
$$

The actual shader uses a discrete and adaptive approximation of this integral.

---

## 20. Why the Domain Warp Creates Complexity

Without the warp, the base surface is simply

$$
 g(q)=0.
$$

With the warp, the visible surface is defined by

$$
\boxed{
G(q,t)=g(W(q,t))=0,
}
$$

where

$$
W(q,t)=R_{a(\|q\|,t)}\left(-\frac\pi2\right)q.
$$

A composition of nonlinear maps can create complicated geometry even when each map is individually simple.

This is one of the most important principles in procedural graphics:

$$
\boxed{
\text{simple implicit field}
+
\text{nonlinear coordinate transformation}
=
\text{complex apparent geometry}.
}
$$

---

## 21. Chain Rule for a Warped Implicit Field

Suppose

$$
F(q,t)=F_0(W(q,t)).
$$

Then by the multivariable chain rule,

$$
\boxed{
\nabla F(q,t)
=
J_W(q,t)^T\nabla F_0(W(q,t)),
}
$$

where

$$
J_W
=\frac{\partial W}{\partial q}
$$

is the Jacobian of the warp.

For this shader,

$$
F_0(x)=x\sin y+y\sin z+z\sin x.
$$

The warp is

$$
W(q,t)=R_{a(\|q\|,t)}\left(-\frac\pi2\right)q.
$$

The rotation matrix itself is perfectly conditioned, but the full Jacobian contains derivatives of the axis $a(\|q\|,t)$.

That is where the real nonlinearity enters.

---

## 22. Derivative of the Normalized Axis

Let

$$
a=\frac{c}{\|c\|}.
$$

For any scalar parameter $u$,

$$
\boxed{
\frac{\partial a}{\partial u}
=
\frac1{\|c\|}
(I-aa^T)
\frac{\partial c}{\partial u}.
}
$$

Here

$$
 c(s,t)=\cos\phi(s,t).
$$

Therefore

$$
\frac{\partial c}{\partial s}
=-0.3\sin\phi,
$$

so

$$
\boxed{
\frac{\partial a}{\partial s}
=
-\frac{0.3}{\|c\|}
(I-aa^T)\sin\phi.
}
$$

The projector

$$
I-aa^T
$$

removes the component parallel to $a$.

This is the standard differential formula for normalizing a vector field.

---

## 23. Generalized Rotation Field

The fixed angle $-\pi/2$ can be generalized to a spatially and temporally varying angle

$$
\theta=\theta(s,t).
$$

Rodrigues' formula gives

$$
\boxed{
W(q,s,t)
=
q\cos\theta
+(a\times q)\sin\theta
+a(a\cdot q)(1-\cos\theta).
}
$$

For example,

$$
\theta(s,t)=\theta_0+\alpha s+\beta t
$$

creates a radial and temporal twist.

The original shader is the special case

$$
\theta=-\frac\pi2.
$$

---

## 24. Fourier Orientation Fields

The single cosine harmonic can be generalized to a finite Fourier field:

$$
\boxed{
 a(s,t)=
\operatorname{normalize}
\left[
\sum_{k=1}^{K}
 A_k\cos(\omega_k s+\nu_k t+\phi_k)
\right].
}
$$

This gives direct control over radial frequency, temporal frequency, amplitude, and phase.

The current shader is essentially the single-harmonic case with three different fixed phase offsets.

---

## 25. Smooth Union

The hard minimum

$$
\min(a,b)
$$

can be replaced by a smooth minimum such as

$$
\boxed{
\operatorname{smin}_k(a,b)
=
-\frac1k\log\left(e^{-ka}+e^{-kb}\right).
}
$$

As

$$
k\to\infty,
$$

we obtain

$$
\operatorname{smin}_k(a,b)\to\min(a,b).
$$

This is useful when constructing differentiable geometry.

---

## 26. Smooth Absolute Value

The absolute value function has a nondifferentiable point at zero.

A smooth approximation is

$$
\boxed{
|x|\approx\sqrt{x^2+\varepsilon^2}.
}
$$

Therefore

$$
|g(x)|
$$

can be replaced by

$$
\sqrt{g(x)^2+\varepsilon^2}.
$$

Likewise,

$$
|s-6|
$$

can be replaced by

$$
\sqrt{(s-6)^2+\varepsilon^2}.
$$

This is particularly useful when analytic gradients and normals are required.

---

## 27. Alternative Glow Kernels

The current kernel is

$$
K(d)=d^{-2}.
$$

A regularized version is

$$
\boxed{
K_\varepsilon(d)=\frac1{d^2+\varepsilon^2}.
}
$$

An exponential kernel is

$$
\boxed{
K(d)=e^{-kd}.
}
$$

A Gaussian-like kernel is

$$
\boxed{
K(d)=e^{-kd^2}.
}
$$

A generalized inverse-power family is

$$
\boxed{
K(d)=\frac1{(d^2+\varepsilon^2)^{p/2}}.
}
$$

The shader approximately corresponds to

$$
p=2.
$$

Thus the appearance model can be regarded as a tunable proximity kernel.

---

## 28. Iterated Domain Warping

Instead of applying the warp once, define

$$
x_0=q,
$$

and recursively

$$
\boxed{
x_{k+1}=W(x_k,t).
}
$$

After $K$ iterations,

$$
 x_K=W^{\circ K}(q,t).
$$

The final field is

$$
\boxed{
F(q,t)=F_0(x_K).
}
$$

The Jacobian becomes

$$
J_{W^{\circ K}}
=
J_W(x_{K-1})\cdots J_W(x_0).
$$

Hence repeated composition can cause the derivative magnitude to grow dramatically.

That is both a source of visual richness and a source of numerical instability.

---

## 29. Multiscale Procedural Fields

A simple field can be turned into a multiscale construction using

$$
\boxed{
F(x)
=
\sum_{k=0}^{K}
\lambda_kF_0(2^kx).
}
$$

After applying a warp,

$$
\boxed{
F_{\mathrm{final}}(x,t)
=
\sum_{k=0}^{K}
\lambda_k
F_0(2^kW(x,t)).
}
$$

This creates controlled spatial frequencies and can produce fractal-like procedural structures.

---

## 30. A General Procedural Ray-Marching Framework

The shader is a specific instance of the following general system.

Start with a ray

$$
q_n=q_0+z_n\hat\omega.
$$

Construct a state-dependent warp

$$
 x_n=W(q_n,t,\sigma_n).
$$

Construct a state variable

$$
\sigma_n=S(x_n,t,\sigma_n).
$$

Construct a distance estimator

$$
 d_n=F(x_n,\sigma_n).
$$

Advance the ray:

$$
 z_{n+1}=z_n+d_n.
$$

Accumulate appearance:

$$
 L_{n+1}=L_n+K(d_n,x_n,t).
$$

Finally tone map:

$$
 C=T(L_N).
$$

Therefore the general rendering architecture is

$$
\boxed{
q
\rightarrow
W
\rightarrow
F
\rightarrow
D
\rightarrow
\text{adaptive sampling}
\rightarrow
K
\rightarrow
T.
}
$$

Your shader chooses

$$
W(q)=R_{a(\|q\|,t)}\left(-\frac\pi2\right)q,
$$

$$
F_0(x,y,z)=x\sin y+y\sin z+z\sin x,
$$

and a minimum between a periodic field and a radial shell.

---

## 31. Final Discrete Rendering Formula

Define

$$
\hat\omega
=
\frac{2FC-r_{xyy}}
{\left\|2FC-r_{xyy}\right\|}.
$$

For every marching step $n$,

$$
q_n=z_n\hat\omega+9e_z,
$$

$$
 s_n=\|q_n\|,
$$

$$
a_n=
\frac{
\cos((0,2,4)^T-\frac t2\mathbf 1+0.3s_n\mathbf 1)
}{
\left\|
\cos((0,2,4)^T-\frac t2\mathbf 1+0.3s_n\mathbf 1)
\right\|},
$$

$$
x_n=(a_n\cdot q_n)a_n-a_n\times q_n,
$$

$$
g_n=x_{n,x}\sin x_{n,y}
+x_{n,y}\sin x_{n,z}
+x_{n,z}\sin x_{n,x},
$$

$$
A_n=0.2|g_n|+\max(s_n-5,0.1),
$$

$$
B_n=|s_n-6|+0.2,
$$

$$
\boxed{
 d_n=0.2\min(A_n,B_n).
}
$$

The ray recurrence is

$$
\boxed{
 z_{n+1}=z_n+d_n.
}
$$

The accumulated radiance is

$$
\boxed{
O_N
=
\sum_{n=0}^{N-1}
\frac{
\max\left(
\cos(0.4x_{n,x}+\phi),
5/s_n^2
\right)
}{d_n^2}.
}
$$

Finally,

$$
\boxed{
C
=
\tanh\left(\frac{O_N}{30000}\right).
}
$$

The iteration terminates approximately when

$$
\boxed{
z_n+n\ge200.}
$$

---

## 32. The Final Closed Mathematical Form

Combining all definitions gives the shader's rendering model:

$$
\boxed{
C(FC,t)
=
\tanh
\left[
\frac1{30000}
\sum_{n}
\frac{
\max\left(
\cos(0.4x_{n,x}+(0,2,4)),
5/s_n^2
\right)
}{
\left(
0.2\min
\left[
0.2|g(x_n)|+\max(s_n-5,0.1),
|s_n-6|+0.2
\right]
\right)^2
}
\right].
}
$$

where

$$
q_n=z_n\hat\omega+9e_z,
$$

$$
 s_n=\|q_n\|,
$$

$$
a_n=
\frac{
\cos((0,2,4)^T-\frac t2\mathbf1+0.3s_n\mathbf1)
}{
\left\|
\cos((0,2,4)^T-\frac t2\mathbf1+0.3s_n\mathbf1)
\right\|},
$$

$$
x_n=(a_n\cdot q_n)a_n-a_n\times q_n,
$$

and

$$
 g(x,y,z)=x\sin y+y\sin z+z\sin x.
$$

The ray positions satisfy

$$
 z_{n+1}=z_n+d_n.
$$

This is the complete mathematical specification of the shader's intended algorithm.

---

## 33. The Core Reusable Formula

The most reusable abstraction is not the particular trigonometric surface. It is the composition

$$
\boxed{
C
=
T
\left[
\sum_n
K\left(D(W(q_n,t)),x_n,t\right)
\right],
\qquad
q_{n+1}=q_n+D(W(q_n,t))\hat\omega.
}
$$

More explicitly,

$$
\boxed{
\begin{aligned}
q(z)&=q_0+z\hat\omega,\\
s&=\|q\|,\\
a&=\operatorname{normalize}\left[\cos(\phi_0+\omega t+\lambda s)\right],\\
x&=R_a(\theta)q,\\
F&=F_0(x),\\
D&=\operatorname{combine}(F,\text{radial fields}),\\
z_{n+1}&=z_n+D_n,\\
L&=\sum_n\frac{H(x_n)}{D_n^p+\varepsilon},\\
C&=T(L).
\end{aligned}
}
$$

The original shader is one parameter choice in this much larger design space.

---

## 34. Design Principles Extracted from the Shader

The shader suggests a useful procedural-geometry workflow.

### Base field

Choose an implicit field

$$
F_0(x)=0.
$$

### Domain warp

Choose a transformation

$$
W(x,t).
$$

### Composite field

Use

$$
F(x,t)=F_0(W(x,t)).
$$

### Distance estimator

Construct

$$
D(x,t)\approx\operatorname{dist}(x,F=0).
$$

### Ray dynamics

Use

$$
z_{n+1}=z_n+D_n.
$$

### Appearance kernel

Choose

$$
K(D,x,t).
$$

### Tone mapping

Choose

$$
T(L).
$$

The general construction is therefore

$$
\boxed{
\text{geometry}
+
\text{domain warp}
+
\text{distance estimator}
+
\text{adaptive sampling}
+
\text{appearance kernel}.
}
$$

This is the underlying mathematical pattern worth remembering.

---

## 35. Final Conceptual Compression

The shader can be compressed mathematically to the pipeline

$$
\boxed{
\hat\omega
\rightarrow
q(z)
\rightarrow
s=\|q\|
\rightarrow
 a(s,t)
\rightarrow
R_aq
\rightarrow
g(x)
\rightarrow
D(x)
\rightarrow
z_{n+1}=z_n+D_n
\rightarrow
\sum D_n^{-2}
\rightarrow
\tanh.
}
$$

The deepest idea is therefore

$$
\boxed{
\text{simple implicit geometry}
\;\circ\;
\text{position-dependent transformation}
\;\circ\;
\text{adaptive numerical integration}
}
$$

The particular functions can all be replaced.

The framework survives.

---

## 36. Useful Generalizations at a Glance

| Component | Current shader | Generalization |
|---|---|---|
| Ray | $q=z\hat\omega+9e_z$ | arbitrary camera transform |
| Axis | normalized cosine field | Fourier / noise / analytic vector field |
| Rotation | $R_a(-\pi/2)$ | $R_a(\theta(s,t))$ |
| Base field | $x\sin y+y\sin z+z\sin x$ | arbitrary implicit field $F_0$ |
| Union | $\min(F_1,F_2)$ | smooth minimum |
| Absolute value | $|x|$ | $\sqrt{x^2+\varepsilon^2}$ |
| Glow | $1/d^2$ | exponential, Gaussian, regularized power law |
| Warp count | one | recursive $W^{\circ K}$ |
| Field scale | single frequency | multiscale Fourier / fractal sum |
| Tone mapping | $\tanh(L/30000)$ | Reinhard, exponential, ACES-like mappings |

The result is a general procedural rendering language built from composition rather than from one giant closed-form surface equation.
