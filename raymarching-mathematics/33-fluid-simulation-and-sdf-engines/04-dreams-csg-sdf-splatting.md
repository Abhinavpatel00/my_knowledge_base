# Chapter 33d — Dreams' CSG → SDF → Point Cloud Pipeline

Dreams (Media Molecule) is the second canonical "SDF world" system, and it is strikingly different from Claybook: it does not ray-march the SDF to the screen; it **converts an SDF into a dense point cloud (splats)** and renders that with the compute unit, "no triangles." This chapter reconstructs, from Alex Evans' SIGGRAPH 2015 talk, the *architecture* and the *LOD/performance mathematics*, and connects them to the theory of this book.

## 33d.1 The CSG tree → SDF step

Dreams' *creation data* is **an "operationally-transformed" CSG tree** — a live, editable expression tree of distance primitives and boolean operations (Chapter 08 + Chapter 09), with edits (brush adds/subtracts) applied as operations on the tree. This is the *authoring* representation.

To render, the tree is **sampled on the fly to a high-resolution signed distance field**. This is the crucial decision: rather than interpreting the (possibly huge, deeply-nested) CSG tree per sample per pixel (expensive and non-cacheable), it bakes the current tree into an SDF *grid* (a volume texture), which is then queried cheaply and, importantly, is shared by many downstream consumers.

**Why sample to a grid?** As the Dreams notes put it (paraphrase): the CSG functions have to be evaluated somewhere, and doing it at discrete points in a 3D texture is much faster than re-evaluating the whole tree per ray, and it turns the sculpture into an *explicit* representation that can be filtered and LOD'd (the mips). This mirrors Claybook's choice of a grid over analytic evaluation — both accept the memory cost of a grid in exchange for cheap, cacheable, LOD-able sampling.

The pipeline is therefore:

$$
\text{CSG tree} \;\xrightarrow[\text{on the fly}]{\text{sample}}\; \text{high-res SDF grid} \;\xrightarrow[\text{mip-filter}]{\text{}}\; \text{multi-mip SDF} \;\xrightarrow{\text{surface sample}}\; \text{multi-resolution point clouds} \;\xrightarrow{\text{splat}}\; \text{screen}.
$$

## 33d.2 From the SDF to point clouds (splats)

The renderer does **not** triangulate (evans tried marching cubes first — "engine 1: the polygon edition" — and it produced dense meshes with mushy edges and slivers; too heavy). Instead it **samples the surface of the sculpt as dense point clouds**, at multiple resolutions (mips). Each point is a **splat** — a small ball billboard.

**Where the surface points come from.** Points are sampled on the SDF surface (the zero-isosurface). Because the SDF gives the distance to the surface and its normal, sampling is easy: place points at surface locations and orient each splat along the normal $\mathbf n=\nabla d$ (normalized). The *density* of points (spacing) is set by the mip level: coarser mip → fewer, larger splats; finer mip → dense, small splats.

## 33d.3 The LOD / performance machinery

This is where the performance mathematics lives.

### 33d.3.1 Mip-filtered SDF + cluster BVH

Each model is mip-filtered (the SDF grid is mipmapped, §33c.3). For rendering, the model is arranged into a **BVH of clusters**, each cluster containing a fixed budget of points. A *separate* point cloud, clustering, and BVH is computed **for each mip level** of the filtered SDF. So what you have is a *hierarchy of point-cloud LODs*, indexed by mip.

### 33d.3.2 Russian-roulette density transition

To **smoothly** transition between LODs (rather than popping), the number of points rendered per cluster is adapted by **Russian roulette**: start at 256 points/cluster; as the camera approaches (or as the needed LOD refines), the count drops **smoothly from 256 down to 25% (64 points/cluster)** and then to the next, finer LOD. The key word is *smoothly* — the transition probability is chosen so the *expected* number of points changes continuously, eliminating the visible "pop" between levels. This is a stochastic LOD built on the expectation:

$$
\mathbb E[\text{points drawn}]=p\cdot(\text{points in cluster}),
$$
with $p$ a smooth function of screen coverage / distance. Russian roulette *trades* a small amount of noise (variance) for *continuity* — exactly the temporal coherency idea of Chapter 22 applied to point density.

### 33d.3.3 Megasplats vs. microsplats

- **Megasplats** (large, far / coarse): rendered as **flat quads with the rasterizer** (the "big strokes"). Cheap.
- **Microsplats** (near, fine): the renderer switches to a **compute-shader splatter**, where a splat is itself a *mini point cloud* that, up close, "expands" from single pixels to a few thousand points, and in the distance/for "tight" objects **degenerates to single pixels**.

The quote from the talk captures the win: the compute-based splatter *beats the rasterizer* because it doesn't waste time on **alpha = 0 pixels** (the empty, transparent parts of a splat quad). A rasterized quad splat writes many transparent fragments; the splatting shader only "fires" the points that are non-empty, so it does strictly less work. This is a *coverage-aware* rendering: you pay only for the *visible material*, not for the quad's bounding area.

## 33d.4 The "no triangles" geometric model

Dreams' geometry is fundamentally **not triangles**. The primitive is the **splat** (a surface point with an orientation and a radius), and the surface is a point cloud. The *model space* is the SDF; the *render primitive* is the splat.

**Why this matters for the look.** Because the geometry is a dense point cloud sampled from an SDF, there's no polygon silhouette, no faceted edges — the image has the characteristic soft, painterly, "impressionist" look. And because the SDF (not a polygon mesh) is the source of truth, you can sculpt and boolean freely and the surface *is* the SDF, sampled at whatever mip resolution you need — the "infinite detail" impression (bounded, in practice, by memory and the SDF grid resolution).

## 33d.5 The engine-iteration history (and why these choices were made)

Evans' talk is famous for documenting the failures, which are instructive and map directly onto Chapter 25's cost model:

| Engine attempt | Approach | Failure | Lesson |
|----------------|----------|---------|--------|
| 1. "Polygon edition" | Marching cubes of the SDF | dense mushy meshes with slivers | triangulation is wasteful/ugly for SDF |
| 2. Gigavoxels (voxel scene) | Sparse voxel hierarchy | 4–10× too slow for PS4; memory | volume overkill, hard with the art direction |
| 3. Refinement renderer | ray-cast SDF per pixel | too slow | per-pixel ray-cast of the SDF too expensive |
| 4. **Point-cloud splatter** | sample SDF → splats | — | **the win** |

The key architectural realization: **don't ray-cast the SDF per-pixel and don't triangulate it; sample it once (into a point cloud) and splat.** This decouples the *geometry evaluation* (which is expensive: the CSG tree) from the *image formation* (which is cheap: splat points), and it uses the SDF grid as a *cacheable intermediate* between them.

## 33d.6 Connection to this book's theory

The point-cloud splatter is precisely the **"convert an SDF to samples and render"** counterpart to the "ray-march the SDF" of earlier chapters (Claybook; iq's shaders). Both use the SDF as the *source of truth*; they differ in the *image-formation operator*:

$$
\text{ray-march:}\quad \text{pixel}\ \xrightarrow{\ \text{sphere-trace}\ }\ \text{hit point}\ \rightarrow\ \text{shade}
$$
$$
\text{splat:}\quad \text{SDF surface}\ \xrightarrow{\ \text{sample}\ }\ \text{points}\ \xrightarrow{\ \text{splat}\ }\ \text{pixels}
$$

The ray-march does the work per-pixel (adaptive, accurate, but must touch each pixel's ray); the splatter does the work per-surface-point (dense, but naturally LOD'd and view-independent-ish). Both are made possible by the SDF giving you *where the surface is and which way it faces*, for free.

## Exercises

1. **(Derivation)** Explain the CSG-tree → SDF-grid bake and why it's cheaper than re-evaluating the tree per ray.
2. **(Analytic)** Derive the Russian-roulette expected point count and explain how it gives a smooth LOD transition.
3. **(Derivation)** Explain why the compute splatter beats the rasterizer (the alpha=0 argument) quantitatively.
4. **(Analytic)** Compare ray-marching vs. splatting as image-formation operators for an SDF; list when each is better.
5. **(Design)** Sketch a mip-LOD + BVH point-cloud pipeline and what per-cluster budget you'd choose.
