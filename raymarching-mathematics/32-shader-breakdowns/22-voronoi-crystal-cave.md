# Shader Breakdown 22 — Voronoi Crystal Cave / Cell Lattice

A "crystal cave" or "faceted rock" is a **Voronoi cell lattice** rendered as a raymarchable surface. The cells become faceted crystals; the classic construction combines a Voronoi *surface* (the cell borders) with a displacement and a refractive/glassy material. This breakdown derives the Voronoi surface and its field class.

## 1. The fragment (reconstructed key parts)

```glsl
// Voronoi "distance" where we search neighbors and track the nearest two
float voronoiCrack(vec3 p){
    vec3 ip = floor(p); vec3 fp = fract(p);
    float f1 = 1e9, f2 = 1e9;
    for(int x=-1;x<=1;x++)for(int y=-1;y<=1;y++)for(int z=-1;z<=1;z++){
        vec3 g = ip + vec3(x,y,z) + hash3(ip+vec3(x,y,z));   // site in cell
        float d = length( fp - (g-ip) );                 // distance from p to site
        if(d<f1){ f2=f1; f1=d; } else if(d<f2){ f2=d; }
    }
    return f2 - f1;          // distance to the cell border
}

float map(vec3 p){
    float crack = voronoiCrack(p);                 // near cell borders
    float d = 0.2 + crack;                        // a wall at the border
    // optional: inward-displaced cell interior for crystal facets
    return d;
}
```

## 2. Mathematics

### 2.1 The Voronoi surface (the cell borders)

The Voronoi diagram (Chapter 18) partitions space into cells around sites $\mathbf c_i$. The **distance to the cell border** is
$$
c(\mathbf p)=F_2(\mathbf p)-F_1(\mathbf p),
$$
where $F_1$ is the distance to the nearest site and $F_2$ to the second-nearest. Where $F_2=F_1$ (a border), $c=0$; inside a cell, $c>0$.

A **surface** at the cell borders is the zero (or small) set of $c$. To make a *solid* cell wall, offset it:
$$
d_{\text{wall}}(\mathbf p)=c(\mathbf p)-r_w,
$$
so the wall is a shell of half-width $r_w$ around each border.

### 2.2 The "crystal facet" displacement

To get the faceted look, displace the interior of each cell (a crystal face) rather than leaving it flat. A common trick: offset the *site* distance to model the planar facets. Because each site defines a cone/sphere of equal distance, the cell interior surface is a set of soft "caps." For truly flat facets, use the **half-plane** distance to each cell cell's nearest-side plane rather than the pure $F_2-F_1$ (which is rounder).

### 2.3 The field class

$F_1$ is 1-Lipschitz (distance to a set of points). $F_2-F_1$ has Lipschitz constant up to 2. So the wall field $c-r_w$ is a **bound** (Lipschitz ≤ 2), not exact. To use it safely as a march step, scale by $1/2$:
$$
d_{\text{safe}}=\frac{c-r_w}{2}.
$$
This is exactly the Chapter 31a "certify the Lipschitz constant and adjust the step" prescription. Many shaders skip this and use the raw $c$ (fast, but it slightly overestimates and can tunnel through thin cell walls). Recognizing this is the important field-class lesson.

## 3. The "thinking process"

1. **Ideas.** "I want a faceted, crystalline/cell structure." → Voronoi cells.
2. **Borders.** "The surface is the cell border." → $F_2-F_1$.
3. **Surface.** "Offset the border into a wall." → $c-r_w$.
4. **Facets.** "Make each interior a flat crystal face." → offset by the nearest-site cone or use half-planes.
5. **Safety.** "The border field is Lipschitz ≤ 2." → halve the step (or accept the whole in the aesthetic).

## 4. Field class

| Quantity | Class |
|----------|-------|
| F1 | distance to points, 1-Lipschitz |
| F2−F1 | distance to border, Lipschitz ≤ 2 |
| wall $c-r_w$ | **bound** (scale by 1/2 for exact safety) |
| facet displacement | bound/estimator |

## 5. Extensions

- **Crystal material.** Refract (Chapter 15) through the cells; color by the facet normal and depth (thickness), for the glassy crystal look.
- **Interior glow / transmission.** A fake SSS (Chapter 13) by measuring the ray path through the volume.
- **Twisted Voronoi.** Warp the input with a twist (Chapter 10) so the cells spiral.
- **Warped crystal.** Domain-warp the Voronoi input (Chapter 16) for organic crystal clusters.
- **Faceted interiors.** Replace $F_2-F_1$ with the *nearest-site distance capped* for flat facets (the "crystal" variant).

## Exercises

1. **(Derivation)** Show $F_2-F_1$ is (a scaled) distance to the cell border and has Lipschitz constant ≤ 2.
2. **(Field class)** Classify the Voronoi wall field and state the safe-step factor.
3. **(Derivation)** Derive the nearest-site "cone" distance and how it produces facets.
4. **(Analytic)** Explain why a raw $c$ (not halved) can tunnel through thin cell walls.
5. **(Design)** Build a crystal material with refraction and a frozen SSS.
6. **(Implementation)** Render a Voronoi crystal cave.
