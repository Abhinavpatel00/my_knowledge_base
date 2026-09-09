# Chapter 33c — Claybook's World SDF: Representation, Sparse Generation, and Performance

This chapter reconstructs, from the GDC 2018 talk of Sebastian Aaltonen and Sami Kantonen, the *exact* world representation Claybook uses, and derives *why* its numbers are what they are. It is the most direct answer to "how do they make the world out of SDFs and keep it fast."

## 33c.1 The core decision: an SDF grid, not analytic functions

A ShaderToy-style *analytic* SDF (Chapter 08) is beautiful but carries no data — you can't *sculpt* it or *store* deformation. Claybook instead stores the world as a **dense hierarchical grid of signed distance values**: an **SDF grid** (volume texture), queried with trilinear filtering. This is the same choice as in the JCGT paper and, in spirit, in Dreams. The trade-off is *fidelity + mutability* (you can bake edits into the grid) versus *memory* (it's not free like a formula).

Analytic SDFs are still used for the **brushes** — small, pre-baked volume textures that act as CSG tools applied to the world grid.

## 33c.2 The exact world-SDF budget (and how to reproduce it)

| Quantity | Value | Where it comes from |
|----------|-------|---------------------|
| Resolution | $1024\times1024\times512$ | the world's effective detail |
| Voxels | $1.024\times1.024\times0.512\times10^{?}=5.369\times10^8$ | $=2^{29}$ |
| Format | 8-bit signed | 1 byte/voxel |
| Mip levels | 5 | LOD for sphere tracing |
| Total size | **586 MB** | see computation below |
| Stored distance range | $[-4,+4]$ voxels | signed value × quantization |
| Precision | $256\,\text{values}/8\,\text{voxels}=1/32\,\text{voxel}$ | $256/8=32$ levels/voxel |
| Max step | doubled per mip level | mip-filtered SDF → larger jumps |

**Computing the 586 MB.** The base level is $2^{29}$ voxels $=536{,}870{,}912$ bytes at 1 B/voxel $=512$ MiB. The 5 mip levels sum to the geometric series
$$
512\left(1+\frac18+\frac1{64}+\frac1{512}+\frac1{4096}\right)
\approx512\times1.1428\approx584.7\text{ MiB},
$$
which is precisely the reported **~586 MB**. So the "8-bit signed" + mip sum exactly explains the memory. This is a nice sanity check of the representation.

**Computing the 1/32 voxel precision.** An 8-bit *signed* value stores $2^8=256$ levels. The distance range is $[-4,+4]$ voxels, a span of 8 voxels. So the quantization step is
$$
\frac{8\ \text{voxels}}{256\ \text{levels}}=\frac{1}{32}\ \text{voxels/level}.
$$
The consequence: the *finest* distance resolution is $1/32$ of a voxel. This matters because near the surface, the ray-march's tolerance must not exceed roughly this, or you see quantization banding.

**Why 8-bit signed and not float.** 8-bit is 4× smaller than a 32-bit float (or 2× smaller than 16-bit half), and the range $[-4,+4]$ voxels with $1/32$ precision is enough for the *near-surface* ray march because the mips provide the large-scale distances and the base level provides the fine, near-surface detail. This is a deliberate precision/accuracy/bandwidth trade-off — exactly the "precision management" of Chapter 25 applied to an engine.

## 33c.3 Why mips double the step distance

This is the crucial rendering-speed insight. A full-resolution SDF lets you step by the *true* (small) distance near a surface, but far from the surface you want to step *fast*. In a mip hierarchy, the coarser mips store a *filtered* distance that is still a conservative bound but with a *magnified* step scale:

$$
\text{max step at mip }m\ \propto\ 2^{m}\times\text{(base step)}.
$$

So at the coarse mip you can leap across empty space, and you only refine to the fine mip as the ray approaches the surface. This is the same "hierarchical / bounding-volume" idea of Chapter 25, realized by the GPU's own mip filtering. Two consequences:

1. **Sphere tracing from a grid.** Each sample is a trilinear-interpolated SDF lookup (Chapter 33e discusses the interpolation error). The mip supplies the step bound.
2. **The mip's guarantee.** A mip-filtered SDF is only a *bound* (filtering can slightly violate the exact SDF property); using a mip that's too coarse near a thin feature can overstep. So the shader selects the finest mip that still allows a large-enough step — a per-sample LOD decision. This is a precise, quantitative location of the "bound vs. exact" tension of Chapter 06.

## 33c.4 Sparse world-SDF generation (the performance mechanism)

Claybook does not regenerate the whole $2^{29}$-voxel grid every frame. It regenerates **only the tiles that an edited brush touches** and builds the mips sparsely. The GPU pipeline (from the talk):

1. **Generate the SDF brush grid.** Each brush is a small, read-only baked volume texture.
2. **Generate dispatch coordinates and mip masks.** Only tiles whose *influence region* intersects an edit are scheduled.
3. **Generate level 0 in $8\times8\times8$ tiles (sparse).** Each $8^3$ tile chunk: dispatch of $64\times64\times32$ threads in $4\times4\times4$ groups.
4. **Generate mips (sparse).**

Concretely, the per-tile computation:

- **Cull** a brush at the tile center $T$: sample the brush; if its SDF value exceeds the grid tile bounds + 4 voxels (i.e. the brush's effect is outside this tile), discard it.
- **Atomic add** the surviving brushes to **groupshared memory (GSM)**.
- **Loop over the brushes in GSM**, sampling each at the cell center $C$; if it's accepted, combine it (a CSG operation) into the grid, written **linearly**.
- **Compaction** via local and global atomics so the output buffer is packed.

The mathematics of the cull: a brush at center $T$ affects tile cells only if its radius reaches them; the `+4 voxels` is a safety margin equal to the brush's influence range (and matches the stored distance range pre-bound). Only tiles near an edit are scheduled, so the *cost scales with the edited volume, not with the world size* — the crucial "sparse" win.

**The groupshared memory (GSM) role.** By loading the candidate *brushes* into GSM once per thread group, the group avoids repeatedly re-fetching from global memory, and the per-thread work is a tight loop over a small set in fast memory. This is a textbook example of the locality optimization of Chapter 25 (move the cost of the *brush list* amortized over the group).

## 33c.5 The physics/fluid coupling and async compute

Claybook runs **clay and fluid simulation on the GPU** (a WCSPH-style particle solver, Chapter 33a) *against* this SDF grid as the boundary (Chapter 33b). Three facts make this whole system real-time:

1. **One representation for render + physics.** The SDF grid is both the ray-tracing geometry *and* the collision/simulation boundary. No separate collision mesh, no divergence between "what you see" and "what you collide with."
2. **SDF = robust collision.** As derived in Chapter 33b, the signed field always knows the closest surface and normal, even inside the object, so particles are pushed out robustly with no tunneling (for features above resolution).
3. **Async compute.** Claybook overlaps the physics/fluid compute passes with rendering (and other work) on the GPU's async compute queues, and uses mip-aware sparse regeneration and GPU-side compaction to keep the engine at 60-ish FPS with fully dynamic, destructible, no-baked-light clay.

**The cost model.** Per frame: sphere-trace the world SDF grid for pixels, run the SPH timestep for particles, and sparsely regenerate only edited tiles. Because the world SDF is mip-filtered and sparsely updated, the *rendering* cost is bounded by the visible tiles, the *physics* by the particle count, and the *edit* cost by the volume of the edit — none scales with the full world size. This is a decomposition of the Chapter 25 cost model into independent, localizable terms.

## 33c.6 Why "no baked lighting / AO / shadows, all real-time"

Because the world is a dynamic SDF, it *changes every frame* (clay flows, the terrain deforms). Any baked lighting/AO/shadow would be stale the moment a particle moves. So Claybook computes all shading *on the fly* from the SDF: sphere-traced shadows and SDF ambient occlusion (Chapter 14), computed per-pixel from the SDF grid. The cost of "everything real-time" is that the lighting must be derivable from the SDF in a single per-pixel evaluation — which is exactly what this book's earlier chapters describe (normals from the field gradient, soft shadows from the field along the light, AO from the field along the normal).

## Exercises

1. **(Calculation)** Reproduce the 586 MB and the 1/32-voxel precision from the stated resolution/format/range.
2. **(Derivation)** Show that coarse mips give larger step distances and derive the $2^m$ scaling; explain the "bound, not exact" caveat.
3. **(Design)** Derive the brush-culling criterion (when can a brush be skipped for a given tile) and the `+4` safety margin.
4. **(Analytic)** Explain how sparse regeneration makes cost scale with edited volume rather than world size.
5. **(Derivation)** Explain why async compute (overlapping physics/fluid/rendering) helps, and identify the dependencies that must be ordered.
