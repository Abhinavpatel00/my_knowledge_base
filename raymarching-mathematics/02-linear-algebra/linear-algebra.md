# Chapter 02 — Linear Algebra

The entire book is written in the language of vectors, matrices, and the transforms built from them. This chapter is a working derivation of the pieces we actually use, not a survey.

## 2.1 The dot product and orthogonality

**Definition.** For $\mathbf a,\mathbf b\in\mathbb R^3$,

$$
\mathbf a\cdot\mathbf b=a_1b_1+a_2b_2+a_3b_3 .
$$

**Geometric meaning.** Because the norm satisfies the law of cosines, we may write

$$
\mathbf a\cdot\mathbf b=\lVert\mathbf a\rVert\lVert\mathbf b\rVert\cos\theta ,
$$

where $\theta$ is the angle between them.

**Properties.**

1. Symmetric: $\mathbf a\cdot\mathbf b=\mathbf b\cdot\mathbf a$.
2. Bilinear: $(\lambda\mathbf a+\mathbf b)\cdot\mathbf c=\lambda(\mathbf a\cdot\mathbf c)+\mathbf b\cdot\mathbf c$.
3. $\mathbf a\cdot\mathbf b=0$ iff $\mathbf a\perp\mathbf b$ (orthogonal).
4. $\lVert\mathbf a\rVert^2=\mathbf a\cdot\mathbf a$.
5. **Cauchy–Schwarz:** $\lvert\mathbf a\cdot\mathbf b\rvert\le\lVert\mathbf a\rVert\lVert\mathbf b\rVert$.

**Projection.** The scalar projection of $\mathbf b$ onto unit vector $\mathbf u$ is $\mathbf b\cdot\mathbf u$; the vector projection is $(\mathbf b\cdot\mathbf u)\,\mathbf u$.

## 2.2 The cross product

**Definition.** The cross product of $\mathbf a,\mathbf b\in\mathbb R^3$ is

$$
\mathbf a\times\mathbf b=
\left(a_2b_3-a_3b_2,\;a_3b_1-a_1b_3,\;a_1b_2-a_2b_1\right).
$$

**Properties.**

1. Anticommutative: $\mathbf a\times\mathbf b=-\mathbf b\times\mathbf a$.
2. $\mathbf a\times\mathbf b$ is orthogonal to both $\mathbf a$ and $\mathbf b$.
3. $\lVert\mathbf a\times\mathbf b\rVert=\lVert\mathbf a\rVert\lVert\mathbf b\rVert\sin\theta$.
4. $\mathbf a\times\mathbf b=\mathbf 0$ iff $\mathbf a,\mathbf b$ are parallel.
5. **Scalar triple product:** $\mathbf a\cdot(\mathbf b\times\mathbf c)$ gives the signed volume of the parallelepiped spanned by $\mathbf a,\mathbf b,\mathbf c$.

**Use in raymarching.** The cross product builds a frame: given a view direction $\mathbf d$ and an up hint $\mathbf u$, the right vector is $\mathbf r=\mathbf d\times\mathbf u$ and then $\mathbf u=\mathbf r\times\mathbf d$ (Chapter 23). It also produces surface normals from triangle data and directions orthogonal to a ray.

## 2.3 Basis, orthonormal bases, and coordinates

A **basis** of $\mathbb R^3$ is a linearly independent spanning set. An **orthonormal basis** (ONB) $\{\mathbf e_1,\mathbf e_2,\mathbf e_3\}$ satisfies

$$
\mathbf e_i\cdot\mathbf e_j=\delta_{ij}
$$

($\delta_{ij}=1$ if $i=j$, else $0$). In an ONB, coordinates are dot products:

$$
\mathbf v=(\mathbf v\cdot\mathbf e_1)\mathbf e_1+(\mathbf v\cdot\mathbf e_2)\mathbf e_2+(\mathbf v\cdot\mathbf e_3)\mathbf e_3 .
$$

**Why this matters for shaders.** The whole point of coordinate systems in this book is to choose an ONB in which the problem becomes simple. Every scene is isotropic — there is no preferred basis in space — so changing the basis never changes the *geometry*, only the *description*. That is the deep justification for domain warping and for camera construction.

## 2.4 Matrices as linear maps

A matrix $M\in\mathbb R^{m\times n}$ represents a linear map $\mathbf x\mapsto M\mathbf x$. Composition of linear maps corresponds to matrix multiplication, and the composition is *function composition* in reverse order: $(M_2M_1)\mathbf x=M_2(M_1\mathbf x)$.

**Transpose.** $(M^T)_{ij}=M_{ji}$. For the dot product and an orthonormal matrix it satisfies $(M\mathbf a)\cdot\mathbf b=\mathbf a\cdot(M^T\mathbf b)$.

**Inverse.** $M^{-1}$ exists iff $\det M\neq0$; it satisfies $MM^{-1}=M^{-1}M=I$. Geometrically, $M^{-1}$ undoes $M$.

## 2.5 Euclidean isometries: rotations and reflections

The transforms that preserve distance are the **isometries**. A linear map $R$ is an isometry iff it preserves the inner product: $\lVert R\mathbf x\rVert=\lVert\mathbf x\rVert$ for all $\mathbf x$, equivalently $R^TR=I$. These are the **orthogonal matrices**, forming the group $O(3)$.

**Two classes:**

- **Rotations**, $\det R=+1$, forming $SO(3)$ — proper rotations.
- **Reflections**, $\det R=-1$ — improper; they reverse orientation.

**Key fact.** A rotation preserves *all* distances, so if $d$ is an exact SDF then $d'( \mathbf p)=d(R\mathbf p)$ is an exact SDF of the rotated object (Chapter 10). This is a special case of the broader fact that some transformations preserve the distance property and some do not.

### Rotation about a coordinate axis

Rotation by angle $\theta$ about the $x$-axis:

$$
R_x(\theta)=
\begin{pmatrix}
1&0&0\\
0&\cos\theta&-\sin\theta\\
0&\sin\theta&\cos\theta
\end{pmatrix}.
$$

About $y$:

$$
R_y(\theta)=
\begin{pmatrix}
\cos\theta&0&\sin\theta\\
0&1&0\\
-\sin\theta&0&\cos\theta
\end{pmatrix}.
$$

About $z$:

$$
R_z(\theta)=
\begin{pmatrix}
\cos\theta&-\sin\theta&0\\
\sin\theta&\cos\theta&0\\
0&0&1
\end{pmatrix}.
$$

**Derivation of $R_z$.** In the $xy$-plane a point $(x,y)$ is $r(\cos\phi,\sin\phi)$ where $r=\sqrt{x^2+y^2}$, $\phi=\operatorname{atan2}(y,x)$. Rotating by $\theta$ gives $r(\cos(\phi+\theta),\sin(\phi+\theta))$. Expanding,

$$
x'=r(\cos\phi\cos\theta-\sin\phi\sin\theta)=x\cos\theta-y\sin\theta,
$$
$$
y'=r(\sin\phi\cos\theta+\cos\phi\sin\theta)=x\sin\theta+y\cos\theta .
$$

That is the first two rows of $R_z$. This *is* the polar-coordinate rotation identity we will reuse in the polar-transformation chapter.

## 2.6 Rotation about an arbitrary axis (Rodrigues)

To rotate $\mathbf x$ by angle $\theta$ about the unit axis $\mathbf a$, decompose $\mathbf x$ into the components parallel and orthogonal to $\mathbf a$:

$$
\mathbf x=(\mathbf x\cdot\mathbf a)\,\mathbf a+\big[\mathbf x-(\mathbf x\cdot\mathbf a)\,\mathbf a\big] .
$$

The parallel part is unchanged. In the plane perpendicular to $\mathbf a$, the orthogonal part $\mathbf x_\perp$ has a natural basis $\{\mathbf x_\perp,\mathbf a\times\mathbf x_\perp\}$ (which are orthogonal and equal length). Rotating,

$$
\mathbf x_\perp'=\mathbf x_\perp\cos\theta+(\mathbf a\times\mathbf x_\perp)\sin\theta .
$$

Adding the unchanged parallel part,

$$
\mathbf R(\mathbf a,\theta)\mathbf x
=\mathbf x\cos\theta+(\mathbf a\times\mathbf x)\sin\theta+\mathbf a(\mathbf a\cdot\mathbf x)(1-\cos\theta).
$$

This is **Rodrigues' formula**. It is the general rotation, and it is the right tool whenever a scene must spin about an arbitrary axis.

## 2.7 Quaternions

Quaternions are the best way to compose rotations and to interpolate between them. A quaternion is

$$
q=w+xi+yj+zk,\qquad i^2=j^2=k^2=ijk=-1 .
$$

We identify $q$ with the pair $(w,\mathbf v)$ where $w\in\mathbb R$ is the scalar part and $\mathbf v=(x,y,z)$.

**Multiplication** (derived from the basis relations):

$$
(w_1,\mathbf v_1)(w_2,\mathbf v_2)=
\big(w_1w_2-\mathbf v_1\cdot\mathbf v_2,\;w_1\mathbf v_2+w_2\mathbf v_1+\mathbf v_1\times\mathbf v_2\big).
$$

**Conjugate.** $\bar q=(w,-\mathbf v)$. **Norm.** $\lVert q\rVert^2=q\bar q=w^2+\lVert\mathbf v\rVert^2$.

**Rotation via conjugation.** Represent a rotation by the unit quaternion

$$
q=\left(\cos\tfrac\theta2,\;\sin\tfrac\theta2\,\mathbf a\right)
$$

for axis $\mathbf a$ (unit) and angle $\theta$. Then acting on a "pure vector" quaternion $x=(0,\mathbf x)$,

$$
x'\mapsto qx\bar q
$$

is exactly the rotation by $\theta$ about $\mathbf a$. (This is why the half-angle: conjugation applies the rotation twice.)

**Composition and advantage.** Quaternion composition is associative; two rotations $q_1,q_2$ compose as $q_1q_2$, and unlike Euler-angle composition this is algebraic and free of gimbal lock. Rotations can be interpolated by spherical linear interpolation (`slerp`), which is why animation systems for cameras and rigid objects use them. In a distance-function context, quaternions appear whenever an object is rotated smoothly over time (Chapter 22) or when a scene has an oriented local frame (Chapter 10).

**Heuristic note.** In GLSL we rarely store quaternions explicitly; we either precompute a rotation matrix or apply Rodrigues on the fly. But understanding the quaternion *algebra* clarifies why successive rotations behave as they do.

## 2.8 The matrix-view of the scene transform

The most important structural insight of the whole book is this:

> Most scene transforms are of the form "apply $T$ to the sample point, then evaluate the primitive at the *inverse-transformed* point." That is, if $g(\mathbf p)$ is the primitive field and we want the object to be the $T$-image of it, we evaluate $g(T^{-1}\mathbf p)$.

For a primitive $g$ centered at the origin and a transform $T\mathbf p=Q\mathbf p+\mathbf t$ ($Q$ orthogonal), we compute

$$
\mathbf p'=Q^T(\mathbf p-\mathbf t),
$$

then $d=g(\mathbf p')$. **This is the "inverse transform trick."** We will use it constantly, and Chapter 10 proves *when* the result is an exact SDF (it is, exactly when the map is a distance-preserving isometry; otherwise we must rescale or it becomes a bound).

## 2.9 Orthonormal basis construction (Gram–Schmidt for frames)

Given two non-parallel vectors $\mathbf u,\mathbf v$, build an ONB:

$$
\mathbf e_1=\frac{\mathbf u}{\lVert\mathbf u\rVert},\qquad
\mathbf e_2=\frac{\mathbf v-(\mathbf v\cdot\mathbf e_1)\mathbf e_1}{\lVert\mathbf v-(\mathbf v\cdot\mathbf e_1)\mathbf e_1\rVert},\qquad
\mathbf e_3=\mathbf e_1\times\mathbf e_2 .
$$

This is the basis for triplanar mapping (Chapter 16), camera frames (Chapter 23), and analytic normals on warped surfaces (Chapter 12).

## Exercises

1. **(Calculation)** Given $\mathbf a=(1,2,3)$, $\mathbf b=(4,0,-1)$, compute $\mathbf a\cdot\mathbf b$, $\mathbf a\times\mathbf b$, and a vector orthogonal to both.
2. **(Geometric)** Verify Rodrigues' formula reduces to $R_z$ when $\mathbf a=(0,0,1)$.
3. **(Derivation)** Show that $R^TR=I$ implies $\lVert R\mathbf x\rVert=\lVert\mathbf x\rVert$ and hence $R$ preserves distances.
4. **(Derivation)** Prove that a reflection matrix has determinant $-1$ and hence reverses orientation.
5. **(Composition)** Compose two quaternion rotations about different axes and show the result equals the corresponding Rodrigues rotation. Verify numerically.
6. **(Design)** You want to rotate a scene about a moving axis over time. Which representation — Euler angles, a quaternion, or Rodrigues — do you choose, and why?
