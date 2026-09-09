# Mathematical Derivation of the Golfed Raymarching Shader

The shader

\[
\texttt{vec3 p,a;}
\]

\[
\texttt{for(float i,z,d,s;z+i++<2e2;o+=max(cos(p.x*.4+vec4(0,2,4,0)),5./s/s)/d/d)}
\]

\[
\texttt{p=z*normalize(FC.rgb*2.-r.xyy),}
\]

\[
\texttt{p.z+=9.,}
\]

\[
\texttt{s=length(p=dot(a=normalize(cos(vec3(0,2,4)-t*.5+s*.3)),p)*a-cross(a,p)),}
\]

\[
\texttt{z+=d=min(abs(dot(p,sin(p).yzx))*.2+max(d=s-5.,.1),abs(--d)+.2)*.2;}
\]

\[
\texttt{o=tanh(o/3e4);}
\]

is essentially a compact procedural ray marcher built from four mathematical ideas:

1. ray parametrization;
2. a state-dependent rotation in \(SO(3)\);
3. a hybrid trigonometric/radial distance estimator;
4. a singular glow accumulation followed by nonlinear tone mapping.

The code is brutally compressed, but mathematically it is much cleaner than its syntax suggests.

There is one important caveat before deriving it:

\[
\boxed{\text{The intended mathematical model assumes }i_0=z_0=d_0=s_0=0.}
\]

The declarations

\[
\texttt{float i,z,d,s;}
\]

do not themselves communicate these initial values. A shader dialect or implementation that does not initialize local variables deterministically makes the literal program formally under-specified. In particular, \(s\) is used while constructing the first rotation axis, so the mathematical recurrence needs an initial \(s_0\). The natural intended choice is

\[
i_0=z_0=d_0=s_0=0.
\]

The symbols \(FC,r,t,o\) are treated abstractly because their precise definitions are outside the supplied fragment. In a Shadertoy-style interpretation one normally has

\[
FC=\text{fragment coordinate},
\qquad
r=\text{resolution},
\qquad
t=\text{time}.
\]

---

# 1. The Shader as a Dynamical System

The most useful way to understand the shader is not as a sequence of assignments but as a discrete dynamical system.

Define the ray parameter at iteration \(n\) by

\[
z_n\in\mathbb R.
\]

Define the camera ray direction

\[
\hat{\omega}
=
\operatorname{normalize}
\left(
2FC-r_{xyy}
\right),
\]

where

\[
r_{xyy}=(r_x,r_y,r_y).
\]

The pre-warped spatial point is

\[
q_n
=
z_n\hat{\omega}
+
9e_z,
\]

where

\[
e_z=(0,0,1).
\]

Thus the ray is

\[
q(z)=z\hat{\omega}+9e_z.
\]

The shader therefore does **not** begin by constructing a conventional object centered at the camera.

Instead, it casts rays from the camera into a coordinate system whose geometry is effectively shifted by \(9\) units in the \(z\)-direction.

The complete recurrence will eventually become

\[
\boxed{
z_{n+1}=z_n+D(q_n,s_n)
}
\]

with

\[
\boxed{
s_n=S(q_n)
}
\]

and a state-dependent spatial transformation

\[
q_n\mapsto x_n.
\]

The entire shader can therefore be interpreted as a discrete trajectory

\[
z_0
\longrightarrow
z_1
\longrightarrow
z_2
\longrightarrow
\cdots
\]

through a procedurally defined scalar field.

---

# 2. Ray Parameterization

The fundamental ray equation is

\[
q(z)=z\hat{\omega}+9e_z.
\]

This is the usual affine parameterization of a line in Euclidean space:

\[
q(z)=q_0+z\hat{\omega},
\]

with

\[
q_0=9e_z.
\]

Since \(\hat{\omega}\) is normalized,

\[
\|\hat{\omega}\|=1.
\]

Therefore

\[
z
\]

has the geometric interpretation of a ray-distance parameter.

The corresponding derivative is

\[
\frac{dq}{dz}=\hat{\omega}.
\]

Consequently the ray is traversed with unit speed in the original ray space.

---

# 3. A Hidden Simplification: \(s\) Is Radial

The shader contains the apparently complicated expression

\[
s
=
\left\|
(a\cdot q)a-a\times q
\right\|.
\]

At first glance this looks like an arbitrary nonlinear deformation.

It is not.

The vector

\[
(a\cdot q)a-a\times q
\]

is exactly a rotation of \(q\) through angle

\[
-\frac{\pi}{2}
\]

around the unit axis \(a\).

This will be derived shortly.

Because rotations preserve Euclidean norm,

\[
\|Rq\|=\|q\|,
\qquad
R\in SO(3),
\]

we immediately obtain

\[
\boxed{
s=\|q\|.
}
\]

Therefore the apparently complicated definition of \(s\) collapses to

\[
s_n
=
\left\|
z_n\hat{\omega}+9e_z
\right\|.
\]

This is one of the most important structural observations in the entire shader.

Expanding the norm gives

\[
s_n^2
=
\left\|
z_n\hat{\omega}+9e_z
\right\|^2.
\]

Because

\[
\|\hat{\omega}\|^2=1,
\]

we obtain

\[
s_n^2
=
z_n^2
+
18z_n\hat{\omega}_z
+
81.
\]

Hence

\[
\boxed{
s_n
=
\sqrt{
z_n^2
+
18z_n\hat{\omega}_z
+
81
}.
}
\]

So the feedback variable \(s\) is fundamentally a radial quantity.

The geometry may look three-dimensional and chaotic, but the temporal/spatial feedback controlling the axis is actually driven by the scalar radial distance

\[
s=\|q\|.
\]

---

# 4. The Rotation Hidden in the Shader

The critical expression is

\[
x
=
(a\cdot q)a-a\times q.
\]

Assume

\[
\|a\|=1.
\]

Recall Rodrigues' rotation formula:

\[
R_a(\theta)q
=
q\cos\theta
+
(a\times q)\sin\theta
+
a(a\cdot q)(1-\cos\theta).
\]

For

\[
\theta=-\frac{\pi}{2},
\]

we have

\[
\cos\left(-\frac{\pi}{2}\right)=0,
\]

and

\[
\sin\left(-\frac{\pi}{2}\right)=-1.
\]

Therefore

\[
R_a\left(-\frac{\pi}{2}\right)q
=
0
-
a\times q
+
a(a\cdot q).
\]

Thus

\[
\boxed{
R_a\left(-\frac{\pi}{2}\right)q
=
(a\cdot q)a-a\times q.
}
\]

Exactly the expression appearing in the shader.

Therefore the spatial transformation is

\[
\boxed{
x
=
R_a\left(-\frac{\pi}{2}\right)q.
}
\]

This is not merely a heuristic vector trick.

It is a genuine element of the rotation group

\[
SO(3).
\]

The rotation matrix is

\[
R_a\left(-\frac{\pi}{2}\right)
=
aa^{T}
-
[a]_\times,
\]

where

\[
[a]_\times
=
\begin{pmatrix}
0 & -a_z & a_y\\
a_z & 0 & -a_x\\
-a_y & a_x & 0
\end{pmatrix}.
\]

Hence

\[
\boxed{
R=aa^T-[a]_\times.
}
\]

Since

\[
R^TR=I
\]

and

\[
\det R=1,
\]

we have

\[
R\in SO(3).
\]

Consequently

\[
\|x\|=\|q\|.
\]

That gives the earlier simplification

\[
\boxed{s=\|x\|=\|q\|.}
\]

---

# 5. Construction of the Rotation Axis

The shader defines

\[
a
=
\operatorname{normalize}
\left(
\cos
\left(
\begin{pmatrix}
0\\
2\\
4
\end{pmatrix}
-\frac{t}{2}
+
0.3s
\begin{pmatrix}
1\\
1\\
1
\end{pmatrix}
\right)
\right).
\]

Define the phase vector

\[
\phi(s,t)
=
\begin{pmatrix}
0\\
2\\
4
\end{pmatrix}
-\frac{t}{2}
+
0.3s
\begin{pmatrix}
1\\
1\\
1
\end{pmatrix}.
\]

Equivalently,

\[
\phi(s,t)
=
\begin{pmatrix}
-\frac t2+0.3s\\
2-\frac t2+0.3s\\
4-\frac t2+0.3s
\end{pmatrix}.
\]

Define

\[
c(s,t)
=
\cos\phi(s,t),
\]

componentwise:

\[
c(s,t)
=
\begin{pmatrix}
\cos(-t/2+0.3s)\\
\cos(2-t/2+0.3s)\\
\cos(4-t/2+0.3s)
\end{pmatrix}.
\]

Then

\[
\boxed{
a(s,t)
=
\frac{c(s,t)}
{\|c(s,t)\|}.
}
\]

This creates a time-varying and radius-dependent orientation field.

The phase dependence is

\[
\frac{\partial \phi}{\partial t}
=
-\frac12
\begin{pmatrix}
1\\1\\1
\end{pmatrix},
\]

and

\[
\frac{\partial \phi}{\partial s}
=
0.3
\begin{pmatrix}
1\\1\\1
\end{pmatrix}.
\]

Thus increasing either time or radius continuously rotates the phase of all three components.

The three constant offsets

\[
0,\quad2,\quad4
\]

introduce a fixed phase separation between the spatial components.

This produces a highly nontrivial orientation field even though the underlying formula is only componentwise cosine.

---

# 6. The Complete Spatial Map

The shader therefore defines the map

\[
q
\mapsto
x
\]

as

\[
\boxed{
x(q,t)
=
R_{a(\|q\|,t)}
\left(-\frac{\pi}{2}\right)q.
}
\]

Substituting the explicit axis:

\[
\boxed{
x(q,t)
=
R_{\displaystyle
\frac{\cos\left(
(0,2,4)^T-\frac t2\mathbf 1+0.3\|q\|\mathbf 1
\right)}
{\left\|
\cos\left(
(0,2,4)^T-\frac t2\mathbf 1+0.3\|q\|\mathbf 1
\right)
\right\|}
}
\left(-\frac{\pi}{2}\right)
q.
}
\]

where

\[
\mathbf 1=
\begin{pmatrix}
1\\1\\1
\end{pmatrix}.
\]

This is a nonlinear domain warp.

However, it is an unusual one.

At each radius \(s\), the transformation is an exact rigid rotation.

Thus locally, for fixed \(s\),

\[
\|x\|=\|q\|.
\]

The nonlinearity comes from the fact that the rotation axis itself changes with

\[
s=\|q\|.
\]

So the shader is best thought of as a **radially modulated rotation field**.

---

# 7. The Trigonometric Geometry

The next major expression is

\[
\operatorname{dot}
\left(
p,
\sin(p)^{yzx}
\right).
\]

After the rotation, write

\[
x=(x,y,z).
\]

The permutation

\[
\sin(p)^{yzx}
\]

means

\[
\begin{pmatrix}
\sin y\\
\sin z\\
\sin x
\end{pmatrix}.
\]

Therefore

\[
g(x,y,z)
=
x\sin y+y\sin z+z\sin x.
\]

Hence

\[
\boxed{
g(x,y,z)
=
x\sin y+y\sin z+z\sin x.
}
\]

The shader uses

\[
|g(x,y,z)|.
\]

Therefore the trigonometric surface family is generated by the implicit equation

\[
\boxed{
g(x,y,z)=0.
}
\]

This is an implicit periodic surface.

Unlike a sphere,

\[
x^2+y^2+z^2-R^2=0,
\]

it contains nonlinear coupling between different coordinate axes:

\[
x\leftrightarrow y,
\qquad
y\leftrightarrow z,
\qquad
z\leftrightarrow x.
\]

This cyclic coupling is responsible for much of the visual complexity.

---

# 8. Differential Geometry of the Trigonometric Surface

The gradient of

\[
g(x,y,z)
=
x\sin y+y\sin z+z\sin x
\]

is

\[
\nabla g
=
\begin{pmatrix}
\sin y+z\cos x\\
x\cos y+\sin z\\
y\cos z+\sin x
\end{pmatrix}.
\]

Therefore

\[
\boxed{
\nabla g(x,y,z)
=
\left(
\sin y+z\cos x,\;
x\cos y+\sin z,\;
y\cos z+\sin x
\right).
}
\]

Whenever

\[
\nabla g\neq0,
\]

the implicit function theorem tells us that

\[
g(x,y,z)=0
\]

locally defines a smooth two-dimensional manifold.

Its normal direction is

\[
\boxed{
n_g
=
\frac{\nabla g}{\|\nabla g\|}.
}
\]

The shader itself does not explicitly compute this analytic normal, but the mathematical surface is fully characterized by this gradient.

---

# 9. Radial Geometry

The scalar

\[
s=\|x\|
\]

also defines concentric spheres

\[
s=R.
\]

In particular,

\[
s=5
\]

and

\[
s=6
\]

appear explicitly in the distance estimator.

Thus the shader combines two distinct geometric families:

\[
\text{periodic implicit surface}
\]

and

\[
\text{spherical shells}.
\]

This is the key geometric recipe.

---

# 10. Reconstructing the Distance Estimator

The exact code is

\[
d
=
0.2
\min
\left(
0.2|g(x)|
+
\max(s-5,0.1),
\;
|s-6|+0.2
\right).
\]

Therefore define

\[
A(x,s)
=
0.2|g(x)|
+
\max(s-5,0.1),
\]

and

\[
B(s)
=
|s-6|+0.2.
\]

Then

\[
\boxed{
D(x)
=
0.2\min(A(x,s),B(s)).
}
\]

Explicitly,

\[
\boxed{
D(x)
=
0.2
\min
\left[
0.2
\left|
x\sin y+y\sin z+z\sin x
\right|
+
\max(\|x\|-5,0.1),
\;
|\|x\|-6|+0.2
\right].
}
\]

This is the scalar field used as the ray-marching step.

---

# 11. What the First Branch Means

The first branch is

\[
A(x,s)
=
0.2|g(x)|
+
\max(s-5,0.1).
\]

The factor

\[
|g(x)|
\]

measures how close we are to the implicit trigonometric surface

\[
g(x)=0.
\]

But it is not itself the Euclidean distance to that surface.

The first-order approximation to the distance from a point \(x\) to

\[
g(x)=0
\]

is approximately

\[
\boxed{
d_{\mathrm{local}}
\approx
\frac{|g(x)|}{\|\nabla g(x)\|}.
}
\]

The shader does not perform this normalization.

Instead it uses

\[
0.2|g(x)|.
\]

Thus this is better described as a **procedural distance heuristic** or **distance estimator**, not a mathematically exact signed-distance function.

Then

\[
\max(s-5,0.1)
\]

creates a radial bias.

For

\[
s>5,
\]

the term becomes

\[
s-5.
\]

For

\[
s\le5,
\]

it is clamped to

\[
0.1.
\]

Thus the first branch roughly says

\[
\boxed{
A
=
\text{periodic surface measure}
+
\text{outward radial penalty}.
}
\]

---

# 12. What the Second Branch Means

The second branch is

\[
B(s)=|s-6|+0.2.
\]

The zero set of

\[
|s-6|
\]

is

\[
s=6.
\]

Therefore this is a spherical shell centered at the origin with radius

\[
R=6.
\]

The constant

\[
0.2
\]

offsets the shell away from zero.

Thus

\[
\boxed{
B(s)
=
\text{distance-like measure to the sphere }s=6
+
0.2.
}
\]

The shader is therefore constructing a competition between

\[
\text{periodic surface}
\]

and

\[
\text{spherical shell}.
\]

---

# 13. The Minimum as a Geometric Union Operator

The use of

\[
\min(A,B)
\]

is geometrically meaningful.

Suppose two implicit fields approximate distance to two structures:

\[
d_1(x),
\qquad
d_2(x).
\]

Then

\[
d(x)=\min(d_1(x),d_2(x))
\]

selects whichever structure is closer.

This behaves like the distance field of a union:

\[
\boxed{
d_{A\cup B}(x)
\approx
\min(d_A(x),d_B(x)).
}
\]

Hence the shader is effectively forming a procedural union between two geometric constructions.

The complete field is therefore

\[
\boxed{
D(x)
=
0.2
\min
\left[
0.2|g(x)|+\max(\|x\|-5,0.1),
\;
|\|x\|-6|+0.2
\right].
}
\]

The visual result is generated by whichever geometric mechanism provides the smaller local value.

---

# 14. Why `abs` Appears Everywhere

The absolute value

\[
|g(x)|
\]

turns the signed implicit function into an unsigned proximity measure.

Without absolute value,

\[
g(x)
\]

changes sign across the surface.

With absolute value,

\[
|g(x)|\ge0.
\]

Both sides of the surface become equivalent:

\[
g>0
\quad\text{and}\quad
g<0
\]

both correspond to increasing distance from the zero set.

Likewise,

\[
|s-6|
\]

creates two sides around the radius

\[
s=6.
\]

Thus the shader deliberately prefers unsigned geometric proximity.

---

# 15. The Complete Ray-Marching Recurrence

Let

\[
q_n
=
z_n\hat{\omega}+9e_z.
\]

Define

\[
s_n=\|q_n\|.
\]

Define

\[
c_n
=
\cos
\left[
\begin{pmatrix}
0\\2\\4
\end{pmatrix}
-\frac t2\mathbf1
+0.3s_n\mathbf1
\right].
\]

Define

\[
a_n
=
\frac{c_n}{\|c_n\|}.
\]

Then rotate:

\[
\boxed{
x_n
=
(a_n\cdot q_n)a_n
-
a_n\times q_n.
}
\]

Because this is a \(-\pi/2\) rotation,

\[
\|x_n\|=\|q_n\|=s_n.
\]

Now define

\[
g_n
=
x_{n,x}\sin x_{n,y}
+
x_{n,y}\sin x_{n,z}
+
x_{n,z}\sin x_{n,x}.
\]

Then

\[
A_n
=
0.2|g_n|
+
\max(s_n-5,0.1),
\]

and

\[
B_n
=
|s_n-6|+0.2.
\]

The marching distance is

\[
\boxed{
d_n
=
0.2\min(A_n,B_n).
}
\]

Finally,

\[
\boxed{
z_{n+1}=z_n+d_n.
}
\]

This is the mathematical core of the shader.

---

# 16. The Loop Termination Condition

The shader tests

\[
z+i++<200.
\]

Under the intended initialization

\[
i_0=0,
\]

the \(n\)-th iteration is allowed while

\[
\boxed{
z_n+n<200.
}
\]

This is unusual compared with the more common condition

\[
n<N_{\max}.
\]

Here both accumulated ray depth and iteration count consume the budget.

The consequence is that the effective maximum iteration count is not simply \(200\).

It depends on how far the ray has marched.

Roughly,

\[
n+z_n<200.
\]

Thus:

\[
\text{slow marching}
\Rightarrow
\text{more iterations},
\]

while

\[
\text{large steps}
\Rightarrow
\text{earlier termination}.
\]

The shader is effectively imposing a joint computational/depth budget.

---

# 17. Radiance Accumulation

The output accumulation is

\[
o
\leftarrow
o+
\frac{
\max
\left(
\cos(0.4x+\phi_c),
\frac{5}{s^2}
\right)
}
{d^2},
\]

where

\[
\phi_c=(0,2,4,0).
\]

For the RGB channels,

\[
\phi_{\mathrm{RGB}}
=
\begin{pmatrix}
0\\2\\4
\end{pmatrix}.
\]

Therefore

\[
h(s,x)
=
\max
\left[
\begin{pmatrix}
\cos(0.4x)\\
\cos(0.4x+2)\\
\cos(0.4x+4)
\end{pmatrix},
\;
\frac5{s^2}
\begin{pmatrix}
1\\1\\1
\end{pmatrix}
\right].
\]

The accumulated color after \(N\) iterations is

\[
\boxed{
O_N
=
\sum_{n=0}^{N-1}
\frac{
h(x_n,s_n)
}{
d_n^2
}.
}
\]

Thus the shader deliberately emphasizes points with small marching distance.

---

# 18. Why the \(1/d^2\) Term Creates Glow

The weighting

\[
\frac1{d^2}
\]

is singular as

\[
d\to0.
\]

Specifically,

\[
\lim_{d\to0^+}\frac1{d^2}
=
+\infty.
\]

Therefore samples close to the procedural surface receive enormous radiance.

This is analogous to a singular kernel.

The shader is effectively constructing something resembling

\[
\boxed{
I(x)
=
\int
\frac{F(x(s))}
{D(x(s))^2}
\,ds
}
\]

but approximating the integral through the discrete marching sequence.

This is **not physically based volume rendering**.

It is a procedural glow model built from a singular proximity kernel.

The basic visual principle is simply

\[
\boxed{
\text{closer to geometry}
\quad\Longrightarrow\quad
\text{stronger emission}.
}
\]

---

# 19. Continuous Interpretation

Ignoring the discretization for a moment, consider the ray

\[
q(z)=z\hat{\omega}+9e_z.
\]

Define the warped point

\[
x(z,t)
=
R_{a(\|q(z)\|,t)}
\left(-\frac{\pi}{2}\right)
q(z).
\]

Then the scalar field is

\[
D(z,t)
=
0.2
\min
\left[
0.2|g(x(z,t))|
+
\max(\|q(z)\|-5,0.1),
\;
|\|q(z)\|-6|+0.2
\right].
\]

The corresponding continuous brightness model can be interpreted as

\[
\boxed{
C(\hat{\omega},t)
\approx
\int
\frac{
H(x(z,t),\|q(z)\|)
}{
D(z,t)^2
}
\,dz
}
\]

for

\[
H(x,s)
=
\max
\left[
\cos(0.4x_x+\phi_{\mathrm{RGB}}),
\frac5{s^2}
\right].
\]

The shader approximates this integral with samples

\[
z_0,z_1,z_2,\ldots
\]

whose spacing is itself determined by

\[
D.
\]

That makes the algorithm nonlinear in two ways:

\[
\boxed{
\text{geometry controls sampling}
}
\]

and

\[
\boxed{
\text{sampling controls accumulated intensity}.
}
\]

That feedback is the core of the visual style.

---

# 20. Why This Is Ray Marching Rather Than Ordinary Ray Tracing

Classical ray tracing solves for intersections of the form

\[
F(q(z))=0.
\]

That often requires solving a geometric equation.

Ray marching instead repeatedly evaluates a distance estimate:

\[
z_{n+1}
=
z_n+D(q_n).
\]

The crucial heuristic is

\[
\boxed{
D(q_n)
\approx
\text{safe distance that can be traveled without crossing geometry}.
}
\]

If \(D\) is a conservative signed-distance estimate, sphere tracing can converge rapidly while avoiding many intersection calculations.

Here the field is not an exact SDF, so the procedure is better described as

\[
\boxed{
\text{heuristic sphere tracing / procedural ray marching}.
}
\]

This distinction matters.

The shader gets its visual result partly because the numerical system is forgiving, not because every quantity has a rigorous geometric-distance interpretation.

Humans occasionally call anything involving a distance-like number an SDF. Mathematics would like them to stop.

---

# 21. SDF Conditions and Lipschitz Continuity

For a mathematically robust sphere tracer, suppose

\[
D(x)
\]

is a distance estimate satisfying a Lipschitz condition

\[
|D(x)-D(y)|
\le
L\|x-y\|.
\]

If

\[
L\le1,
\]

then a step of size

\[
D(x)
\]

is geometrically meaningful as a lower bound on the distance to the surface.

For a true signed distance function,

\[
\boxed{
\|\nabla D\|=1
}
\]

almost everywhere.

The field in this shader does not generally satisfy this.

For example,

\[
g(x)=x\sin y+y\sin z+z\sin x
\]

has gradient

\[
\nabla g
=
\left(
\sin y+z\cos x,
x\cos y+\sin z,
y\cos z+\sin x
\right).
\]

Its magnitude may be significantly larger than \(1\).

Therefore

\[
|g(x)|
\]

can change much faster than Euclidean distance.

Multiplying by

\[
0.2
\]

acts partly as a conservative scaling factor, reducing the aggressiveness of the field.

This is a common procedural-shader strategy:

\[
\boxed{
\text{scale a complicated field down}
\Rightarrow
\text{make the resulting marcher more stable}.
}
\]

It is not a proof of safety, merely a useful heuristic.

---

# 22. The Gradient of the First Distance Branch

Let

\[
A(x)
=
0.2|g(x)|+\max(s-5,0.1),
\]

with

\[
s=\|x\|.
\]

Away from the nondifferentiable sets

\[
g(x)=0
\]

and

\[
s=5,
\]

we have

\[
\nabla |g|
=
\operatorname{sign}(g)\nabla g.
\]

Also,

\[
\nabla s
=
\frac{x}{\|x\|}
=
\frac{x}{s}.
\]

Therefore, when

\[
s>5,
\]

the gradient is

\[
\boxed{
\nabla A
=
0.2\operatorname{sign}(g)\nabla g
+
\frac{x}{s}.
}
\]

When

\[
s<5,
\]

the radial contribution disappears because the clamp is constant:

\[
\boxed{
\nabla A
=
0.2\operatorname{sign}(g)\nabla g.
}
\]

Then

\[
D=0.2\min(A,B)
\]

is piecewise defined according to whichever branch is smaller.

---

# 23. The Geometry as a Lower Envelope

Define

\[
F_1(x)=
0.2|g(x)|+\max(\|x\|-5,0.1)
\]

and

\[
F_2(x)=
|\|x\|-6|+0.2.
\]

Then

\[
D(x)
=
0.2\min(F_1(x),F_2(x)).
\]

The surface

\[
F_1=F_2
\]

is therefore a switching manifold.

On one side,

\[
D=0.2F_1,
\]

while on the other,

\[
D=0.2F_2.
\]

Thus the complete field is a piecewise-defined lower envelope:

\[
\boxed{
D(x)=
\begin{cases}
0.2F_1(x),&F_1(x)\le F_2(x),\\[4pt]
0.2F_2(x),&F_2(x)<F_1(x).
\end{cases}
}
\]

This explains why the geometry can exhibit abrupt changes in local marching behavior.

---

# 24. A Cleaner Mathematical Pseudocode

The entire shader can be rewritten conceptually as

\[
\boxed{
\begin{aligned}
z_0 &= 0,\\
s_0 &= 0,\\
O_0 &= 0.
\end{aligned}
}
\]

For

\[
n=0,1,2,\ldots
\]

while

\[
z_n+n<200:
\]

\[
q_n=z_n\hat{\omega}+9e_z,
\]

\[
s_n=\|q_n\|,
\]

\[
a_n=
\frac{
\cos\left(
(0,2,4)^T-\frac t2\mathbf1+0.3s_n\mathbf1
\right)
}{
\left\|
\cos\left(
(0,2,4)^T-\frac t2\mathbf1+0.3s_n\mathbf1
\right)
\right\|
},
\]

\[
x_n
=
(a_n\cdot q_n)a_n-a_n\times q_n,
\]

\[
g_n
=
x_{n,x}\sin x_{n,y}
+
x_{n,y}\sin x_{n,z}
+
x_{n,z}\sin x_{n,x},
\]

\[
A_n
=
0.2|g_n|
+
\max(s_n-5,0.1),
\]

\[
B_n
=
|s_n-6|+0.2,
\]

\[
d_n
=
0.2\min(A_n,B_n),
\]

\[
O_{n+1}
=
O_n
+
\frac{
\max
\left(
\cos(0.4x_{n,x}+(0,2,4,0)),
\frac5{s_n^2}
\right)
}{
d_n^2
},
\]

\[
z_{n+1}=z_n+d_n.
\]

Finally,

\[
\boxed{
C
=
\tanh\left(\frac{O_N}{30000}\right).
}
\]

That is the mathematical program.

---

# 25. The Final Closed Form

Collect everything into a single formulation.

Let

\[
\hat{\omega}
=
\frac{2FC-r_{xyy}}
{\|2FC-r_{xyy}\|}.
\]

For each ray sample \(z_n\), define

\[
q_n
=
z_n\hat{\omega}+9e_z.
\]

Define

\[
s_n
=
\|q_n\|
=
\sqrt{
z_n^2+18z_n\hat{\omega}_z+81
}.
\]

Define

\[
u_n
=
\cos
\left[
\begin{pmatrix}
0\\2\\4
\end{pmatrix}
-\frac t2
\begin{pmatrix}
1\\1\\1
\end{pmatrix}
+
0.3s_n
\begin{pmatrix}
1\\1\\1
\end{pmatrix}
\right].
\]

Then

\[
a_n=\frac{u_n}{\|u_n\|}.
\]

Define the radial rotation

\[
x_n
=
(a_n\cdot q_n)a_n-a_n\times q_n.
\]

Define the cyclic trigonometric implicit function

\[
g(x,y,z)
=
x\sin y+y\sin z+z\sin x.
\]

Then

\[
D_n
=
0.2
\min
\left[
0.2|g(x_n)|
+
\max(s_n-5,0.1),
\;
|s_n-6|+0.2
\right].
\]

The ray recurrence is

\[
\boxed{
z_{n+1}=z_n+D_n.
}
\]

The color accumulation is

\[
\boxed{
O_N
=
\sum_{n=0}^{N-1}
\frac{
\max
\left[
\cos(0.4x_{n,x}+\phi),
\frac5{s_n^2}
\right]
}{
D_n^2
},
}
\]

with

\[
\phi=(0,2,4,0).
\]

The final image value is

\[
\boxed{
C
=
\tanh\left(\frac{1}{30000}
\sum_{n=0}^{N-1}
\frac{
\max
\left[
\cos(0.4x_{n,x}+\phi),
\frac5{s_n^2}
\right]
}{
D_n^2
}
\right).
}
\]

The sequence is terminated by

\[
\boxed{
z_n+n\ge200.
}
\]

This is the final mathematical object implemented by the shader.

---

# 26. What the Shader Is Really Doing

At a conceptual level, the shader can be decomposed as

\[
\boxed{
\text{camera ray}
\rightarrow
\text{radial state}
\rightarrow
\text{state-dependent rotation}
\rightarrow
\text{periodic implicit field}
\rightarrow
\text{radial shell competition}
\rightarrow
\text{adaptive stepping}
\rightarrow
\text{singular glow}
\rightarrow
\text{tone mapping}.
}
\]

The interesting part is that the field is not generated by a single primitive.

Instead,

\[
\boxed{
\text{geometry}
=
\text{warp}
\circ
\text{periodic field}
\circ
\text{radial envelope}.
}
\]

And the apparent complexity emerges from composing relatively simple operators.

That is one of the central ideas of procedural graphics.

---

# 27. Why the Geometry Looks More Complicated Than the Equations

Consider the composition

\[
x=R_{a(s,t)}q.
\]

Suppose the original field were simply

\[
g(x)=0.
\]

Without the warp, it is a fixed periodic surface.

But now

\[
x=x(q,t),
\]

so the actual surface in ray-space is defined implicitly by

\[
g(x(q,t))=0.
\]

Therefore the rendered surface is

\[
\boxed{
G(q,t)
=
g\left(
R_{a(\|q\|,t)}
\left(-\frac{\pi}{2}\right)
q
\right)
=0.
}
\]

This is a composition of nonlinear maps.

Even when each individual map is simple, the composition can produce highly elaborate geometry.

The general procedural principle is

\[
\boxed{
\text{simple field}
+
\text{nonlinear coordinate transformation}
=
\text{complex apparent geometry}.
}
\]

---

# 28. A More General Mathematical Framework

The shader belongs to a broad family of constructions of the form

\[
\boxed{
F(x,t)
=
F_0\!\left(W(x,t)\right),
}
\]

where

\[
F_0
\]

is a base implicit field and

\[
W
\]

is a coordinate warp.

Here,

\[
F_0(x)
=
x\sin y+y\sin z+z\sin x,
\]

and

\[
W(x,t)
=
R_{a(\|x\|,t)}
\left(-\frac{\pi}{2}\right)x.
\]

This is an extremely powerful abstraction.

You do not need to invent increasingly ridiculous equations.

Instead:

\[
\boxed{
\text{invent a simple field}
}
\]

then

\[
\boxed{
\text{invent an interesting domain transformation}.
}
\]

The visual complexity comes from composition.

---

# 29. Generalization I: Arbitrary Rotation Angle

The fixed angle

\[
-\frac{\pi}{2}
\]

can be generalized to

\[
\theta=\theta(s,t).
\]

Rodrigues' formula gives

\[
\boxed{
W(q,s,t)
=
q\cos\theta
+
(a\times q)\sin\theta
+
a(a\cdot q)(1-\cos\theta).
}
\]

For example,

\[
\theta(s,t)
=
\theta_0+\alpha s+\beta t.
\]

Then

\[
W
\]

becomes a continuous helical twist.

The original shader is simply the special case

\[
\boxed{
\theta=-\frac{\pi}{2}.
}
\]

---

# 30. Generalization II: Radially Varying Rotation

Rather than only varying the axis,

\[
a=a(s,t),
\]

we can vary both axis and angle:

\[
\boxed{
W(q)
=
R_{a(s,t)}(\theta(s,t))q.
}
\]

For example,

\[
a(s,t)
=
\operatorname{normalize}
\left(
\begin{pmatrix}
\cos(\alpha s+t)\\
\cos(\beta s+t+\phi_1)\\
\cos(\gamma s+t+\phi_2)
\end{pmatrix}
\right),
\]

and

\[
\theta(s,t)
=
\theta_0+\lambda\sin(\mu s+\nu t).
\]

This produces a generalized rotational domain warp.

---

# 31. Generalization III: Fourier Orientation Fields

The cosine vector can be generalized from one harmonic to a Fourier series:

\[
a(s,t)
=
\operatorname{normalize}
\left(
\sum_{k=1}^{K}
A_k
\cos(\omega_k s+\nu_k t+\phi_k)
\right).
\]

More explicitly,

\[
\boxed{
a(s,t)
=
\operatorname{normalize}
\left(
\sum_{k=1}^{K}
A_k
\cos(\omega_k s+\nu_k t+\phi_k)
\right).
}
\]

The original shader effectively uses a single harmonic:

\[
K=1.
\]

Increasing \(K\) gives controlled multiscale deformation without abandoning the mathematical structure.

---

# 32. Generalization IV: Replace the Base Field

The current implicit field is

\[
g(x,y,z)
=
x\sin y+y\sin z+z\sin x.
\]

We could replace it with

\[
g(x,y,z)
=
\sin(xy)+\sin(yz)+\sin(zx).
\]

Or

\[
g(x,y,z)
=
\sin(x)+\sin(y)+\sin(z)-\lambda.
\]

Or

\[
g(x,y,z)
=
\sin(\alpha x+\beta y)
+
\sin(\gamma y+\delta z)
+
\sin(\epsilon z+\zeta x).
\]

Or a radial-angular composition:

\[
g(x)
=
f(\|x\|,\theta,\phi).
\]

The warp remains unchanged.

This separation is extremely useful:

\[
\boxed{
\text{shape generator}
\neq
\text{domain warp}.
}
\]

You can develop each independently.

---

# 33. Generalization V: Smooth Union Instead of Hard Minimum

The current union is

\[
D=\min(D_1,D_2).
\]

A smooth minimum can be defined as

\[
\operatorname{smin}_k(a,b)
=
-\frac1k
\log
\left(
e^{-ka}+e^{-kb}
\right).
\]

Therefore,

\[
\boxed{
D
=
\operatorname{smin}_k(D_1,D_2).
}
\]

As

\[
k\to\infty,
\]

we recover

\[
\operatorname{smin}_k(a,b)\to\min(a,b).
\]

This allows a continuous blending region rather than a hard branch boundary.

---

# 34. Generalization VI: Soft Absolute Value

The absolute value

\[
|x|
\]

has a cusp at

\[
x=0.
\]

A smooth approximation is

\[
|x|
\approx
\sqrt{x^2+\varepsilon^2}.
\]

Thus

\[
|g(x)|
\]

can be replaced by

\[
\sqrt{g(x)^2+\varepsilon^2}.
\]

Likewise,

\[
|s-6|
\]

becomes

\[
\sqrt{(s-6)^2+\varepsilon^2}.
\]

This improves differentiability:

\[
\boxed{
|x|
\rightsquigarrow
\sqrt{x^2+\varepsilon^2}.
}
\]

This becomes especially useful when computing analytic normals or derivatives.

---

# 35. Generalization VII: Better Glow Kernels

The current glow kernel is

\[
K(d)=\frac1{d^2}.
\]

This diverges as

\[
d\to0.
\]

A numerically safer regularization is

\[
\boxed{
K_\varepsilon(d)
=
\frac1{d^2+\varepsilon^2}.
}
\]

Another option is exponential falloff:

\[
\boxed{
K(d)=e^{-kd}.
}
\]

A compact Gaussian-like glow is

\[
\boxed{
K(d)=e^{-k d^2}.
}
\]

A controllable inverse-power family is

\[
\boxed{
K(d)=\frac1{(d^2+\varepsilon^2)^{p/2}}.
}
\]

The shader corresponds approximately to

\[
p=2.
\]

Thus one can treat the rendering model as a parameterized kernel family rather than a mysterious magic constant.

---

# 36. Generalization VIII: Physically Inspired Falloff

For a point-like source in three spatial dimensions, physically motivated kernels often involve powers of distance such as

\[
\frac1{r^2}.
\]

The shader uses

\[
\frac1{d^2},
\]

but here \(d\) is not necessarily the Euclidean distance from a point light.

Rather,

\[
d=D(x)
\]

is the distance-estimator output.

Therefore

\[
\frac1{D(x)^2}
\]

can be interpreted as a pseudo-radiometric proximity field.

This distinction is important:

\[
\boxed{
\frac1{d^2}
\text{ does not automatically make the rendering physically based.}
}
\]

It simply gives strong near-surface emphasis.

---

# 37. Generalization IX: Iterated Domain Warping

The shader performs one nonlinear rotation.

We can iterate the warp:

\[
x_{k+1}
=
W(x_k,t),
\qquad
x_0=q.
\]

After \(K\) iterations,

\[
\boxed{
x_K
=
W^{\circ K}(q,t).
}
\]

Then the base field becomes

\[
F(q,t)
=
g(x_K).
\]

This generates significantly more complicated structures.

The danger is that composition multiplies derivative magnitudes.

If

\[
J_W(x)
\]

is the Jacobian of the warp, then

\[
J_{W^{\circ K}}
=
J_W(x_{K-1})
\cdots
J_W(x_0).
\]

Consequently,

\[
\|J_{W^{\circ K}}\|
\]

can grow rapidly.

This is exactly where procedural shaders can become numerically unstable.

---

# 38. Generalization X: Jacobian-Based Procedural Geometry

For a warped field

\[
F(x)=F_0(W(x)),
\]

the chain rule gives

\[
\boxed{
\nabla F(x)
=
J_W(x)^T
\nabla F_0(W(x)).
}
\]

This is a fundamental equation for domain-warped SDFs.

The original shader implicitly performs

\[
F_0(W(x))
\]

but does not explicitly calculate

\[
J_W.
\]

If you do calculate it, you gain access to:

\[
\text{analytic normals},
\]

\[
\text{curvature},
\]

\[
\text{gradient magnitude},
\]

\[
\text{Lipschitz bounds},
\]

and potentially better sphere-tracing step control.

This is the mathematical route from "cool shader trick" toward a more rigorous geometric system.

---

# 39. Differentiating the Rotation Axis

The axis is

\[
a(s,t)=\frac{c(s,t)}{\|c(s,t)\|},
\]

with

\[
c(s,t)=\cos\phi(s,t).
\]

For a normalized vector

\[
a=\frac{c}{\|c\|},
\]

the derivative satisfies

\[
\boxed{
\frac{\partial a}{\partial s}
=
\frac1{\|c\|}
\left(I-aa^T\right)
\frac{\partial c}{\partial s}.
}
\]

Now

\[
\frac{\partial c}{\partial s}
=
-0.3
\sin\phi.
\]

Thus

\[
\boxed{
\frac{\partial a}{\partial s}
=
-\frac{0.3}{\|c\|}
\left(I-aa^T\right)
\sin\phi.
}
\]

The matrix

\[
I-aa^T
\]

projects onto the tangent plane of the unit sphere at \(a\).

Therefore the derivative of normalization removes the radial component of the raw derivative.

This is a useful geometric identity far beyond this shader.

---

# 40. Why the Warp Is Locally Special

For fixed \(a\),

\[
R_a\in SO(3).
\]

Thus

\[
J_R^TJ_R=I.
\]

Therefore

\[
\|J_Rv\|=\|v\|.
\]

The rotation itself is perfectly conditioned.

The complication comes entirely from

\[
a=a(\|q\|,t).
\]

Thus the field is not difficult because rotations are unstable.

It is difficult because the **rotation parameter is itself a function of position**.

This distinction is important when designing more advanced procedural fields.

---

# 41. The Shader as a Composition of Operators

A compact mathematical factorization is:

\[
\boxed{
\mathcal R_t
=
\mathcal T_{\mathrm{tone}}
\circ
\mathcal A_{\mathrm{glow}}
\circ
\mathcal M_{\mathrm{march}}
\circ
\mathcal D_{\mathrm{field}}
\circ
\mathcal W_t
\circ
\mathcal P.
}
\]

Where:

\[
\mathcal P:
z\mapsto z\hat{\omega}+9e_z
\]

is the ray parameterization;

\[
\mathcal W_t:
q\mapsto
R_{a(\|q\|,t)}(-\pi/2)q
\]

is the domain warp;

\[
\mathcal D_{\mathrm{field}}
\]

constructs the hybrid distance field;

\[
\mathcal M_{\mathrm{march}}
\]

generates

\[
z_{n+1}=z_n+D_n;
\]

\[
\mathcal A_{\mathrm{glow}}
\]

computes

\[
\sum_n \frac{H_n}{D_n^2};
\]

and

\[
\mathcal T_{\mathrm{tone}}
\]

performs

\[
\tanh.
\]

This decomposition is much more useful for shader design than memorizing the original one-liner.

---

# 42. Tone Mapping

The final operation is

\[
C=\tanh(O/30000).
\]

The hyperbolic tangent has the properties

\[
\tanh(0)=0,
\]

and

\[
\lim_{x\to+\infty}\tanh x=1.
\]

Its derivative is

\[
\frac{d}{dx}\tanh x
=
1-\tanh^2x.
\]

Therefore very large accumulated values are compressed:

\[
O\gg30000
\quad\Longrightarrow\quad
C\approx1.
\]

This is a nonlinear saturation operator.

Hence the complete mapping is

\[
\boxed{
C_i
=
\tanh
\left(
\frac{O_i}{30000}
\right).
}
\]

The shader intentionally allows the raw accumulation to become enormous and relies on the nonlinear output map to compress it.

---

# 43. Numerical Interpretation of the Whole Algorithm

The shader can therefore be viewed as solving the following problem:

Given a ray

\[
q(z)=z\hat{\omega}+9e_z,
\]

construct a scalar field

\[
D(q,t)
\]

using a position-dependent \(SO(3)\) transformation and a hybrid implicit geometry.

Then numerically integrate a singular response

\[
K(D)=D^{-2}
\]

along an adaptively sampled ray.

Symbolically,

\[
\boxed{
C(\hat{\omega},t)
=
\tanh
\left[
\frac1{30000}
\sum_n
K(D(q_n,t))
H(q_n,t)
\right].
}
\]

The sampling rule itself depends on the same field:

\[
\boxed{
q_{n+1}
=
q_n
+
D(q_n,t)\hat{\omega}.
}
\]

Thus the field determines both:

\[
\text{where the samples occur}
\]

and

\[
\text{how strongly those samples contribute}.
\]

That feedback is what makes this style of shader particularly expressive.

---

# 44. The Most General Template Behind the Shader

A very general procedural raymarcher can be written mathematically as

\[
q_n=q_0+z_n\hat{\omega},
\]

\[
x_n=W(q_n,t,\sigma_n),
\]

\[
\sigma_n=S(x_n,t,\sigma_n),
\]

\[
D_n=F(x_n,\sigma_n),
\]

\[
z_{n+1}=z_n+D_n,
\]

\[
L_{n+1}
=
L_n+
K(D_n,x_n,t),
\]

and finally

\[
C=T(L_N).
\]

Your shader is simply one particular member of this family:

\[
\boxed{
W=\text{radially modulated rotation},
}
\]

\[
\boxed{
S=\text{Euclidean norm},
}
\]

\[
\boxed{
F=\text{minimum of trigonometric and spherical fields},
}
\]

\[
\boxed{
K\sim D^{-2},
}
\]

\[
\boxed{
T=\tanh.
}
\]

This abstraction is worth remembering.

---

# 45. A Better Mental Model for Designing Similar Shaders

Instead of asking

\[
\text{``What equation makes this exact shape?''}
\]

ask the following mathematical questions:

### Base manifold

Choose

\[
F_0(x)=0.
\]

### Domain transformation

Construct

\[
W(x,t).
\]

### Composite manifold

Use

\[
F(x,t)=F_0(W(x,t)).
\]

### Distance heuristic

Construct

\[
D(x,t)\approx\operatorname{dist}(x,\{F=0\}).
\]

### Marching dynamics

Use

\[
z_{n+1}=z_n+D_n.
\]

### Appearance field

Choose

\[
K(D,x,t).
\]

### Tone map

Choose

\[
T.
\]

This gives the design equation

\[
\boxed{
C
=
T
\left[
\sum_n
K
\left(
D(W(q_n))
\right)
\right].
}
\]

That formula is the real reusable idea.

---

# 46. Three Especially Powerful Extensions

## 46.1 Rotational flow field

Replace the fixed angle by

\[
\theta=\lambda s+\omega t.
\]

Then

\[
x
=
R_{a(s,t)}(\theta(s,t))q.
\]

This creates a radial twisting field.

---

## 46.2 Recursive warp

Let

\[
x_0=q,
\]

and

\[
x_{k+1}
=
R_{a(\|x_k\|,t)}
\left(\theta(\|x_k\|,t)\right)x_k.
\]

Then

\[
F(q,t)=F_0(x_K).
\]

This gives a hierarchy:

\[
K=1
\Rightarrow
\text{simple warp},
\]

\[
K=2
\Rightarrow
\text{nested warp},
\]

\[
K\gg1
\Rightarrow
\text{highly intricate procedural field}.
\]

---

## 46.3 Multiscale field

Define

\[
F(x)
=
\sum_{k=0}^{K}
\lambda_k
F_0(2^kx).
\]

Then warp the result:

\[
\boxed{
F_{\mathrm{final}}(x,t)
=
\sum_{k=0}^{K}
\lambda_k
F_0
\left(
2^kW(x,t)
\right).
}
\]

This introduces controlled spatial frequencies and produces fractal-like structure.

---

# 47. A Useful Design Hierarchy

The shader's construction can be organized mathematically from simplest to most complicated:

\[
\boxed{
\text{primitive}
\rightarrow
\text{implicit field}
\rightarrow
\text{domain warp}
\rightarrow
\text{field composition}
\rightarrow
\text{distance estimator}
\rightarrow
\text{ray dynamics}
\rightarrow
\text{radiance kernel}.
}
\]

For example:

\[
\text{sphere}
\]

becomes

\[
s-1
\]

then

\[
F(W(x))
\]

then

\[
\min(F_1,F_2)
\]

then

\[
z_{n+1}=z_n+D_n
\]

then

\[
L\sim\sum D_n^{-2}.
\]

The geometry and the appearance are therefore separate mathematical layers.

---

# 48. The Core Formula to Keep in Your Reference Book

If you only keep one abstraction from this shader, keep this:

\[
\boxed{
\begin{aligned}
q(z)&=q_0+z\hat{\omega},\\[2mm]
s&=\|q\|,\\[2mm]
a&=
\operatorname{normalize}
\left[
\cos(\phi_0+\omega t+\lambda s)
\right],\\[2mm]
x&=
R_a(\theta)q,\\[2mm]
F(x)&=\text{procedural implicit field},\\[2mm]
D(x)&=\operatorname{combine}(F,\text{radial fields}),\\[2mm]
z_{n+1}&=z_n+D_n,\\[2mm]
L&=
\sum_n
\frac{H(x_n)}
{D_n^p+\varepsilon},\\[2mm]
C&=T(L).
\end{aligned}
}
\]

The supplied shader is approximately the parameter choice

\[
\boxed{
\theta=-\frac{\pi}{2},
}
\]

\[
\boxed{
\phi_0=(0,2,4),
}
\]

\[
\boxed{
\omega=-\frac12,
}
\]

\[
\boxed{
\lambda=0.3,
}
\]

\[
\boxed{
F(x,y,z)=x\sin y+y\sin z+z\sin x,
}
\]

\[
\boxed{
D
=
0.2
\min
\left[
0.2|F(x)|
+\max(s-5,0.1),
\;
|s-6|+0.2
\right],
}
\]

\[
\boxed{
p=2,
}
\]

and

\[
\boxed{
T(u)=\tanh(u/30000).
}
\]

That is the reusable mathematical template behind the one-liner.

---

# 49. Final Interpretation

The entire shader can ultimately be summarized as the following mathematical pipeline:

\[
\boxed{
\hat{\omega}
\longrightarrow
q(z)
\longrightarrow
s=\|q\|
\longrightarrow
a(s,t)
\longrightarrow
R_{a(s,t)}q
\longrightarrow
g(x)
\longrightarrow
D(x)
\longrightarrow
z_{n+1}=z_n+D_n
\longrightarrow
\sum D_n^{-2}
\longrightarrow
\tanh.
}
\]

More compactly:

\[
\boxed{
C
=
\tanh
\left[
\frac1{30000}
\sum_{n}
\frac{
\max
\left(
\cos(0.4x_{n,x}+\phi),
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
\right]
}
\]

with

\[
\boxed{
x_n
=
R_{a_n}\left(-\frac{\pi}{2}\right)
\left(
z_n\hat{\omega}+9e_z
\right),
}
\]

\[
\boxed{
a_n
=
\operatorname{normalize}
\left[
\cos
\left(
(0,2,4)^T-\frac t2\mathbf1+0.3s_n\mathbf1
\right)
\right],
}
\]

\[
\boxed{
s_n
=
\sqrt{
z_n^2
+
18z_n\hat{\omega}_z
+
81
},
}
\]

and

\[
\boxed{
z_{n+1}=z_n+D_n.
}
\]

The deepest idea here is not the particular function

\[
x\sin y+y\sin z+z\sin x.
\]

It is the composition

\[
\boxed{
\text{simple implicit geometry}
\;\circ\;
\text{position-dependent transformation}
\;\circ\;
\text{adaptive ray dynamics}.
}
\]

Once that structure is understood, thousands of these apparently insane demoscene one-liners stop looking like black magic and start looking like what they really are: compact compositions of geometry, analysis, and numerical approximation. The syntax is still criminally hostile to human beings, naturally, but the mathematics underneath is surprisingly orderly.
