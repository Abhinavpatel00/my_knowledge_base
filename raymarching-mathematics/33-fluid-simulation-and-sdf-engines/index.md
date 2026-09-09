# Section 33 — Fluid Simulation and SDF Engines

This section closes the "advanced content" series requested in the follow-up: how real engines (Claybook, Dreams) make a *world* out of signed distance fields, and how they simulate *fluid* against that SDF world — the full mathematical model and the performance machinery that makes it real-time.

Two systems stand for the two canonical architectures:

- **Claybook** — a *single* dense **grid SDF** (`1024×1024×512`, 8-bit signed, 5 mips, ~586 MB), regenerated *sparsely* per edited tile, sphere-traced for rendering and used directly as the *boundary* for a GPU SPH fluid. One representation for render + physics.
- **Dreams** — an **operationally-transformed CSG tree** baked on the fly into a *high-resolution SDF grid*, then converted to **multi-resolution point clouds (splats)** and rendered by a compute splatter ("no triangles"), with mip-based LOD and Russian-roulette density transition.

The unifying theme: both make the SDF the *source of truth* for the world, and both use it for as much as possible (render, collision, shading) so the whole system shares one representation and pays for it once.

## Chapters

| Chapter | Topic | Builds on |
|---------|-------|-----------|
| [33a — SPH Fluid Theory](01-sph-fluid-theory.md) | Kernel properties; conservative density; symmetrized pressure; viscosity/XSPH; WCSPH Tait EOS; ISPH pressure Poisson; acoustic & force CFL; counting-sort neighbor search; SoA GPU layout | §33e.4, §33b |
| [33b — Fluid–Solid Coupling: SDF Boundaries](02-sph-boundaries-and-sdf-coupling.md) | Why an SDF boundary beats triangles; the SDF boundary force; Akinci boundary particles; why tunneling is geometrically hard | §33a |
| [33c — Claybook's World SDF](03-claybook-world-sdf.md) | The exact `1024×1024×512` 8-bit/5-mip/~586 MB representation; reproduce 586 MB & 1/32-voxel precision; why mips double step; sparse tile generation; GSM; async compute | §33b, §33e |
| [33d — Dreams' CSG → SDF → Splat](04-dreams-csg-sdf-splatting.md) | CSG tree → SDF grid → mip point clouds; cluster BVH + per-mip LOD; Russian roulette; megasplats vs. microsplats; compute splatter beats rasterizer (alpha=0); the engine-iteration failures | §33e |
| [33e — Performance & Numerical Analysis](05-performance-and-numerical-analysis.md) | Memory & precision budget math; trilinear interpolation error; grid-SDF "bound not exact"; analytic grid normals; mip-sphere-tracing step; SPH stability; the per-frame cost decomposition | §33a–33d |

## Reading order

For the *mathematical core*, read 33a (SPH) → 33b (SDF coupling). For the *engine architecture*, read 33c (Claybook) → 33d (Dreams) → 33e (performance/numerics).

## Related sections

- Chapter 06 (distance fields/exact vs. bound), Chapter 12 (differentials/normals), Chapter 14 (shadows/AO), Chapter 25 (performance), Chapter 31a (lipschitz/convergence-certified bounds).
