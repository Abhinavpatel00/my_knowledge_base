# Chapter 13 — Lighting

Lighting is not a recipe of GLSL `mix` calls; it is the evaluation of a **radiance integral**. This chapter derives the standard light-transport models and relates them to raymarched surfaces. We start from the geometric meaning of the dot product and build outward.

## 13.1 The geometry of the dot product in lighting

Consider a surface with unit normal $\mathbf n$ and a light arriving along unit direction $\mathbf l$ (pointing *toward* the light). The **irradiance** on the surface is the product of the light's intensity and the **cosine of the incidence angle**:

$$
\cos\theta=\mathbf n\cdot\mathbf l .
$$

**Why the cosine factor.** The surface intercepts light along its *cross-section*, which is foreshortened by $\cos\theta$: a beam of unit cross-section, incident at angle $\theta$, spreads over a surface area $1/\cos\theta$, so the flux per unit area scales by $\cos\theta$. Hence

$$
L_d\propto\max(0,\mathbf n\cdot\mathbf l).
$$

This is the **Lambert** law, and it is the direct geometric consequence of the dot product.

**The $\max(0,\cdot)$ is essential.** When $\mathbf n\cdot\mathbf l<0$ the light is *behind* the surface and contributes nothing; simply multiplying without the clamp would produce negative light (wrong) and, worse, would let back-face light illuminate the front.

## 13.2 Lambertian (diffuse) reflection

A **Lambertian** surface reflects light equally in all directions (it is an ideal diffuse reflector). The outgoing radiance for a diffuse surface with albedo $\rho$ is

$$
L_o=\frac{\rho}{\pi}\int_{\Omega^+} L_i(\mathbf l)\cos\theta\,d\omega .
$$

For a single directional light of intensity $I$, this integral yields

$$
L_d=\rho\,I\,\max(0,\mathbf n\cdot\mathbf l).
$$

The $1/\pi$ is the normalization of the hemisphere integral; when we fold it into the "intensity," shaders write `albedo * normalize(ndotl)`.

**Interpretation.** The diffuse term is the direct consequence of energy conservation over the hemisphere, modulated by the cos-law. It is a *pointwise* evaluation of the irradiance integral under a single light and a uniform BRDF.

## 13.3 Specular reflection: the reflection vector

A specular reflection mirrors the direction of incidence about the normal. The **reflection vector** is

$$
\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n .
$$

**Derivation.** Decompose $\mathbf d$ into its component along $\mathbf n$, $(\mathbf d\cdot\mathbf n)\mathbf n$, and its tangential component, $\mathbf d-(\mathbf d\cdot\mathbf n)\mathbf n$. Reflecting around $\mathbf n$ negates the normal component and keeps the tangential component:

$$
\mathbf r=(\mathbf d-(\mathbf d\cdot\mathbf n)\mathbf n)-(\mathbf d\cdot\mathbf n)\mathbf n=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n .
$$

This is derived (not assumed) in Chapter 15. In lighting terms, the viewer direction $\mathbf v$ (pointing from surface to camera) and the incident (view) direction $\mathbf d=-\mathbf v$; the specular reflection is $\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n$.

## 13.4 Blinn-Phong: the half vector

The **half vector** is the normalized bisector of the light and view directions:

$$
\mathbf h=\frac{\mathbf l+\mathbf v}{\lVert\mathbf l+\mathbf v\rVert}.
$$

**Why it's useful.** The specular reflection is strongest when the reflection vector $\mathbf r$ aligns with the view direction $\mathbf v$. Equivalently, it is strongest when the half vector $\mathbf h$ aligns with the normal $\mathbf n$. Using the half vector is cheaper and numerically better because it avoids computing $\mathbf r$ from a potentially non-normalized incident direction, and it is symmetric in $\mathbf l,\mathbf v$.

**Blinn-Phong** specular:

$$
L_s=I_s\,k_s\,\big(\max(0,\mathbf n\cdot\mathbf h)\big)^{m},
$$

where $m$ is the **shininess/exponent** controlling highlight tightness (larger $m$ → tighter, brighter highlight).

**Phong** uses $\mathbf r$ directly:

$$
L_s=I_s\,k_s\,\big(\max(0,\mathbf r\cdot\mathbf v)\big)^{m}.
$$

Blinn-Phong is generally preferred because it doesn't degrade on grazing angles and is cheaper.

## 13.5 The microfacet model

Real surfaces are rough at a micro scale. A **microfacet BRDF** models reflection as happening on a distribution of tiny facets, each reflecting specularly. The general form (Cook–Torrance) is

$$
f_r(\mathbf l,\mathbf v)=\frac{D(\mathbf h)\,G(\mathbf l,\mathbf v)\,F(\mathbf v,\mathbf h)}
{4(\mathbf n\cdot\mathbf l)(\mathbf n\cdot\mathbf v)} .
$$

**The three factors:**

- **$D$ (normal distribution function)** — the probability density of microfacets oriented along $\mathbf h$.
- **$G$ (geometric attenuation / shadowing-masking)** — the fraction of microfacets not occluded by neighbors (self-shadowing and self-masking).
- **$F$ (Fresnel)** — the reflectance as a function of angle, from Chapter 15.

**Why the denominator has $4(\mathbf n\cdot\mathbf l)(\mathbf n\cdot\mathbf v)$.** It converts between the micofacet space and the macro surface space, and it cancels the $1/(\mathbf n\cdot\mathbf l)$ from the irradiance transfer.

**Intuition.** A smooth surface has a very sharp $D$ (all microfacets aligned) → a sharp, mirror-like highlight. A rough surface has a broad $D$ → a broad, dimmer highlight. $D$ is the source of the *shape* of the highlight; $G$ and $F$ modulate its intensity, especially at grazing angles.

## 13.6 GGX (the modern standard)

The **GGX / Trowbridge-Reitz** normal distribution is

$$
D(\mathbf h)=\frac{\alpha^2}{\pi\big((\mathbf n\cdot\mathbf h)^2(\alpha^2-1)+1\big)^2},
$$

where $\alpha$ is the **roughness** (small $\alpha$ = smooth). GGX has a well-known property: it has a longer "tail" than Blinn-Phong, producing a more realistic falloff with distinctive grazing highlights. This is why it is the standard in physically based rendering.

**Roughness mapping.** GGX's $\alpha$ is typically $\alpha=\text{roughness}^2$ (for perceptual roughness), and the exponent relationship to Blinn-Phong's $m$ is $\alpha^2=2/(m+2)$ or similar — we note this so a reader can convert between the two.

## 13.7 Fresnel and the Schlick approximation

**Fresnel** describes how reflectance depends on angle. At normal incidence the reflectance is $F_0$; as the incidence angle increases toward grazing, the reflectance rises toward 1. The **Schlick approximation** is

$$
F(\theta)=F_0+\big(1-F_0\big)(1-\cos\theta)^{5},
$$

where $\cos\theta=\mathbf n\cdot\mathbf v$ (or $\mathbf v\cdot\mathbf h$).

**Why the $(1-\cos\theta)^5$.** The exact Fresnel equations are a complicated function of refractive indices; the $5$th power is a fitted exponent that captures the rapid rise near grazing while matching the exact curve well for dielectric/conductor cases across most angles. It is an **approximation** — labeled as such — and it's what makes grazing surfaces "iluminat" at the rim (the characteristic bright edge).

**Relevance for raymarched surfaces.** Since raymarched surfaces are pure implicit geometry, the Fresnel/Schlick term gives the "rim light" and the correct behavior at grazing angles, which is essential for the "crystal/liquid/glass" look and for the metallic-material aesthetic.

## 13.8 Geometric attenuation

The **Smith** geometric-attenuation term accounts for micro-surface self-shadowing. A commonly used form is

$$
G(\mathbf l,\mathbf v)=\frac{2(\mathbf n\cdot\mathbf l)(\mathbf n\cdot\mathbf v)}
{(\mathbf n\cdot\mathbf l)+(\mathbf n\cdot\mathbf v)}
$$

(or its height-correlated GGX variants). $G$ suppresses the highlight at grazing angles where many microfacets are shadowed by neighbors.

## 13.9 Assembling the model

A complete (local) lighting model combines diffuse and specular:

$$
L_o=\underbrace{\rho_d\,\max(0,\mathbf n\cdot\mathbf l)}_{\text{diffuse}}
+\underbrace{\frac{D(\mathbf h)\,G\,F}{4(\mathbf n\cdot\mathbf l)(\mathbf n\cdot\mathbf v)}\,I}_{\text{specular (microfacet)}}
+\underbrace{k_a\,L_{\text{ambient}}}_{\text{ambient}}
$$

plus (in raymarching): **shadows** (hard/soft, Chapter 14), **ambient occlusion** (Chapter 14), **reflections/refractions** (Chapter 15), and **emission/glow** (Chapter 16).

## 13.10 Relating to raymarched surfaces

For a raymarched surface, the material is defined *per hit point* on the implicit surface. The key difference from mesh rendering is that:

1. The normal is computed from the field (Chapter 12).
2. The "texture" and "details" come from procedural fields evaluated at the hit point (Chapters 16–18).
3. Shadows and AO are computed by *marching from the hit point* along the light (Chapter 14), not from a shadow map.
4. The surface can be *deformed at the hit point* — adding displacement, curvature-based bevels, and material variation as pure functions.

This is why raymarching can make a single SDF look like a detailed creature, metal, or crystal: the lighting model is applied to a procedurally modulated field.

## Exercises

1. **(Derivation)** Derive the cosine law from the geometric cross-section argument, and state why the $\max(0,\cdot)$ clamp is required.
2. **(Derivation)** Derive the reflection vector $\mathbf r=\mathbf d-2(\mathbf d\cdot\mathbf n)\mathbf n$.
3. **(Derivation)** Show that maximizing $\mathbf r\cdot\mathbf v$ is equivalent to maximizing $\mathbf n\cdot\mathbf h$.
4. **(Derivation)** Derive the Cook–Torrance form and explain each factor.
5. **(Analytic)** Explain why GGX has a longer tail than Blinn-Phong and how the roughness parameter changes highlight shape.
6. **(Derivation)** Derive/justify the Schlick approximation and state its cosine exponent.
7. **(Implementation)** Implement Lambert + Blinn-Phong + Schlick/Grazing rim on a sphere; observe rim brightening with Fresnel.
8. **(Design)** Combine a curvature-based term with Fresnel to simulate "wet" metal; describe the math of the highlight change.
