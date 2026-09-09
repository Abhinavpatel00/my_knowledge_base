# Shader Breakdown 14 — Worley/Voronoi Cellular Noise (F1, F2, and F2−F1)

Worley (cellular) noise is one of the most-used procedural-primitive building blocks. It captures the "nearest site" geometry of Voronoi diagrams (Chapter 18) and produces the cracked/veined/cellular textures ubiquitous in procedural graphics. Here we derive the standard Worley form, the F2−F1 crack field, its gradient, and its field class.

## 1. The fragment (reconstructed key parts)

```glsl
float hash(vec3 p){ return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }

vec2 worley(vec3 p){
    vec3 ip = floor(p), fp = fract(p);
    float f1 = 1e9, f2 = 1e9;
    for(int x=-1;x<=1;x++)
    for(int y=-1;y<=1;y++)
    for(int z=-1;z<=1;z++){
        vec3 g = vec3(x,y,z)                               // cell neighbor offset
               + vec3(hash(ip+vec3(x,y,z)),
                      hash(ip+vec3(x,y,z)+...),
                      hash(ip+vec3(x,y,z)+...));           // random site in cell
        vec3 o = fp - g;
        float d = dot(o,o);
        if(d < f1){ f2 = f1; f1 = d; }
        else if(d < f2){ f2 = d; }
    }
    return vec2(sqrt(f1), sqrt(f2));   // (F1, F2)
}
```

## 2. Mathematics

### 2.1 The lattice and the random sites

Space is partitioned into unit cells indexed by $\mathbf i=\lfloor\mathbf p\rfloor$. Within each cell, a **site** is placed at
$$
\mathbf c_{\mathbf i}=\mathbf i+\mathbf k_{\mathbf i},
$$
where $\mathbf k_{\mathbf i}\in[0,1)^3$ is a per-cell random jitter from a hash. For the query point $\mathbf p$ (fractional part $\mathbf f=\mathbf p-\mathbf i$), the nearest site lies in the cell containing $\mathbf p$ or one of its 26 neighbors (Chapter 18: only a constant number need be searched).

### 2.2 F1 and F2

For each candidate site, compute the squared Euclidean distance
$$
d_{\mathbf i}=\lVert\mathbf f-\mathbf k_{\mathbf i}\rVert^2.
$$
Track the two smallest:
$$
F_1=\min_{\mathbf i}d_{\mathbf i},\qquad F_2=\text{second-min}_{\mathbf i}d_{\mathbf i}.
$$
F1 is the distance to the nearest site; F2 is the distance to the second-nearest. The `f1=d` and `f2` bookkeeping is a two-pass selection of the two smallest distances. The `sqrt`s return the actual distances. 

**Interpretation of F1.** F1 is the distance from $\mathbf p$ to the nearest site — i.e. the **distance to the "centroids" of the cells.** The set $F_1=\text{const}$ are circles around each site; the union of these circles generates the "blobby cell" look.

### 2.3 The F2−F1 crack field

The key derived field is
$$
c(\mathbf p)=F_2-F_1.
$$
**Derivation.** The boundary of a Voronoi cell is the set of points equidistant to two sites, i.e. where $F_2=F_1$, i.e. $c=0$. As $\mathbf p$ moves away from a boundary, $c$ grows. So $c$ is approximately **distance to the nearest cell boundary.** When $c$ is small, we're near a cell border; when $c$ is large, we're in a cell interior.

This produces **cracks/veins**: the set where $c$ is below a threshold is the set of all cell borders, drawn as lines/planes. This is exactly the "cracked" or "terrain ridge" pattern.

### 2.4 The gradient and its field class

For a fixed site $\mathbf c$, $\nabla d_{\mathbf i}=2(\mathbf p-\mathbf c)$. So $\nabla F_1$ is well-defined away from the equidistant loci (the cell borders), and it points from the nearest site toward $\mathbf p$. Across a cell border, $\nabla F_1$ jumps (the nearest site switches). Thus F1 is a **piecewise smooth** function, differentiable except on the Voronoi edges (the "medial axis" of the site set — Chapter 6).

**Field class.** F1 is a **distance to a set of points** — it is 1-Lipschitz (the min of 1-Lipschitz functions is 1-Lipschitz, Chapter 9/18). But the *derived* field $F_2-F_1$ has Lipschitz constant up to 2. So:
- F1 alone is a valid **distance bound** to the sites (safe to march as a step, if you wanted the sites' offsets).
- $F_2-F_1$ is a **crack/edge** field — its Lipschitz constant is 2, so it must be scaled if used as a step.

## 3. The visual uses

| Use | Field | Effect |
|-----|-------|--------|
| Blobs | `F1` | Rounded cells / spots |
| Cracks/veins | `F2-F1` | Cell borders as lines |
| Cell ID | hash of nearest site | Colored cells |
| Smooth cells | `smoothstep` of F1 | Soft blobs |
| Warped cells | warp input before Worley | Organic, flowing cells |

## 4. The "thinking process"

1. **Ideas.** "I want cell-like, cracked, organic structure." → Voronoi.
2. **Sites.** "Place random points per lattice cell." → hash a jitter per cell.
3. **Distances.** "Find the nearest (F1) and second-nearest (F2)." → 27-cell neighbourhood, track two minimums.
4. **Geometry.** "The borders are where F2=F1." → use $F_2-F_1$ as an edge field.
5. **Organic.** "Make the cells flow." → warp the input domain (Chapter 16/18).

## 5. Extensions

- **Isotropic warping.** Feed the Worley input through an FBM (Chapter 16) — the classic "organic cells."
- **Voronoi SDF.** Treat a chosen threshold of `F1` as a surface: `F1 - r` is a distance to a "spherical cap" around each site (a union of spheres). By setting the threshold you get the "bumpy" Voronoi material.
- **Fractal/cellular Voronoi.** Sum Worley at several octaves (like fBm) for "lumpy" detail.
- **Cracks as a surface.** Render `abs(c - k)` — the thin border shells — as solid geometry.
- **Anisotropic cell shape.** Scale the distance metric to stretch the cells.

## Exercises

1. **(Derivation)** Derive F1 and F2 and the two-pass selection; justify the 27-cell search.
2. **(Derivation)** Show $\nabla F_1=2(\mathbf p-\mathbf c)$ and identify where it jumps.
3. **(Derivation)** Show $F_2-F_1$ is a (scaled) distance to the cell border and has Lipschitz constant 2.
4. **(Field class)** Classify F1 (distance bound to sites) and F2−F1 (edge field).
5. **(Analytic)** Explain why warping the input makes the cells organic.
6. **(Implementation)** Implement 2D/3D Worley and produce the crack pattern.
