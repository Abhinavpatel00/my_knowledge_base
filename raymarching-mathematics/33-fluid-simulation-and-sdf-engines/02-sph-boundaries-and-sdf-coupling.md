# Chapter 33b — Fluid–Solid Coupling: Why an SDF Boundary Beats Triangles

This is the mathematical heart of "why Claybook's SDF world makes particle simulation robust." We derive the boundary treatment: how a signed distance field supplies the *exact* closest-surface information (even for query points already inside the solid), how that gives a clean no-penetration force, and why — in contrast to triangles — it makes tunneling *structurally* difficult.

## 33b.1 The boundary value problem

In the fluid we enforce the no-penetration (free-slip or no-slip) boundary condition on the fluid/solid interface $\Gamma$:
$$
\mathbf v\cdot\mathbf n = \mathbf v_\Gamma\cdot\mathbf n
$$
(no penetration; tangential slip is a material choice). The pressure must also satisfy a **Neumann** condition at the boundary. For a mesh (triangles) this requires:
1. detecting that a particle has *crossed* a triangle, and from which side, and
2. projecting back to the correct side.

Two problems arise immediately: a triangle is a **thin surface** with no notion of *which side*, and a fast particle can jump across it in one timestep — **tunneling**.

## 33b.2 The signed distance field does all of it at once

Let $d:\mathbb R^3\to\mathbb R$ be the world's signed distance field, with the convention $d<0$ inside the solid, $d>0$ outside, $d=0$ on $\Gamma$. For any query point $\mathbf q$:

- **distance to nearest surface** = $|d(\mathbf q)|$,
- **which side** = $\operatorname{sign} d(\mathbf q)$,
- **closest surface point** $\approx \mathbf q-d(\mathbf q)\,\mathbf n(\mathbf q)$,
- **outward normal** $\mathbf n=\nabla d$ (unit for an exact SDF),
- **penetration depth** (if inside) = $-d(\mathbf q)>0$.

This is exactly Aaltonen's remark: *"With SDF you always know where is the closest surface, even inside the objects. Pushing particles out is simple."* A triangle cannot tell you you're already inside; an SDF can, and it tells you the *direction and magnitude* to push out.

## 33b.3 The SDF boundary force (implicit / Koschier)

A clean, particle-free boundary model uses the SDF directly. The idea: treat the *penetration* as a source of pressure/acceleration. For a fluid particle $i$ at $\mathbf x_i$ with $d_i=d(\mathbf x_i)<0$ (inside), the no-penetration response is a repulsive acceleration along the outward normal, proportional to penetration depth and scaled by the fluid's stiffness:

$$
\mathbf a_i^{\text{boundary}}=-\mathbf n_i\,\cdot\,\Psi(d_i),\qquad \mathbf n_i=\nabla d(\mathbf x_i),\quad d<0.
$$

where $\Psi$ is a stiffly-increasing function of depth (e.g. $\Psi(\cdot)=K\,\rho_0\,(-d_i)$ or a von-of-relationship derived from the pressure at the wall). This is the "push out" term: the deeper the particle, the stronger the ejection, always along $\nabla d$.

**Why this is stable.** Because $d$ is 1-Lipschitz (an exact SDF, or a conservative bound), the force is a *single-valued, smooth-ish* function of position with bounded gradient — no sign ambiguity, no detecting crossings. The force is always directed out of the solid. Contrast with triangles, where you must find which triangle and which side and whether you crossed, and any mistake lets a particle pass through.

**The wall pressure (for accuracy).** To get the correct *pressure* boundary condition (not just a push-out), one can use the SDF to estimate the fluid's pressure at the boundary via a **one-sided/dirichlet-from-SDF** correction. The standard trick (Akinci / SDF boundary methods): the *boundary number density* $\psi_i$ of the solid at $\mathbf x_i$,
$$
\psi_i=\sum_{j\in\text{boundary}} m_j\,W(\mathbf x_i-\mathbf x_j),
$$
is built by sampling boundary particles on (and slightly inside) the SDF surface. Then the density and pressure of the *fluid* are corrected for the presence of the wall, and the force is
$$
\mathbf a_i^{\text{boundary}}=-m_i\sum_{j\in\text{boundary}}\Big(\frac{p_i}{\rho_i^2}+\frac{p_j}{\rho_j^2}\Big)\nabla_iW_ij ,
$$
exactly the same symmetrized form as the fluid pressure force but summed over *boundary* neighbors $j$.

## 33b.4 Boundary particles sampled from the SDF (Akinci et al.)

If you prefer a *particle-based* wall (simpler to parallelize, and it naturally handles curved/moving geometry), generate **boundary particles** directly from the SDF:

1. **Sample the surface** (the zero-isosurface of $d$) — this is a marching-cubes/surface-point sampling step.
2. **Fill a thin volumetric shell** of particles just inside the surface (so they're at density $\rho_s$ near the wall). The SDF tells you exactly how far to offset: place boundary particles at points where the SDF's *distance-to-surface* is in a small band.

Because the SDF is signed, sampling the surface and generating the wall shell is trivial and *error-free* — again the "one representation" advantage.

## 33b.5 Why tunneling is hard, not just handled

The real reason an SDF world is robust is **geometric**. Consider a fast particle moving distance $\lVert\mathbf v\rVert\Delta t$ in one step. To tunnel through a thin shell of thickness $\varepsilon$, the particle must end up on the far side. With a mesh, that's easy if $\lVert\mathbf v\rVert\Delta t>\varepsilon$ and no ray/shape test catches it. With an **SDF**, the *query* for "am I inside?" is a *function of point* — so whether the particle's new position is inside is determined by a single scalar lookup $d(\mathbf x_i^{n+1})<0$. Even if it jumped past the surface, the lookup still returns negative (you're inside), and the push-out force still fires, directing it back out through the surface it came.

**The subtlety.** Tunneling that *passes entirely through a thin feature and ends outside on the other side* (so $d>0$ at the end) is still possible if the feature is thinner than the step and the SDF grid resolution can't resolve it. This is why `d` must resolve the *thinnest* feature you care about — a resolution/memory trade-off (Chapter 33c/e). But "you're inside on the wrong side" — the catastrophic failure mode of mesh collision — is inherently prevented because the SDF is a field, not a surface.

## 33b.6 Combining the fluid force and the SDF push

The complete fluid acceleration on particle $i$ is
$$
\mathbf a_i=\underbrace{\mathbf g}_{\text{gravity}}
+\underbrace{\sum_j m_j\Big(\frac{p_i}{\rho_i^2}+\frac{p_j}{\rho_j^2}\Big)(-\nabla_iW_ij)}_{\text{pressure}}
+\underbrace{\sum_j m_j\frac{4\nu(\mathbf x_ij\cdot\nabla_iW_ij)}{(\rho_i+\rho_j)\lVert\mathbf x_ij\rVert^2}\mathbf v_ij}_{\text{viscosity}}
+\underbrace{\Psi(d_i)\,\mathbf n_i\ \big[\,d_i<0\,\big]}_{\text{SDF boundary}} .
$$

The last term is the coupling. It is *cheap* (one SDF lookup + gradient per particle per step), it is *robust* (no sign ambiguity, no crossing detection), and it *couples the fluid to a world you're already storing for rendering*. That last point is the key architectural win: **the same SDF grid used to render the world is used to simulate the fluid** — no separate collision mesh, no double representation, no "collision geometry vs. render geometry" divergence.

## Exercises

1. **(Derivation)** Show that $\mathbf n=\nabla d$ is the outward normal and that $\mathbf q-d\,\mathbf n$ is the closest-surface point (using the eikonal property, Chapter 06/31b).
2. **(Derivation)** Derive the penetrative push-out acceleration $\mathbf a=-\Psi(d)\,\mathbf n$ and justify its sign/direction.
3. **(Derivation)** Write the boundary-particle force using the symmetrized pressure form, and explain why it's momentum-conserving.
4. **(Analytic)** Explain geometrically why a fast particle can't "end up inside on the wrong side" with an SDF, but can with a thin triangle.
5. **(Analytic)** Identify the remaining tunneling risk (thinner-than-resolution features) and how resolution/mips bound it.
