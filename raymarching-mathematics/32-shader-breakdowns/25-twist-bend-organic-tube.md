# Shader Breakdown 25 — Twist and Bend: Domain Deformations of an Organic Tube

Twist and bend are the two most common *deformations* (Chapter 10) that turn a simple tube or box into an organic, dynamic form. They are invaluable when you want a "twisted ribbon," a "bent pipe," or a "coiled tube." The critical mathematical fact is that **neither is an isometry** — so they produce distance *bounds*, and you must compensate for the step to keep the march safe.

## 1. The fragment (reconstructed key parts)

```glsl
float sdTube(vec3 p, float r){ return length(p.xz) - r; }   // an infinite cylinder

float map(vec3 p){
    // TWIST: rotate the cross-section by an angle proportional to y
    float c = cos(k*p.y), s = sin(k*p.y);
    p.xy = mat2(c,s,-s,c) * p.xy;              // or p.xz
    // BEND: bend the y-axis into an arc
    float a = p.y / R;                         // angle over a radius R
    p = vec3( sin(a)*(R - p.x), cos(a)*(R - p.x) - R, p.z );

    return sdTube(p, r);
}
```

## 2. Mathematics

### 2.1 The twist

The **twist** rotates a cross-section by an angle proportional to the axial coordinate:
$$
\theta(y)=k\,y,\qquad
\mathbf p_{xz}\mapsto R_{\theta(y)}\,\mathbf p_{xz}.
$$
In matrix form,
$$
\begin{pmatrix}x'\\ y'\\ z'\end{pmatrix}
=
\begin{pmatrix}
\cos(ky) & 0 & -\sin(ky)\\
0 & 1 & 0\\
\sin(ky) & 0 & \cos(ky)
\end{pmatrix}
\begin{pmatrix}x\\ y\\ z\end{pmatrix}.
$$
A vertical column (or a box or tube) becomes a helical column: each slab is rotated more than the one below it, so the whole thing corkscrews.

**Jacobian and field class.** The twist's Jacobian has off-diagonal entries proportional to $k$ times the arm radius $\lVert\mathbf p_{xz}\rVert$. Its spectral norm is
$$
\sigma_{\max}=\sqrt{1+(k\lVert\mathbf p_{xz}\rVert)^2},
$$
which is $>1$ away from the axis. So the twist is **not an isometry**; the composed field is a **distance bound**, and the safe step must be scaled by $1/\sqrt{1+(k r)^2}$ (or one accepts the bound). The twist is *conformal-style* (it preserves angles locally, but scales lengths), which is why it looks "natural."

### 2.2 The bend

To **bend** the $y$-axis into an arc of radius $R$, map each vertical slab by an arc-length parameterization. The typical form:
$$
a=\frac{y}{R},\qquad
\mathbf p'=\Big(\sin a\,(R-p_x),\ \cos a\,(R-p_x)-R,\ p_z\Big).
$$
This wraps the column around a cylinder of radius $R$. A box/cylinder along $y$ becomes an arc/curve.

**Jacobian and field class.** The bend's Jacobian is not orthogonal either; it stretches space by an amount that depends on $p_x$ (the distance from the bend's neutral axis). Near the "outer" side, lengths are stretched; near the "inner," compressed. So the bend is also a **distance bound**, not exact. The stretching factor is roughly $1-p_x/R$, which is why the neutral axis is where the geometry is undistorted.

### 2.3 The tube SDF

The underlying organic form is often an infinite cylinder:
$$
d=\lVert\mathbf p_{xz}\rVert-r,
$$
which is an exact SDF. After a twist/bend, it becomes a bound. This is the whole point: **the complexity (coil, arc) comes from the deformation, and the deformation costs you exactness.**

## 3. Field-class analysis

| Stage | Operation | Isometry? | Field class | Safe step |
|-------|-----------|-----------|-------------|-----------|
| tube | $\lVert p_{xz}\rVert-r$ | — | exact | $d$ |
| twist | $R_{\theta(y)}$ | no | **bound** | $d/\sqrt{1+(kr)^2}$ |
| bend | arc wrap | no | **bound** | $d/(1-p_x/R)$ |

## 4. The "thinking process"

1. **Ideas.** "I want a coiled/helical tube or a bent pipe." → deform a tube.
2. **Twist.** "Rotate each slab by an angle ∝ height." → $\theta=ky$.
3. **Bend.** "Wrap a column around an arc." → arc-length parameterization.
4. **Class.** "These aren't isometries." → the field becomes a bound; scale the step.

## 5. Extensions

- **Twist with a varying rate.** $k=k(y)$ makes the twist rate vary (a "tapered corkscrew").
- **Taper + twist + bend.** Combine all three deformations for an organic "vine."
- **Curved-ray correction.** If exactness is essential, use the curved-ray method (Breakdown 7) rather than the inverse-transform bound, for the true deformed geometry.
- **Repetition + twist.** Tile the twisted form along an axis for a periodic corkscrew (Chapter 11).
- **Material swirl.** Use the twist angle as a texture coordinate to wrap a spiral pattern on the tube.

## Exercises

1. **(Derivation)** Write the twist matrix and derive $\sigma_{\max}=\sqrt{1+(kr)^2}$.
2. **(Derivation)** Write the bend map and its Jacobian; state the stretch factor $1-p_x/R$.
3. **(Field class)** Classify the twisted/bent tube and give the safe-step scaling.
4. **(Analytic)** Explain why a varying twist rate $k(y)$ changes the look.
5. **(Design)** Combine taper + twist + bend for a vine; describe the field class.
6. **(Implementation)** Render a twisted and bent tube; apply the safe-step factor.
