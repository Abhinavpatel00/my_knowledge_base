# Shader Breakdown 7 — Advanced: Curved-Ray Marching and Harnack Tracing

These are two modern, research-frontier generalizations of sphere tracing. They are the natural place to see graduate-level mathematics applied to a raymarcher. This breakdown reconstructs both and shows how they *extend* the classical algorithm.

## 7.1 Curved-ray marching of a deformed SDF

**The setup.** We have a reference SDF $d$ in "undeformed" space and a deformation $D:\mathbb R^3\to\mathbb R^3$ (e.g. a bend, a skinning, a nonlinear warp). We want the image of $d=0$ under $D$. The inverse-transform trick requires $D^{-1}$, which may not exist or be cheap. Instead, track the ray in *undeformed* space.

**The ODE.** Let $\boldsymbol\omega$ be the world ray direction (constant). The undeformed-space ray is the curve $\hat{\mathbf x}(s)$ solving
$$
\hat{\mathbf x}'(s)=\hat{\boldsymbol\omega}(\hat{\mathbf x}(s)):=J_D^{-1}(\hat{\mathbf x})\,\boldsymbol\omega
$$
with initial condition $\hat{\mathbf x}(0)=D^{-1}(\mathbf o)$ (or an approximation thereof). This is the parametric-curve deformation (Barr) written as an IVP.

**Why the Jacobian.** The world ray is $\mathbf x(t)=\mathbf o+t\boldsymbol\omega$. Under $D^{-1}$, a small world displacement $d\mathbf x$ corresponds to undeformed displacement $d\hat{\mathbf x}=J_{D^{-1}}\,d\mathbf x$. Since $d\mathbf x=(dt)\boldsymbol\omega$, we get $d\hat{\mathbf x}/dt=J_{D^{-1}}\boldsymbol\omega$, i.e. the velocity field above.

**The marching algorithm.**

```
for each sphere-tracing step:
    integrate the ODE along the curved ray with an ODE solver (no SDF calls)  # cheap
    evaluate d at the new undeformed-space point                               # expensive
    take a conservative sphere-tracing step along the curve based on d         # safe
```

**The safety guarantee.** Even though the trajectory is approximate, each SDF step is a *sphere-tracing* step in undeformed space, so the current point's SDF value is a conservative empty-ball radius along the (approximate) curve. **The algorithm is guaranteed not to step into the surface.** The error only shifts *where* the surface is hit (along the curve), not *whether* it's hit or tunneled through. This is the key result of Seyb et al. (2019).

**Cost.** The ODE integration substeps (cheap, no SDF) are decoupled from the SDF evaluations (expensive). So the cost is dominated by SDF calls, same as classical sphere tracing, plus a modest ODE overhead. This makes the method viable for real-time deformations that were previously impossible to render directly as SDFs.

### 7.1.1 Application

These include: **linear blend skinning** (a character articulating), **bends and squashes** (nonlinearity), and any *forward* deformation for which the inverse is unavailable. The method extends the "transform space" philosophy of Chapter 10 to the case where the transform is not invertible.

## 7.2 Harnack tracing of a harmonic surface

**The setup.** We have a harmonic function $h$ ($\Delta h=0$), e.g. from a winding-number or Poisson-surface-reconstruction field. We want the level set $h=c$. It is **not** Lipschitz an SDF, so classical sphere tracing's Lipschitz bound does not apply.

**The key theorem (Harnack).** For a positive harmonic function on a ball, the value at the center is bounded above by a constant times the value on the boundary — a statement about *how fast* a positive harmonic function can grow. This yields a **conservative empty-ball radius**,
$$
\rho(\mathbf p)\sim \frac{h(\mathbf p)}{\lVert\nabla h(\mathbf p)\rVert}\quad\text{(heuristic)},
$$
that requires only the *value* of $h$ (and a global constant), not a Lipschitz condition.

**The rigorous point.** Unlike a Lipschitz bound (which needs $|\nabla h|$ bounded), the Harnack bound is purely *value-based*: because $h$ is harmonic and positive, its behavior inside a ball is controlled by its boundary values, giving a spot-radius in which $h$ cannot vanish. This is why Harnack tracing can handle **angle-valued harmonic functions with jump discontinuities** (where Lipschitz reasoning fails) — the value-based bound is inherited from the harmonic structure, not from differentiability.

**The tracing step.** At a point $\mathbf p$ with $h(\mathbf p)=v\ne c$, compute the conservative radius $\rho$ (from Harnack) and step along the ray by $\rho$. When $|h-c|<\alpha\lVert\nabla h\rVert$ (a gradient-sensitive threshold), declare a hit.

### 7.2.1 Application

Harnack tracing lets us visualize, in real time:
- Surfaces from **Poisson surface reconstruction** (no mesh extraction or linear solve),
- Surfaces from **generalized winding numbers** (polygon soup, including with holes),
- **Non-planar polygons** and mathematical objects: knots, links, spherical harmonics, Riemann surfaces.

This extends real-time ray-level-set rendering beyond SDFs to the large class of harmonic-level-set representations. It is a beautiful instance of the "find a conservative radius" abstraction, where the radius comes from potential theory rather than metric geometry.

## 7.3 The unifying abstraction

Both methods, plus classical sphere tracing, fit one pattern:

> **Given a scalar field and a desired level set, produce a *pointwise conservative radius* that bounds the empty ball around the current point; step by that radius; stop when you're within a tolerance of the level set.**

| Method | Radius source | Requires | Handles |
|--------|---------------|----------|---------|
| Sphere tracing | $d$ | distance value | SDFs, 1-Lipschitz |
| Bounded | $d/L$ | value + Lipschitz constant | Lipschitz fields |
| Segment | $d/L_{\text{local}}$ | value + local bound | Lipschitz, adaptive |
| Harnack | Harnack constant | value | harmonic level sets |
| Curved-ray | $d$ along a curve | value + Jacobian | deformed SDFs |

The differences are *which a-priori property* supplies the radius and *whether the ray is straight*.

## 7.4 The "thinking process" (extension mindset)

The pattern for extending a marcher:

1. **What's the field's a-priori structure?** Is it a distance (Lipschitz)? A harmonic function (Harnack)? A deformation of a distance (Jacobian)? Each dictates which conservative bound you can use.
2. **What radius certifies empty space?** For each structure, find the pointwise empty-ball radius computed from available data (value, gradient, Jacobian, Harnack constant).
3. **Is the ray straight?** If space is deformed, the ray is a curve → integrate the ODE; the SDF still supplies the step.
4. **What tolerates the error?** Each method makes a specific guarantee (no tunneling, but possible positional shift; or exact for harmonic; or conservative for a bound). State it.

## 7.5 Extensions

### 7.5.1 Harnack + curved ray
Combine: trace a *curved* ray through a *harmonic* level set. This unifies both generalizations and is a natural direction for volumetric deforms of harmonic fields.

### 7.5.2 Using the gradient-sensitivity threshold for termination
For Harnack, the termination is gradient-based ($|h-c|<\alpha|\nabla h|$) rather than an absolute $\varepsilon$. This is more robust to scaling, analogous to the relative epsilon of Chapter 23.

### 7.5.3 Segment-traced Harnack
Combine a local Lipschitz bound (for the harmonic field's *local* behavior) with the Harnack value bound for even larger steps on smooth regions.

### 7.5.4 Automatic differentiation for the Jacobian (curved-ray)
As in Chapter 20, use dual numbers to obtain $J_D$ and $J_D^{-1}$ analytically rather than by finite differences, keeping the curved-ray integration exact and cheap.

## Exercises

1. **(Derivation)** Derive the curved-ray velocity field $\hat{\mathbf x}'=J_D^{-1}\boldsymbol\omega$ from the chain rule.
2. **(Analytic)** Explain why curved-ray marching is guaranteed not to tunnel, even with ODE integration error.
3. **(Derivation)** Recall Harnack's inequality for a positive harmonic function and sketch how it yields an empty-ball radius.
4. **(Analytic)** Explain why Harnack tracing handles jump discontinuities while Lipschitz reasoning cannot.
5. **(Implementation)** Implement a single-step curved-ray sphere tracer for a bend; compare against the naive inverse-transform.
6. **(Derivation)** Derive the gradient-sensitivity termination condition for a level set and explain how to choose $\alpha$.
7. **(Design)** Catalogue which rendering tasks call for each of the four methods (distance, harmonic, deformed, local-Lipschitz).
