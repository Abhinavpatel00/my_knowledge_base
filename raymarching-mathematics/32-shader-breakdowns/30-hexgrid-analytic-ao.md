# Shader Breakdown 30 — Hexgrid Ray Traversal with Analytic Ambient Occlusion

iq's hex-grid work (which he published as a ShaderToy doodle; his post describes "fast hexgrid-ray traversal (some mul+adds per cell/step) and analytic ambient occlusion based on polygon form factors") is a showcase of two things at once: **(1)** fast *grid traversal* through a hex lattice, and **(2)** **analytic ambient occlusion** that needs no ray-casting. This breakdown derives both.

## 1. The fragment (reconstructed concepts)

```glsl
// 1) hex-grid traversal: march a ray through a hex lattice, cell by cell,
//    adding only a few mul+add per cell.
//    (The hex lattice is the triangular lattice of Chapter 16.)
while(inside){
    compute which hex cell the point is in;      // axial transform
    if(cellOccupled(cell)) → record the cell;    // "hit" a hex
    advance by the small, per-axis tDelta (mul+add);
}

// 2) analytic ambient occlusion from polygon form factors.
//    For the cell the ray is in, sum the "form factor" of each polygon
//    face of the cell as seen from the point, giving a closed-form AO.
float ao = sum over faces of the solid-angle form factor;
```

## 2. Mathematics

### 2.1 The hex-grid traversal

A hex lattice is the **triangular lattice** (Breakdown 16): generators at $60^\circ$. To march a ray through it, you use the **axial coordinates** $\big[\xi,\eta\big]$ (the inverse transform derived in Breakdown 16):
$$
[\xi,\eta]=\Big(p_x-\tfrac{p_y}{\sqrt3},\ \tfrac{2p_y}{\sqrt3}\Big).
$$
The ray $\mathbf r(t)=\mathbf o+t\mathbf d$ maps to a line in the $(\xi,\eta)$ plane with slope given by the Jacobian of the transform applied to $\mathbf d$. The traversal computes, per hex row/column, the $t$-values where the ray crosses each cell boundary — with a per-axis `tDelta` and `tMax`, exactly the DDA of Breakdown 24 but on the skewed hex lattice.

**Why it's cheap.** Each boundary crossing is a few mul+add. Over the whole traversal you visit only the cells the ray actually crosses, in order. This is the same "skip empty space" benefit as the voxel grid (Breakdown 24), applied to a hexagonal lattice.

**The 3D conversion.** For 3D hex-prism cells, the traversal runs in the 2D hex lattice for the $x,z$ directions and a regular 1D lattice for the $y$ (height) direction. The hex prism is a common "cell" for structure/maze/shape studies.

### 2.2 The analytic ambient occlusion

For a point on (or near) a surface, the **ambient occlusion** is the fraction of the hemisphere above the point not blocked by nearby geometry. If the nearby geometry is a set of planar polygons (the faces of the hex cell), the occlusion is the **solid angle** subtended by those faces. A *planar polygon* subtends a solid angle given by the **form factor** (the "projected solid angle"), which has a closed-form expression (the "polygon form factor" / Nusselt analog).

**The form factor.** For a polygonal face as seen from a point at distance, the solid angle (and thus the fraction of the hemisphere it blocks) can be computed from a sum over the face's edges:
$$
F=\frac{1}{2\pi}\sum_{\text{edges}}\ \arccos\!\big(\mathbf e_i\cdot\mathbf e_{i+1}\big)\cdot(\text{sign})
$$
($\mathbf e_i$ the edge vectors from the point, with appropriate normalization). This is an **analytic** formula — no ray-casting, no sampling. Because the "occluder" is a known polygon (the cell face), the AO is a **closed form**, which makes it both fast and exact for that geometry.

**Why this matters.** Instead of marching several AO rays along the normal (Chapter 14, the SDF AO), here the AO is computed **in closed form** from the *known* polygon geometry. It's much faster (no marching, no sampling) and noise-free. It works when the geometry is a *known* polygonal cell (hex grid, voxel grid, mesh), and it's a form of **screen-space/precomputed-free analytic occlusion**.

## 3. The "thinking process"

1. **Ideas.** "I want a fast hex structure with shading." → grid traversal + analytic AO.
2. **Traverse.** "Skip empty cells cheaply." → DDA on the hex (triangular) lattice.
3. **AO.** "How much does the hex geometry block ambient light?" → the **solid-angle form factor** of each cell face.
4. **Why.** "No AO rays, no sampling, exact and fast." → closed-form polygon form factors.

## 4. Field class

| Quantity | Class |
|----------|-------|
| hex lattice traversal | exact (grid) |
| cell occupancy | indicator |
| polygon form-factor AO | analytic (exact for the polygon geometry) |

The AO here is not an SDF-based heuristic (Chapter 14); it's an **analytic form factor** — exact for the given polygon surface. This is a different, and in this case superior, way to get ambient occlusion.

## 5. Extensions

- **3D hex prisms.** Extend the 2D traversal to hex-prism cells for 3D structures.
- **Voxel grid AO.** Apply the same polygon form-factor AO to a voxel grid (the cube faces).
- **GPU-cast AO approximations.** Combine with the ray-based AO for smooth/slow geometry; use analytic form factors for crisp cell geometry.
- **Non-uniform cells.** Generalize to general convex polygonal cells, each contributing a form factor.

## Exercises

1. **(Derivation)** Derive the hex lattice's inverse axial transform $[\xi,\eta]$ and the DDA `tDelta` on the skewed lattice.
2. **(Derivation)** Derive the polygon form factor (solid angle) for a single face.
3. **(Analytic)** Explain why analytic AO is faster and noise-free vs. the SDF ray-based AO.
4. **(Field class)** Distinguish the form-factor AO (exact for polygons) from the SDF AO (heuristic).
5. **(Design)** Apply form-factor AO to a voxel grid.
6. **(Implementation)** Implement the hex-grid traversal with analytic form-factor AO.
