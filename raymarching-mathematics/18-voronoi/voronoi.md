# Chapter 18 — Voronoi and Cellular Geometry

Voronoi diagrams partition space according to *nearest site*. They are the mathematical engine behind cellular patterns, cracks, bubbles, biological tissue, and a huge class of "cell-based" procedural surfaces. This chapter derives the geometry and builds the shader constructions.

## 18.1 Definition and the nearest-site selection

Given a discrete set of **sites** $\{\mathbf c_i\}$, the **Voronoi cell** of site $\mathbf c_i$ is

$$
V_i=\{\mathbf p:\lVert\mathbf p-\mathbf c_i\rVert\le\lVert\mathbf p-\mathbf c_j\rVert\ \forall j\}.
$$

The **Voronoi diagram** is the partition of space into these cells. The defining operation for shader purposes is: for a query point $\mathbf p$, determine the **nearest site** and its distance,

$$
d_{\text{nearest}}=\min_i\lVert\mathbf p-\mathbf c_i\rVert.
$$

**The lattice trick.** To make this tractable procedurally, generate sites on a *lattice*. For a query point $\mathbf p$, the nearest site lies in the integer cell containing $\mathbf p$ or one of its neighbors. Specifically, for each candidate cell $\lfloor\mathbf p\rfloor+\delta$ (with $\delta$ ranging over the $3\times3$ (2D) or $3\times3\times3$ (3D) neighborhood), place a site at $\mathbf c=\text{cell}+\mathbf k$ (where $\mathbf k$ is a per-cell random offset from a hash), and compare distances. This bounds the search to a constant number of sites.

**Why a lattice works.** The sites are generated at integer grid points with a random jitter within the unit cell. Then the closest site to $\mathbf p$ must be among the sites in the cell containing $\mathbf p$ and its immediate neighbors — because any site more than one cell away is farther than the nearest corner site. This is the standard Worley/Voronoi construction.

## 18.2 Distance to the nearest site and its gradient

For nearest site $\mathbf c_i$,

$$
d_i=\lVert\mathbf p-\mathbf c_i\rVert.
$$

The field $d_{\min}(\mathbf p)=\min_i d_i$ is the **distance to the nearest site**. Its zero set is the sites themselves; it's a distance *to a set of points*, and it is piecewise smooth, non-differentiable along the **Voronoi edges/equidistant loci** (the boundaries between cells), which is like a medial axis (Chapter 06). These non-differentiable boundaries are exactly the "cell borders."

**Gradient.** Inside a cell, the gradient of $d_{\min}$ is the unit vector from the site to $\mathbf p$: $\nabla d_{\min}=(\mathbf p-\mathbf c_i)/\lVert\mathbf p-\mathbf c_i\rVert$, which is 1-Lipschitz. Across a cell boundary it jumps.

## 18.3 The Voronoi distance field and its uses

**Procedural cracks.** The **second-nearest** site gives the second distance $d_2$. The quantity $d_2-d_1$ is the distance from $\mathbf p$ to the cell *boundary* (the equidistant set). Where $d_2-d_1$ is small, $\mathbf p$ is near a boundary. This gives the classic "crack" pattern:

$$
\text{crack intensity}=\text{clamp}\big(d_2-d_1,\ 0,\ k\big)
$$

with $k$ the crack width. So Voronoi produces crack/vein patterns by taking the difference of the two nearest distances.

**Biological / cellular patterns.** Scaling and warping the nearest-site distance produces cell-like structures: `f(d1)` where `f` is a smooth bell, or `d1` combined with a noise to make cells appear organic. Used for snake skin, scales, animal cells, coral, and foam.

**Cellular materials.** By coloring/compositing a material per cell (using the hash of the nearest site), Voronoi creates "tile" or "cellular" materials for game textures and procedural rock/floor.

## 18.4 Voronoi as a surface (raymarchable)

To raymarch a Voronoi *surface* (rather than a texture), treat a function of the Voronoi distances as an implicit field. For example, the "cellular wall" surface

$$
f(\mathbf p)=d_{2}-d_{1}-k
$$

has zero set at the cell boundaries, offset outward by $k$; it forms a network of walls — the cellular "cracked slab." Since $d_2-d_1$ is piecewise 1-Lipschitz (both are 1-Lipschitz, and their difference is Lipschitz with constant $\le2$), this is a **bound**. In general, Voronoi-based implicit surfaces are **bounds/estimators**, which is fine for marching as long as we account for the Lipschitz constant.

## 18.5 Voronoi distance, F2-F1 and "edge" fields

The family of derived scalar fields:

| Field | Formula | Visual |
|-------|---------|--------|
| Nearest distance | $d_1$ | Cell interiors, distance to sites |
| Second distance | $d_2$ | Cell borders via $d_2-d_1$ |
| Cell ID / color | hash of nearest site | Colored cells |
| Edge field | $d_2-d_1$ | Cracks, veins, borders |
| Voronoi "noise" | $d_1$ or combinations | Organic bumps |

## 18.6 Procedural architecture from Voronoi

Voronoi is also the origin of *cell-based architecture*: partitioning a floor plan into cells and placing a room/structure per cell. Because the site hash can drive the material, size, and orientation, a single Voronoi field generates a "procedural city" or a "crystal cluster." Combined with repetition (Chapter 11), it produces large structured environments from a few operations.

## 18.7 Variants

- **Worley noise.** Another name for the Voronoi nearest-distance noise; often combined with FBM.
- **Anisotropic Voronoi.** Scale the distance metric to stretch cells.
- **Warped Voronoi.** Apply domain warping (Chapter 16) to the *input* coordinates before the Voronoi, giving organic, flowing cells (the classic "biological" look).
- **Voronoi with relief.** Displace cell interiors by a function of distance (e.g. a smooth bump `sin(d1*k)*...`), producing convex cell "domes."

## 18.8 Cost and field class

The Voronoi lookup examines a constant number of cells (9 in 2D, 27 in 3D), each requiring a hash and a distance. It's moderately expensive but is one of the most flexible procedural texture/surface generators. Its distance fields are **bounds**, because the min of 1-Lipschitz functions is 1-Lipschitz (for the nearest-distance field), but derived fields like $d_2-d_1$ have Lipschitz constant up to 2. We scale steps accordingly.

## Exercises

1. **(Derivation)** Show that the nearest site for a point lies in the lattice cell containing it or a neighbor cell; hence the 3×3 (2D) search.
2. **(Derivation)** Derive the gradient of the nearest-distance field and show it's 1-Lipschitz inside a cell.
3. **(Geometric)** Explain why $d_2-d_1$ measures distance to the cell boundary and is zero on it.
4. **(Implementation)** Implement 2D Voronoi (crack pattern) with a hash.
5. **(Design)** Build a raymarchable "cracked slab" surface using $d_2-d_1-k$; identify its field class and the safe-step scale factor.
6. **(Design)** Warp the Voronoi input to produce organic flowing cells; describe the visual change.
7. **(Reverse engineering)** Given a shader that subtracts two `length` values of neighboring cells, identify it as Voronoi and describe the $F_2-F_1$ structure.
