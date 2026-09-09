# Chapter 19 — Fractals and Distance Estimators

Fractals are the crown jewel of procedural geometry: an *iterated map* escapes or converges, and its "escape-time" structure encodes an infinitely detailed surface. This chapter derives the mathematics of escape-time fractals, the 2D Mandelbrot/Julia sets, the 3D Mandelbulb and Mandelbox, and the **distance estimator** that makes them renderable.

## 19.1 Dynamical systems and iteration

An **iterated map** is a function $F:\mathbb R^n\to\mathbb R^n$ applied repeatedly:

$$
\mathbf z_{k+1}=F(\mathbf z_k),\qquad k=0,1,2,\dots
$$

The sequence $\{\mathbf z_k\}$ is an **orbit**. Depending on the *initial value* $\mathbf z_0$ (and on the parameters of $F$), the orbit may:

- converge to a fixed point / cycle,
- diverge (escape to infinity),
- or stay bounded and roam chaotically.

**Escape-time fractals** capture the *boundary between escaping and bounded orbits*. The set of points whose orbit stays bounded is the **filled Julia set** (if we iterate $z\mapsto z^2+c$ with fixed $c$ and varying $z_0$) or the **Mandelbrot set** (if $z_0=0$ and $c$ varies).

## 19.2 Complex numbers and the Mandelbrot set

The 2D Mandelbrot set is the iteration of the complex quadratic:

$$
z_{k+1}=z_k^2+c,\qquad z_0=0.
$$

**Interpretation.** For each point $c\in\mathbb C$ (the screen coordinate), we iterate $z=z^2+c$. If the orbit stays bounded as $k\to\infty$, $c$ is in the Mandelbrot set; otherwise it escapes.

**The escape criterion.** If at some step $|z_k|>2$, the orbit diverges (because once $|z|>2$, $|z^2+c|\ge|z|^2-|c|>|z|$ grows without bound). So the bailout radius $R=2$ is a standard threshold: iterate until $|z_k|>R$ or a max iteration count.

**Power-2 in complex arithmetic.** $z^2=(x+iy)^2=x^2-y^2+i(2xy)$. This doubles the angle and squares the modulus. The Mandelbrot set's "fractal-ness" comes from this *nonlinear* map: it self-copies at every scale, and the boundary is a Julia set.

## 19.3 Julia sets

For a *fixed* $c$, the set of $\mathbf z_0$ whose orbits stay bounded is the **filled Julia set**; its boundary is the **Julia set**. The Mandelbrot set is the set of $c$ for which the Julia set is connected (a famous correspondence). Julia sets are the "wandering boundary" structures and are the primary 2D fractal source.

## 19.4 Escape-time coloring

The **iteration count** at escape ($k$ such that $|z_k|>R$) is a *discrete* coloring: points deep inside the set have high iteration counts (never escape). The **smooth iteration count** refines this:

$$
\mu=k+1-\frac{\log(\log|z_k|)}{\log 2},
$$

which interpolates the iteration count to a smooth, continuous value. This $\mu$ is directly related to the **Douady–Hubbard potential** and to the *distance estimator* (Chapter 20). It is the basis of smooth coloring.

## 19.5 The derivative of the iteration (the running derivative)

To estimate the distance to the boundary (a *distance estimator*), we need the derivative of the iteration map with respect to $c$. Define

$$
f_n(c)=z_n(c)\quad (k\text{-th iterate}), \qquad
f_{n}'=\frac{\partial z_n}{\partial c}.
$$

Differentiating $z_{k+1}=z_k^2+c$ with respect to $c$:

$$
z'_{k+1}=2z_k\,z'_k+1,\qquad z'_0=0.
$$

So the **running derivative** $z'_k$ is accumulated during the iteration. Its magnitude $|z'_k|$ measures how sensitive the orbit is to the parameter — i.e. how *stretched* space is near that point, which is exactly what determines the local distance distortion.

**General power $z\mapsto z^p+c$:** $z'_{k+1}=p\,z_k^{p-1}\,z'_k+1$.

## 19.6 The Mandelbulb: raising the polynomial to 3D

The Mandelbulb (White/Nylander, 2009) extends the idea to 3D by defining a spherical-coordinate "power" (Chapter 04). For a vector $\mathbf z=(x,y,z)$, convert to spherical $(r,\theta,\phi)$:

$$
r=\lVert\mathbf z\rVert,\quad \theta=\arccos(z/r),\quad \phi=\operatorname{atan2}(y,x).
$$

Then define the **power-n map** $\mathbf z\mapsto\mathbf z^n$ by

$$
\mathbf z^n=
r^n\big(\sin(n\theta)\cos(n\phi),\ \sin(n\theta)\sin(n\phi),\ \cos(n\theta)\big),
$$

and iterate

$$
\mathbf z_{k+1}=\mathbf z_k^n+\mathbf c .
$$

The classic Mandelbulb uses $n=8$ (power 8), which gives the iconic bulbous, spiky fractal.

**Distance estimator for the Mandelbulb.** Track a scalar running derivative $dr$ (magnitude of the Jacobian). Starting $dr=1$, each iteration the power map multiplies by $n r^{n-1}$:

$$
dr_{k+1}=n\,r_k^{\,n-1}\,dr_k+1 .
$$

When the orbit escapes, the distance estimator is

$$
\text{DE}=\frac{0.5\,\log(r)\,r}{dr},
$$

where $r=|z_n|$ is the escape length and $dr$ the running derivative. (This is the Hubbard–Douady based estimate; Chapter 20 derives it.) The factor of 0.5 ensures a *conservative lower bound* (safe for sphere tracing).

**Why this works.** In spherical coordinates the power map doubles angles and raises the modulus; the derivative $dr$ tracks how space is stretched by the map. Near the fractal surface, the orbit escapes slowly and the derivative is moderate; far away it escapes fast. The ratio gives the *distance* by a potential-theoretic argument (Green's function of the complement).

## 19.7 The Mandelbox: folding systems

The Mandelbox uses *folding* instead of a polynomial power. Its iteration is:

$$
\mathbf z_{k+1}=s\cdot\operatorname{sphereFold}\big(\operatorname{boxFold}(\mathbf z_k)\big)+\mathbf c ,
$$

where

- **Box fold (isometry).** If a coordinate $z_i>1$, reflect it to $2-z_i$; if $z_i<-1$, to $-2-z_i$. (This is `abs`-based folding, an isometry — Chapter 11.)
- **Sphere fold.** If $\lVert\mathbf z\rVert<r_{\min}$, scale by $r_{\min}^2/\lVert\mathbf z\rVert^2$; if $\lVert\mathbf z\rVert<r_{\max}$, scale by $r_{\max}^2/\lVert\mathbf z\rVert^2$. This scales space non-uniformly (the "warp" that creates structure).
- **Scale.** Multiply by $s$; typical interesting values are $s\in(-2.5,-1.5)$.

**Why a scalar derivative suffices.** The box fold is an isometry (doesn't change distances). The sphere fold scales space by a known factor. So the running *scalar* derivative is simply multiplied by the fold's cancellation factors at each step, and the distance estimator is the same Hubbard–Douady form. This scalar approximation was proposed by Buddhi on the Fractal Forums and is standard for the Mandelbox.

## 19.8 Quaternion and other 3D fractals

- **Quaternion Julia sets.** Iterate $z\mapsto z^2+c$ where $z,c$ are *quaternions*. Since $\mathbb H$ is 4-dimensional, we slice to 3D for display. The result is a smooth, swirling fractal.
- **Other triplex/polynomial variants.** Benesi-type formulas use more elaborated spherical/trigonometric maps for richer structures.

## 19.9 Orbit traps

**Orbit traps** color the fractal by *how close the orbit comes to a fixed geometric object* (a point, a line, a sphere) during its escape. The accumulated minimum distance to the trap along the orbit is the color coordinate:

$$
\text{trap}=\min_k \lVert\mathbf z_k-\mathbf t\rVert.
$$

This produces the metallic, banded, "swirled" colors seen in fractal art. The trap is a mathematical device: track the minimum distance from the orbit to a target set, then map it to a color gradient.

## 19.10 Folding, scaling, and self-similarity

The visual "complexity" of a fractal comes from the interplay:

- **Scaling** (self-similar magnification) — the map rescales space, so the structure replicates at smaller scales.
- **Folding** (reflection/symmetry) — box folds and `abs` folds introduce mirror symmetry that creates kaleidoscopic structure.
- **Iteration** (nonlinearity) — repeated application of a nonlinear map creates the fine, self-similar boundary.

These three, combined, generate enormous structure from tiny formulas. This is the same trio (scaling, folding, iteration) as the KIFS of Chapter 11.

## 19.11 The field class of fractal distance estimators

Fractal DEs are **distance estimators** — they approximate the true distance and are *usually conservative* (they tend to underestimate near the surface due to the 0.5 factor) but are not proven exact. The 0.5 in `0.5*log(r)*r/dr` is specifically chosen to make the estimate a lower bound (safe), because the true distance to the surface is bounded below by this conservative estimate (Chapter 20). So fractal DEs are safe to march with, but they are an *approximation* — misclassifying them as exact SDFs is a common mistake.

## 19.12 Rendering a fractal: recap of the pipeline

1. **Define the map** ($z\mapsto z^p+c$, or the folding system).
2. **Iterate** until escape or max iterations; accumulate the running derivative $dr$.
3. **Estimate distance** with the DE formula.
4. **March** using the DE as a safe step.
5. **Color** with the smooth iteration count and/or an orbit trap.

This is why fractals need a *distance estimator* rather than an SDF: the fractal's surface is not described by a closed-form distance function, so we estimate it from the iteration.

## Exercises

1. **(Derivation)** Derive the escape criterion $|z|>2$ for the quadratic map.
2. **(Derivation)** Differentiate $z\mapsto z^p+c$ to obtain the running derivative.
3. **(Derivation)** Explain how the Mandelbulb's power map is defined in spherical coordinates and why it's nonlinear.
4. **(Derivation)** Explain why a scalar running derivative suffices for the Mandelbox, given that the box fold is an isometry.
5. **(Geometric)** Describe the geometric meaning of the orbit trap and how it produces color.
6. **(Implementation)** Implement a 2D Julia set renderer with smooth coloring and a DE-based zoom.
7. **(Implementation)** Implement the Mandelbulb DE and raymarch it; explain the role of $dr$ and the 0.5 factor.
