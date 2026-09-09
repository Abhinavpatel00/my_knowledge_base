# Chapter 33a — Smoothed-Particle Hydrodynamics: The Full Discretization

Claybook's "clay" is a fluid. To understand why an SDF world is the ideal boundary for it, and how it stays real-time on a GPU, we need the full SPH framework: the kernel approximation, the discretization of the Navier–Stokes equations, the two ways of enforcing incompressibility, the stability/timestep analysis, and the GPU data layout. This chapter is self-contained and rigorous.

## 33a.1 The continuum problem

We model a fluid with the incompressible Navier–Stokes equations

$$
\frac{\partial \mathbf v}{\partial t}+(\mathbf v\cdot\nabla)\mathbf v
=-\frac{1}{\rho}\nabla p+\nu\nabla^2\mathbf v+\mathbf g,\qquad \nabla\cdot\mathbf v=0,
$$

with $\mathbf v$ velocity, $p$ pressure, $\rho$ density, $\nu$ kinematic viscosity, $\mathbf g$ body force. SPH is a **Lagrangian mesh-free** method: the fluid is represented by $N$ particles carrying mass $m_i$, position $\mathbf x_i$, and velocity $\mathbf v_i$. The field quantities (density, pressure, velocity) are reconstructed *at arbitrary points* by convolution with a smoothing kernel $W$.

## 33a.2 The kernel approximation

Define a **smoothing kernel** $W_h(\mathbf x)=W(\mathbf x,h)$ with smoothing length $h$, satisfying

1. **Normalization:** $\displaystyle\int_{\mathbb R^3} W\,\mathrm dV=1$.
2. **Compact support:** $W(\mathbf x)=0$ for $\lVert\mathbf x\rVert>2h$.
3. **Positivity and monotonicity:** $W\ge0$, $W(0)=\max$, decreasing.
4. **Symmetry:** $W(-\mathbf x)=W(\mathbf x)$ (so $\nabla W$ is odd).

The **kernel approximation** of a field $A$ is
$$
\langle A(\mathbf x)\rangle=\int_{\mathbb R^3} A(\mathbf x')W(\mathbf x-\mathbf x',h)\,\mathrm d\mathbf x'.
$$
Using the particle discretization (a weighted sum over particles, with volume $V_j=m_j/\rho_j$):

$$
\langle A(\mathbf x_i)\rangle\approx\sum_j V_j A(\mathbf x_j)W_ij
=\sum_j \frac{m_j}{\rho_j}A_j\,W_ij,
$$

where $W_ij=W(\mathbf x_i-\mathbf x_j,h)$.

### 33a.3 Common kernels

**Cubic spline (B-spline).** Let $q=\lVert\mathbf x\rVert/h$:
$$
W(q)=\sigma_h\begin{cases}
1-\tfrac32 q^2+\tfrac34 q^3,&0\le q<1,\\
\tfrac14(2-q)^3,&1\le q<2,\\
0,&q\ge2.
\end{cases}
$$
The constant $\sigma_h$ is set by the normalization $\int W\,dV=1$; in 3D, $\sigma_h=1/(\pi h^3)$ using the common convention (the reader can verify via $\int_0^2 W\,4\pi r^2\,dr=1$, which fixes $\sigma_h$ uniquely). The cubic spline is $\mathcal C^2$ but its second derivative is not continuous at the compact-support boundary, which can cause slight density noise.

**Wendland (quintic, $\mathcal C^2$).** 
$$
W(q)=\sigma_h\begin{cases}
(1-\tfrac q2)^4(2q+1)&0\le q<2,\\
0,&q\ge2,
\end{cases}
\qquad \sigma_h^{\text{3D}}=\frac{21}{16\pi h^3}.
$$
The Wendland kernel is positive in Fourier space (it has good "pairing" behavior — the first derivative is bounded and it does not cause particle clumping that the cubic spline can exhibit), so it is preferred in modern weakly-compressible SPH.

The derivatives are what matter for the discrete operators. For a radial kernel $W=W(r)$, the gradient with respect to $\mathbf x_i$ (holding $\mathbf x_j$ fixed) is
$$
\nabla_i W_ij=\frac{\mathrm dW}{\mathrm dr}(r)\ \frac{\mathbf x_i-\mathbf x_j}{r},
\qquad r=\lVert\mathbf x_i-\mathbf x_j\rVert,\qquad \nabla_iW_ij=-\nabla_jW_ij .
$$

## 33a.4 Discretizing the equations

### 33a.4.1 Density

$$
\rho_i=\sum_j m_j\,W_ij .
$$
This is the standard, *conservative* density estimate (it does not require solving, and it automatically satisfies $\langle\rho\rangle$ to the integration-consistent degree of the kernel).

### 33a.4.2 Momentum

The pressure acceleration is discretized in a **symmetrized** form that conserves linear and angular momentum exactly:
$$
\frac{\mathrm d\mathbf v_i}{\mathrm dt}\bigg|_{\text{press}}
=-\sum_j m_j\Big(\frac{p_i}{\rho_i^2}+\frac{p_j}{\rho_j^2}\Big)\nabla_i W_ij .
$$
**Why symmetric.** Writing $G(x)=x/\rho^2$-style, the pair $(\frac{p_i}{\rho_i^2}+\frac{p_j}{\rho_j^2})$ is symmetric under $i\leftrightarrow j$ while $\nabla_iW_ij=-\nabla_jW_ij$, so the sum antisymmetrizes: particle $i$ pushes $j$ exactly opposite to how $j$ pushes $i$. This is what makes the method conserve momentum (otherwise spurious "self-forces" appear).

### 33a.4.3 Viscosity

The viscous term $\nu\nabla^2\mathbf v$ needs a discretization of the Laplacian (second derivative of the kernel). The **Morris** operator (for laminar viscosity):
$$
\frac{\mathrm d\mathbf v_i}{\mathrm dt}\bigg|_{\text{visc}}
=\sum_j m_j\,\frac{4\nu\,(\mathbf x_ij\cdot\nabla_iW_ij)}{(\rho_i+\rho_j)\,\lVert\mathbf x_ij\rVert^2}\,\mathbf v_ij,
$$
with $\mathbf x_ij=\mathbf x_i-\mathbf x_j$, $\mathbf v_ij=\mathbf v_i-\mathbf v_j$. This uses the fact that $\nabla^2$ in SPH is approximated by a "double summation" that reuses the kernel gradient and a $1/r$ regularization.

For turbulent/realistic behaviour, an **artificial viscosity** (Monaghan) is often added to the pressure term:
$$
\Pi_{ij}=\begin{cases}
-\frac{\alpha c\,\mu_{ij}}{\bar\rho_{ij}},&\mathbf v_{ij}\cdot\mathbf x_{ij}<0,\\
0,&\text{otherwise},
\end{cases}\qquad
\mu_{ij}=\frac{h\,\mathbf v_{ij}\cdot\mathbf x_{ij}}{\lVert\mathbf x_{ij}\rVert^2+\eta^2},
$$
added inside the pressure bracket; $\alpha$ is a tunable dissipation, $c$ the sound speed. The $\mathbf v_{ij}\cdot\mathbf x_{ij}<0$ condition ensures it only dissipates when particles approach.

### 33a.4.4 Position (XSPH)

To reduce disorder and avoid "checkerboard" particle patterns, the **XSPH** correction advects particles with a smoothed velocity:
$$
\frac{\mathrm d\mathbf x_i}{\mathrm dt}=\mathbf v_i+\varepsilon\sum_j\frac{m_j}{\bar\rho_{ij}}\big(\mathbf v_j-\mathbf v_i\big)W_ij,\qquad 0\le\varepsilon\le0.5 .
$$
This is a mild velocity smoothing; $\varepsilon$ is typically $0.1$–$0.5$.

## 33a.5 Enforcing incompressibility

There are two families, and which one you use changes the whole solver.

### 33a.5.1 Weakly-compressible SPH (WCSPH)

Treat the fluid as *slightly* compressible and close the system with an **equation of state** relating pressure to density. The **Tait EOS**:
$$
p_i=B\Big[\Big(\frac{\rho_i}{\rho_0}\Big)^{\gamma}-1\Big],\qquad
B=\frac{\rho_0\,c^2}{\gamma},\qquad \gamma\approx7 .
$$
Here $\rho_0$ is the rest density and $c$ is an **artificial** sound speed chosen so density fluctuations stay under ~1%:
$$
c=10\,\max(\lVert\mathbf v\rVert).
$$
One simply integrates pressure forces and advects particles; pressure "pops" the density back toward $\rho_0$. **Pros:** simple, no linear solve, trivially parallel. **Cons:** strict timestep limit (the acoustic CFL), and density/pressure noise. This is the family most compatible with a GPU, real-time, billiards-of-particles solver (and the "clay is a slightly-compressible fluid" model).

### 33a.5.2 Projection / divergence-free (ISPH)

Solve a **pressure Poisson equation** enforcing $\nabla\cdot\mathbf v=0$ (or a density constraint) each step:
$$
\nabla\cdot\Big(\frac{\nabla p}{\rho}\Big)=\frac{\rho}{\Delta t}\nabla\cdot\mathbf v\quad\text{or}\quad
\nabla^2p_i=-\frac{\rho_0}{\Delta t}\nabla\cdot\mathbf v_i .
$$
Discretized as a sparse linear system over the particle graph (each row uses the neighbor Laplacian $\sum_j$). This gives near-incompressible, low-noise flow but requires iterating a large sparse system (Jacobi/PCG/GPU-preconditioned) — more expensive and harder to keep real-time. Claybook targets the *cheap* end with WCSPH-like behaviour plus an SDF boundary.

### 33a.5.3 The stiffness / timestep analysis

The stability of SPH is governed by the **acoustic CFL** and the **force/free-surface** condition:

$$
\Delta t\le\alpha\frac{h}{c+\max_i\lVert\mathbf v_i\rVert},\qquad 0.2\lesssim\alpha\lesssim0.5,
$$

and, for free-surface forces and surface tension,
$$
\Delta t\le\beta\sqrt{\frac{h}{\max_i\lVert a_i\rVert}},\qquad 0.4\lesssim\beta\lesssim0.7 .
$$

The first says the fastest information (sound) must not cross more than a fraction of a smoothing length per step; the second says the fastest *particle* must not move more than a compact-support fraction per step. For real-time, one *intentionally* slows the acoustic speed (artificial $c$) so the CFL allows large $\Delta t$ — this is the entire trick behind "isn't that too stiff?" — you trade peak accuracy for a relaxed timestep.

## 33a.6 Neighbor search and the GPU data layout

SPH's cost is $O(N\times\text{neighbors})$; the neighbors come from a **spatial hash** over the compact support.

### 33a.6.1 Uniform-grid / cell-linked list

Partition space into cells of size $h$ (or $2h$). Each particle maps to a cell $\mathbf c_i=\lfloor\mathbf x_i/h\rfloor$. Neighbors of $i$ are the particles in the $3\times3\times3$ (or $5^3$, depending on kernel support) neighborhood of cells. For a *fixed-support* kernel this is a constant bound, so the total work is linear.

### 33a.6.2 Counting sort / radix sort for GPU

To make the lookup cache-friendly and atomic-free, sort particles by cell. The standard GPU pipeline:

1. **Cell ID:** $\mathbf c_i$ → a scalar hash $\mathbf c_i\cdot(\ldots)$.
2. **Counting:** histogram of cell counts.
3. **Prefix sum (scan):** exclusive scan gives each cell's starting index in the sorted array.
4. **Scatter:** each particle writes itself into `sorted[cellStart + atomicAdd(cellCounter)]`.

Now a particle and its neighbors are contiguous in memory (coherent), and the neighbor loop is a simple range scan over the sorted buffer. This is what makes millions of SPH particles tractable on a GPU.

### 33a.6.3 Structure-of-arrays (SoA) layout

Cache-coherent layouts store positions `x`, velocities `v`, densities `rho`, pressures `p` as separate arrays. This maximizes memory bandwidth and lets a compute shader process a tile of particles using **shared memory** (the analogous "groupshared memory" Claybook uses for its brush grid). For a warp/group, load the neighbor set into shared memory once and reuse it across the group's particles.

## 33a.7 The full WCSPH update (one step)

```
for each particle i:
    find neighbors N(i) via the cell hash
    rho_i = Σ_j m_j W_ij                              (density)
    p_i   = B[(rho_i/rho0)^γ - 1]                       (Tait EOS)
for each particle i:
    a_i = g + (-Σ_j m_j (p_i/rho_i² + p_j/rho_j²)∇W_ij)   (pressure)
             + Σ_j m_j 4ν(x_ij·∇W_ij)/((ρ_i+ρ_j)|x_ij|²) v_ij   (viscosity)
for each particle i:
    v_i += Δt * a_i                                      (symplectic Euler)
    x_i += Δt * (v_i + XSPH correction)
    apply boundary constraint via the world SDF          (Ch 33b)
```

This is the mathematical core. The **timestep** $\Delta t$ follows §33a.5.3, the neighbor search follows §33a.6, and the whole thing is a fixed set of gather/scatter passes — ideal for GPU compute (and for running asynchronously with rendering, as Claybook does).

## 33a.8 The coupling to an SDF world

The final line — "apply boundary constraint via the world SDF" — is the *whole reason* Claybook can have clay that flows through a destructible, deforming environment. Because the world is stored as a **signed distance field**, the fluid solver can, for any particle, query:

- the **signed distance** to the nearest solid (its penetration depth), and
- the **normal** $\mathbf n=\nabla d$ (the direction to push out).

This is the subject of Chapter 33b, and it is the mathematical bridge between the SPH fluid and the SDF world.

## Exercises

1. **(Derivation)** Verify the cubic-spline normalization by computing $\int_0^2 W\,4\pi r^2\,dr=1$ and deriving $\sigma_h^{3d}$.
2. **(Derivation)** Show $\nabla_iW_ij=-\nabla_jW_ij$, and hence that the symmetrized pressure force conserves linear momentum.
3. **(Derivation)** Derive the Morris viscous operator by applying the SPH Laplacian identity $\nabla^2 A\approx\sum_j\frac{m_j}{\rho_j}(A_i-A_j)\nabla^2W_ij$ to the velocity.
4. **(Derivation)** Show the Tait EOS with $\gamma=7$ makes small density perturbations produce large pressure (the "stiffness").
5. **(Analytic)** Derive the acoustic CFL timestep and explain why an artificial, reduced sound speed relaxes it.
6. **(Implementation)** Sketch the counting-sort neighbor pipeline (cell hash → histogram → scan → scatter) and the SoA compute-shader layout.
