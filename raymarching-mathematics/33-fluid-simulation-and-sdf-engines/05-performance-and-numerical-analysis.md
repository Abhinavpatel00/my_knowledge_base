# Chapter 33e — Performance and Numerical Analysis of Engine-Scale SDF Systems

This chapter is the mathematical finishing layer: the memory/compute budget, the discretization error of a *grid-sampled* SDF, the accuracy of numerical normals from a grid, the mip-sphere-tracing step, and the stable-preconditioned SPH solve. Together these explain *why* Claybook/Dreams hit their budgets and *where* they'd fail.

## 33e.1 The memory budget math

The world grid is $N_x\cdot N_y\cdot N_z$ voxels. For Claybook that's $2^{29}$ voxels. Two drivers of cost:

- **Bytes per voxel.** 8-bit = 1 byte, but you pay for *range × precision*. With $B$ bytes per value, Q bits (256 for 8-bit signed), range $R$ voxels, the precision step is $R/(Q-1)$ voxels. For Claybook, $R=8$, $Q=256$: $\frac{8}{255}\approx\frac{1}{32}$ voxel. To *halve* the precision step you need either double the bits (more memory) or half the range (tighter bound, more clamping).
- **Mip overhead.** The mips add a factor $\sum_{m\ge1}1/8^m=1/7\approx14.3\%$ per level chain… actually the 3D mip shrinks volume by 8 each level, so the tail sums to $1/8+1/64+\cdots=\frac{1}{7}\approx0.1428$ of the base — reproducing the $1.1428$ factor we used to explain 586 MB. **The mips cost only ~14%, which is why they're free in practice.**

**The precision-bandwidth trade-off.** Total bytes = voxels $\times$ bytes/voxel $\times$ (1 + 1/7). Reducing bytes/voxel (e.g. to 8-bit from 32-bit float) is a 4× memory saving *and* a 4× bandwidth saving (the ray-march's trilinear samples hit memory bandwidth, not just capacity). This is why Claybook uses 8-bit signed, not float — the *bandwidth* of per-pixel SDF sampling dominates, and 8-bit quadruples the effective cache/bandwidth for the same capacity.

## 33e.2 Discretization error of a grid SDF

The stored value is a sample of an *exact* distance $d_\text{exact}$ at grid points, interpolated trilinearly:
$$
d_{\text{grid}}(\mathbf x)=\sum_{c\in\text{cell}} \ell_c(\mathbf x)\,d_{\text{exact}}(\mathbf x_c),
$$
where $\ell_c$ are the trilinear basis functions. Two errors:

1. **Truncation error.** Trilinear interpolation is second-order accurate for a smooth, convex function:
$$
d_{\text{grid}}(\mathbf x)=d_{\text{exact}}(\mathbf x)+O(h^2\,\lVert H_{d}\rVert)\quad(h=\text{voxel size}).
$$
For a *distance* field, $\lVert H_d\rVert$ scales like curvature; so near sharp features (edges, corners — the medial axis of Chapter 06) the error is larger. The JCGT paper notes this is exactly what produces the visible "voxel" artifacts when the viewer is close: the interpolated field deviates from the true distance near corners/edges, and the normals (and surfaces) show it.

2. **The 1-Lipschitz question.** The interpolant of a 1-Lipschitz function is **not** necessarily 1-Lipschitz. Trilinear interpolation of exact distance values can produce a field whose gradient exceeds 1 in some cells (a local overestimate), meaning the *step* `d_grid` can be $> \text{true distance}$ there → potential overstepping. In practice this is small (it's an $O(h^2)$ deviation), but it's the precise reason a grid SDF is a **bound/estimator**, not exact, and why you add a small safety scale when sampling a coarser mip. This is the engine-scale version of the exact/bound taxonomy of Chapter 06, made concrete by interpolation.

**Normals from a grid.** The analytic normal of the trilinear field,
$$
\mathbf n=\nabla d_{\text{grid}}=\frac{\partial}{\partial\mathbf x}\Big(\sum_c\ell_c d_c\Big),
$$
is exact within each cell (it's a polynomial), but discontinuous across cell faces. Computing it analytically (rather than via finite differences of the field) removes the finite-difference noise of Chapter 12 entirely — the JCGT paper compares "analytic normals" (from the trilinear derivative) and reports them as superior near the voxel artifacts. The cost is that you must differentiate the interpolation, which is cheap.

## 33e.3 Mip-sphere-tracing step scaling

The mip-filtered SDF is a *bound* with a larger allowed step. If mip $m$ stores SDF values computed from $\sim 2^m$-sized voxel regions, the effective step bound is roughly
$$
\text{step}_m\sim 2^m\,h_{\text{base}} .
$$
The marcher advances by $d_{\text{grid}}^{(m)}$ *if* the bound is valid at that "radius." The full algorithm:

```
for each ray:
  m = 0 (coarsest)
  while not hit and t < T_max:
    choose the finest mip m whose distance bound is still ≥ (a fraction of) the step
       i.e. select m so that d_grid(m)(p) is not limited by mip coarseness
    t += d_grid^(m)(p - ...)      # step by the mip-scaled bound
  refine with the base mip near the surface
```

**The correctness/performance tension.** A coarser mip gives a larger step (faster) but a *looser* bound (must not overstep thin features). The selection rule: advance by the largest step that is *still a safe underestimator* — monitoring the ratio `d/step` and dropping to a finer mip when the bound gets tight. This is the mip-based analogue of the *adaptive* step of §7.10 and the local-Lipschitz step of §31a.4, applied over an LOD hierarchy.

## 33e.4 The SPH solve: cost and stability

The fluid solve (§33a) is $O(N \cdot k)$ per step with $k$ = avg neighbors ($\sim25$–$50$ for a cubic-spline / Wendland kernel), and must satisfy the CFL timestep. Two couplings to the SDF world matter:

- **The "clay-fluid" density.** If the clay is modelled as a slightly-compressible WCSPH fluid, the *number of steps per frame* is set by the acoustic CFL with a *reduced* artificial sound speed — this is the deliberate stiffness/realtime trade-off (§33a.5.3).
- **The SDF boundary cost.** Each particle does one trilinear SDF lookup + gradient per step — negligible compared to the neighbor loop. So the *fluid* cost is dominated by neighbor search, not by the SDF boundary. This is why an SDF world doesn't penalize the simulator.

The particle count and the timestep are the two knobs for the fluid's GPU budget. If you double the particles, you double the per-step cost; if you double the timestep (by lowering the artificial $c$), you halve the steps per frame at the cost of more compressibility noise. Both are exactly the "steps × cost-per-step" decomposition of Chapter 25, applied to the fluid.

## 33e.5 Putting it together: the per-frame budget

$$
\text{cost}_\text{frame}\approx\underbrace{P\cdot S\cdot C_\text{step}}_{\text{ray-march pixels}}
+\underbrace{N_\text{part}\cdot k\cdot C_\text{neigh}}_{\text{fluid steps}}
+\underbrace{V_\text{edited}\cdot C_\text{tile}}_{\text{sparse SDF edit}},
$$
where $P$ = pixels, $S$ = avg marcher steps, $C_\text{step}$ = cost per SDF sample (an 8-bit trilinear read), $N_\text{part}$ = particles, $k$ = neighbors, $C_\text{neigh}$ = neighbor-loop cost, $V_\text{edited}$ = edited volume, $C_\text{tile}$ = per-tile regeneration cost.

**The three terms are (mostly) independent**, which is exactly why such a system can be real-time:
- Ray-march cost scales with visible pixels and the mip step quality.
- Fluid cost scales with particles × neighbors.
- Edit cost scales with *edited volume*, not world size.

This is a *decomposition* of cost. The SDF makes the three *share* one representation (so you're not paying three separate geometry stores), and mips/sparse tiles make two of them *locality-bounded*. That's the full answer to "how do they make the world out of SDFs and make it performant."

## 33e.6 Stable-SPH preamble

A few numerical stabilizers that keep a real-time SPH solver from blowing up:

- **Density re-sampling / Shepard correction.** Divide the density integral by the kernel's partition of unity: $\rho_i^{(\text{corr})}=\frac{\sum_j m_jW_ij}{\sum_j V_jW_ij}$, which fixes boundary density loss.
- **Negative-pressure clamp.** Clamp $p\ge0$ (or a small value) to avoid attractive unphysical forces.
- **Approximate (Jacobian-free) projection.** Where incompressibility matters, solve the PPE with a *few* Jacobi/sweep iterations rather than to convergence.
- **Pairing-free kernels.** Use a positive-Fourier kernel (Wendland) to avoid the clumping/clustering that the cubic spline allows.

## Exercises

1. **(Calculation)** Verify the $1/7$ mip overhead and reproduce the ~586 MB from $2^{29}$ voxels, 8-bit, 5 mips.
2. **(Derivation)** Derive the trilinear interpolation error $O(h^2\lVert H_d\rVert)$ and identify where it blows up (near edges/corners).
3. **(Analytic)** Explain why a grid SDF is a *bound*, not exact, and how the mip choice can overstep.
4. **(Derivation)** Differentiate the trilinear field to get the analytic normal; explain why it's exact within a cell but discontinuous at faces.
5. **(Analytic)** Write the per-frame budget decomposition and explain why the three terms are independent.
6. **(Design)** Choose between 8-bit signed, 16-bit half, and 32-bit float for a world SDF in terms of capacity, bandwidth, and precision; justify.
