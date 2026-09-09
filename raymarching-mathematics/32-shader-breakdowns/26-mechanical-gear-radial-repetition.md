# Shader Breakdown 26 — Mechanical Gears: Radial Repetition + CSG

Mechanical / engineering forms (gears, cogs, rotors) are built from **radial repetition** (Chapter 11) plus **CSG booleans** (Chapter 9). A gear is the canonical example: a disc with teeth, carved for the tooth gaps. This is an exercise in isometries (rotation), radial folding (Chapter 11.5), and exact booleans.

## 1. The fragment (reconstructed key parts)

```glsl
float sdGear(vec3 p){
    p = abs(p);                                    // mirror symmetric (optional)
    // 1) the disc (in the plane perpendicular to the axis)
    float disc = length(p.xz) - R;                 // a cylinder / disc radius R
    // 2) carve tooth gaps by radial repetition
    float a = atan(p.z, p.x);                      // azimuth
    float n = 12.0, width = 0.2;
    a = mod(a + PI/n, 2.*PI/n) - PI/n;             // fold into n sectors
    float r = length(p.xz);
    p.xz = vec2(cos(a), sin(a)) * r;               // rebuild at folded angle
    float teeth = ...;                             // the tooth shape
    float t = max(teeth, ...);                     // union tooth with disc
    // subtract the tooth gaps:
    float gap = ...;
    return max(t, -gap);                           // difference
    // + a hole in the center
    return max(d, -sdCylinder(p, ax, r_hole));
}
```

## 2. Mathematics

### 2.1 The radial fold

The azimuth is $\theta=\operatorname{atan2}(p_z,p_x)$, and folding it into $n$ sectors writes it as
$$
\theta'=\operatorname{mod}\!\Big(\theta+\tfrac{\pi}{n},\ \tfrac{2\pi}{n}\Big)-\tfrac{\pi}{n}.
$$
Rebuilding the point at $\theta'$ with the same radius $r$ gives the $n$-fold symmetric arm. Because the azimuth rotation and the fold are isometries, this is **exact-SDF-preserving**. The number $n$ is the gear's tooth count. One "tooth" in the fundamental sector becomes $n$ teeth.

### 2.2 The disc and the teeth (CSG)

The disc is $\operatorname{length}(p.xz)-R$ (a cylinder radius $R$). The tooth is a second shape (a box/capsule) in one sector. The union $t=\max(d_{\text{disc}},d_{\text{tooth}})$, then the tooth gaps are carved by **difference** $d=\max(t,-d_{\text{gap}})$. All of these are exact SDF booleans (Chapter 9) because the inputs are exact. The center hole is a difference with a cylinder. So the gear is a **union/intersection/difference** of exact primitives — an **exact SDF** (piecewise).

### 2.3 The gear's exactness

| Stage | Operation | Isometry? | Field class |
|-------|-----------|-----------|-------------|
| radial fold | `mod` of azimuth | yes | exact |
| disc/box/capsule | primitives | — | exact |
| union/intersection | `max`/`min` | — | exact |
| difference (hole) | `max(d,-hole)` | — | exact |

So a gear is an **exact SDF**, much like the city (Breakdown 20) — it's isometries + exact primitives + exact booleans. This is why mechanical objects render crisply and can be combined with other exact forms.

## 3. The "thinking process"

1. **Ideas.** "I want a gear." → a disc with teeth.
2. **Disc.** "The main body." → a cylinder SDF.
3. **Teeth.** "n teeth around it." → radial repetition into $n$ sectors.
4. **Carve.** "Cut the gaps and the hub hole." → CSG differences.
5. **Rotation.** "Spin it over time." → rotate the frame (isometry).

## 4. Extensions

- **Angular teeth profile.** Instead of a square tooth, use a rounded/capsule tooth (a "melted" gear), or a tapered tooth (a cone/capsule) for a "helical gear."
- **Mesh / involute profile.** A proper gear has an **involute** tooth profile; this is more complex but gives the correct mechanical conjugate action. Approximate with circles/boxes first.
- **Multiple gears.** Combine several gears that mesh — an important detail is the tooth spacing must match so they interlock (the radial repetition $n$ and tooth width must satisfy a relation).
- **Anisotropic scale.** Scale the gear's thickness (a non-uniform scale → bound).
- **Material.** Metals with anisotropic specular (anisotropic GGX) and a PBR BRDF (Chapter 13).

## Exercises

1. **(Derivation)** Derive the radial fold into $n$ sectors and verify it preserves radius.
2. **(Field class)** Show the gear is an exact SDF (isometries + exact primitives + exact booleans).
3. **(Derivation)** Derive the tooth-as-a-capsule or box primitive.
4. **(Analytic)** Explain why a proper involute profile is harder, and how to approximate it.
5. **(Design)** Build two meshing gears; describe the tooth-count/sizing constraint.
6. **(Implementation)** Render a rotating gear with a metal PBR material.
