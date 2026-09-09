# Chapter 28 — Complete Projects

Each project is a full application of the book's pipeline. For every one, we go from artistic target through mathematical model, field, marcher, lighting, material, animation, optimization, to a final shader — then a mathematical post-mortem. These increase in difficulty.

---

## Project 1 — Sphere Tracer

**Artistic target.** Render a shaded sphere.

**Geometric decomposition.** One sphere at the origin.

**Mathematical model.** Ray $\mathbf r(t)=\mathbf o+t\mathbf d$, $d(\mathbf p)=\lVert\mathbf p\rVert-r$.

**Distance field.** $d=\operatorname{length}(\mathbf p)-r$ (exact SDF).

**Ray marcher.** Sphere-trace: advance by $d$ until $d<\varepsilon$ or $t>T_{\max}$.

**Lighting.** Lambert + a simple ambient.

**Final shader.**

```glsl
void mainImage(out vec4 o, in vec2 f){
    vec2 uv = (2.*f-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.,0.,-3.), rd=normalize(vec3(uv,1.));
    float t=0.;
    for(int i=0;i<200;i++){
        float d=length(ro+rd*t)-1.;
        if(d<1e-3) break; t+=d; if(t>10.) break;
    }
    vec3 p=ro+rd*t;
    vec3 n=normalize(p);
    vec3 l=normalize(vec3(.5,.6,.6));
    float dif=max(dot(n,l),0.);
    vec3 col=vec3(.1)+vec3(1.,.6,.3)*dif;
    o=vec4(col*exp(-t*.2),1.); // simple depth fade
}
```

**Post-mortem.** The sphere's gradient is $\hat{\mathbf p}$, so the normal is exact. The field is a true SDF → safe, 1-Lipschitz. The `exp(-t*.2)` is a fake aerial perspective (fog), a deliberate approximation. The normal via `normalize(p)` is exact and cheap (no finite differences).

---

## Project 2 — Primitive Scene

**Target.** A small scene of a few primitives (sphere, box, torus).

**Decomposition.** Union of a sphere, a box, and a torus.

**Model.** $d=\min(\text{sphere},\text{box},\text{torus})$.

**Field.**

```glsl
float map(vec3 p){
    float d = sdSphere(p,1.);
    d = min(d, sdBox(p-vec3(2.,0.5,0.),vec3(1.)));
    d = min(d, sdTorus(p-vec3(0.,2.,0.),1.5,.4));
    return d;
}
```

**Post-mortem.** The `min` union is an exact SDF of the union (Chapter 09). The seams are $\mathcal C^0$; normals are computed with central differences. The torus is exact. This is the baseline scene.

---

## Project 3 — Boolean Sculpture

**Target.** A sculpture from CSG booleans and smooth union.

**Decomposition.** Smooth-union of a few spheres, subtract a capsule (difference).

**Model.** $d=\operatorname{smax}(d_A,d_B)-\text{...}$, difference via `max`.

**Field.**

```glsl
float map(vec3 p){
    float a = sdSphere(p,1.2);
    float b = sdSphere(p-vec3(1.,1.,0.),.8);
    float u = smin(a,b,.3);
    float d = sdCapsule(p-vec3(0.,0.,1.),vec3(0.,-.5,0.),vec3(0.,1.,0.),.3);
    return max(d, -u);      // subtract the capsule from the union
}
```

**Post-mortem.** The smooth union is a **bound** (Chapter 09), not exact; the `min`/difference is exact when inputs are exact. The `max(u, -capsule)` is the difference $u\setminus\text{capsule}$. The field is safe (bound), and the smooth union gives $\mathcal C^1$ normals — a "melted" sculpture.

---

## Project 4 — Infinite Tunnel

**Target.** A corridor the camera flies through.

**Decomposition.** Repeat a box/cylinder; center it as a tunnel.

**Model.** Repetition + cylinder.

**Field.**

```glsl
float map(vec3 p){
    p = mod(p+3.,6.)-3.;     // repeat along all axes
    float d = sdCylinder(p, 1.0);  // a tube = tunnel wall
    return d;
}
```

**Post-mortem.** `mod` is centered repetition (Chapter 11), exact SDF along each axis. The cylinder is exact. The result is an infinite lattice of tubes, seen from inside as a corridor. Because the field is exact, the marcher is safe; the aesthetic comes from flying along the repeated structure.

---

## Project 5 — Procedural Crystal

**Target.** A faceted crystal.

**Decomposition.** An octahedron (or box) with a lathe/cut pattern, plus a colored interior.

**Model.** Crystal = a convex polyhedron (octahedron) with a radial modulation.

**Field.**

```glsl
float map(vec3 p){
    p = abs(p);
    p.y = mod(p.y+2.,4.)-2.;    // axial repetition for crystal column
    float d = sdOctahedron(p, 1.2);
    d = sdBox(p, vec3(1.0));    // crystal cross-section
    float t = 0.5 + 0.5*sin(6.*atan(p.x,p.z)); // facets
    d += 0.05*t;                 // slight facet displacement
    return d;
}
```

**Post-mortem.** The `abs` is a mirror fold (isometry). The radial modulation `sin(6*atan(...))` adds facets. The displacement `0.05*t` makes the field a **bound** (not exact); the amplitude is small so it's safe. Coloring: a star-ish palette + Fresnel for the glassy skin.

---

## Project 6 — Organic Creature

**Target.** A wobbly, blobby organic form.

**Decomposition.** Smooth-union of several spheres (a blob), displaced by FBM.

**Model.** $d=\operatorname{smin}(\ldots,\text{blobs})+\text{fbm displacement}$.

**Field.**

```glsl
float map(vec3 p){
    float d = sdSphere(p,1.);
    d = smin(d, sdSphere(p-vec3(1.,.2,0.),.6), .5);
    d = smin(d, sdSphere(p+vec3(-1.,.3,.2),.5), .5);
    d += 0.08*fbm(p*2.);
    return d;
}
```

**Post-mortem.** Smooth union is a bound; FBM displacement makes it an estimator. The small amplitude keeps it safe. The visual is a meaty, organic blob. Normals from finite differences.

---

## Project 7 — Mechanical Environment

**Target.** A mechanical machine room.

**Decomposition.** Repeated gears, pistons, pipes; a torus/cylinder/box menagerie.

**Model.** Union/intersection of many primitives with repetition.

**Field.** A `map` that layers repeated cylinders (pipes), torus gears, boxes (pistons), all combined with `min` and repetition.

**Post-mortem.** Each primitive is exact; the union is exact; repetition is exact. The scene is a large but *exact* SDF — safe, and the "machine" look is from the crisp edges (which need exact booleans rather than smooth ones). Animation rotates the gears via `rotation` (isometry, exact).

---

## Project 8 — Fractal Object

**Target.** A Mandelbulb.

**Model.** Iterate $\mathbf z\mapsto\mathbf z^8+\mathbf c$ with a running derivative and the DE.

**Field.** The Mandelbulb DE (Chapter 19/20).

```glsl
float map(vec3 p){
    vec3 z=p; float dr=1.; float r=0.;
    for(int i=0;i<8;i++){
        r=length(z);
        float inv=max(r,1e-6);
        float th=acos(clamp(z.z/inv,-1.,1.));
        float ph=atan(z.y,z.x);
        float zr=pow(r,8.);
        th=8.*th; ph=8.*ph;
        z=zr*vec3(sin(th)*cos(ph),sin(th)*sin(ph),cos(th))+p;
        dr=8.*pow(r,7.)*dr+1.;
    }
    return .5*log(max(length(z),1e-6))*length(z)/dr;
}
```

**Post-mortem.** The field is a **distance estimator** — conservative via the $0.5$ factor, safe but approximate. Color via smooth iteration count and an orbit trap. This is the deepest use of the whole book.

---

## Project 9 — Volumetric Cloud

**Target.** A soft cloud/smoke volume.

**Model.** A density field from FBM, rendered by volumetric ray marching (Chapter 21).

**Field.** `density(p) = fbm(p)`; render via a fixed-step integral with light-scatter.

```glsl
// inside main: march the ray, accumulate emission/absorption using density().
```

**Post-mortem.** The density is a scalar field (not a distance); we use fixed steps, not a safe-step. Light marching gives the in-scatter. This is a true *volumetric* render, distinct from a soft SDF.

---

## Project 10 — Reflective/Refractive Object

**Target.** Glass / mirror sphere.

**Model.** Fresnel-mixed reflection and refraction; TIR handling.

**Field.** A sphere SDF; on hit, compute `reflect` and `refract` and trace each with a limited bounce.

**Post-mortem.** The reflection/refraction vectors (Chapter 15) are derived. The bounce rays are traced with the sphere-tracer starting just off the surface (bias). This is a *recursive* raymarch (bounded depth), so cost multiplies per bounce — budget it.

---

## Project 11 — Complex Procedural World

**Target.** A tiled landscape with objects, atmosphere.

**Model.** A height field or a repeated/volumetric environment with multiple systems.

**Post-mortem.** Combining repetition, booleans, displacement, and fog. This is where the taxonomy matters: repetition (exact), displacement (bound), fog (volumetric). Performance requires bounding/early-exit (Chapter 25).

---

## Project 12 — High-Quality Abstract ShaderToy Artwork

**Target.** A polished abstract piece with soft shadows, AO, Fresnel, and a strong material.

**Model.** A base SDF, deformed by noise, rendered with Lambert+GGX+Fresnel+soft shadows+AO, animated.

**Post-mortem.** Every stage is a known mathematical object; the quality comes from *careful* choice of field, lighting, and color. This is the "gold standard" the whole book builds toward.

---

## Exercises

1. **(Implementation)** Build each project; for each, identify the field class and any approximations.
2. **(Derivation)** For Project 8, derive the DE from the running derivative.
3. **(Design)** Combine Project 5 (crystal) and Project 8 (fractal) to make a fractal crystal; describe the math.
4. **(Optimization)** For Project 11, add a bounding volume and explain the cost saving.
5. **(Reverse engineer)** From the Project 1 shader, identify all the "hacks" (fake fog, normal-color, etc.).
6. **(Post-mortem)** For each project, list the exact-SDF/ bound/ estimator components and justify each.
