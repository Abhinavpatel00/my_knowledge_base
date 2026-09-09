# Shader Breakdown 24 — iq's "Rounded Voxels": Grid Traversal + Distances

iq's "Rounded Voxels" (and his general grid-marching approach, e.g. the hex-grid work) is a **hybrid**: fast ray traversal through a *voxel/regular grid*, and once a cell is found occupied, an SDF marcher takes over inside the cell. This is a cost model (Chapter 25) favorite: skip empty space via the (exact, cheap) grid traversal, and only pay for the expensive SDF evaluation near the filled cell.

## 1. The fragment (reconstructed key parts)

```glsl
// traverse the ray through a regular grid, cell-by-cell (DDA / Amanatides-Woo)
float gridTraverse(vec3 ro, vec3 rd, out vec3 cell){
    vec3 cellBounds = step(...) ;   // grid coordinate
    ... incremental ray-grid traversal (the "3D DDA") ...
    // for each cell (in order), test: is it "occupied"?
    if(occupied(cell)) {
        // switch to SDF marcher inside this cell
        return sdfMarch(ro, rd, cell);   // a rounded box per cell
    }
    return far;
}
```

## 2. Mathematics

### 2.1 The grid traversal (DDA)

The "3D DDA / Amanatides-Woo" algorithm marches the ray through a regular grid cell-by-cell in order. At each cell, it checks occupancy. The core computation is, per axis, the parameter $t$ at which the ray crosses the cell boundary. Let the cell be a unit cube with the grid coordinate $\mathbf i=\lfloor\mathbf p\rfloor$. The ray enters a cell at

$$
t_{x,\text{enter}}=\frac{\text{cellMin}_x-o_x}{d_x},\qquad
$$

and the "tMax"/"tDelta" per axis are computed from the ray direction: $t\text{Delta}_x=|1/d_x|$ (a normalization trick which is why `1/rd` is used). The algorithm advances along the axis with the smallest next-boundary $t$, in order. **This is an exact, cheap way to visit the empty cells in order — the key to hopping over empty space without an SDF step.**

### 2.2 The SDF inside the occupied cell

Once an occupied grid cell is found, the marcher evaluates the *actual* SDF from the ray origin to find the precise intersection. For "rounded voxels," the SDF inside is a **rounded box**:
$$
d_{\text{cell}}(\mathbf p)=\operatorname{sdRoundedBox}(\mathbf p-\mathbf c_{\text{cell}}).
$$
The rounded box is the Minkowski sum of a box and a ball (Chapter 8.4), which is why the voxels look rounded rather than perfectly cubical — the rounding radius controls the "cubeness."

### 2.3 The field class and cost

| Stage | Operation | Class | Cost |
|-------|-----------|-------|------|
| grid traversal | DDA | exact (occupancy 0/1) | cheap (a few mul+add per cell) |
| occupancy test | an indicator | occupancy field | cheap |
| in-cell SDF | rounded box | exact | expensive (but only near filled cells) |

This is the Chapter 25 cost model in action: the grid traversal *skips empty space* (dominant in sparse scenes), so the expensive SDF evaluation is only done in a tiny number of occupied cells. The big win is the *average* step cost being much lower than a naive full-scene SDF march.

## 3. The "thinking process"

1. **Ideas.** "I want fast rendering of many rounded voxels." → grid + SDF hybrid.
2. **Skip.** "Most of space is empty." → grid-traverse in order, cheaply.
3. **Occupancy.** "Which cells are filled?" → a cheap occupancy test (or a small store).
4. **Refine.** "Inside a filled cell, find the exact surface." → the expensive SDF.
5. **Round.** "Voxels look cubic; round them." → Minkowski sum (rounded box).

## 4. Extensions

- **Hierarchical grid / octree.** For scenes with a wide range of occupancy density, use a hierarchical (octree) traversal.
- **Screen-space grid.** Project the grid to the screen, or run the traversal in screen-space for "voxel sphere-tracing" (iq's "circular" screen-space method).
- **Grid + smooth blends.** Let the in-cell SDF use a smooth-min (Chapter 9) so voxels blend into a continuous surface.
- **Rasterized grid.** Store an occupancy/evaluated grid in a 3D texture for even faster sampling.
- **Hash-grid (sparse).** For very large sparse scenes, use a hash table of cells instead of a dense grid.

## Exercises

1. **(Derivation)** Derive the DDA's `tMax`/`tDelta` from the ray-grid intersection (using $|1/d_x|$).
2. **(Analytic)** Explain why the grid traversal skips empty space cheaply and why the in-cell SDF is only evaluated sparsely.
3. **(Field class)** Classify the occupancy test and the rounded-box SDF.
4. **(Derivation)** Derive the rounded box as a Minkowski sum (Chapter 8.4).
5. **(Design)** Add an octree for non-uniform density; describe the traversal.
6. **(Implementation)** Render a grid of rounded voxels with the DDA + in-cell SDF.
