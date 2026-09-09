# Chapter 20 — Distance Estimators

A **distance estimator (DE)** is a function that approximates the distance to a surface, often derived from an iterative process. Fractals have no closed-form SDF; their surfaces must be *estimated*. This chapter derives the DE from the potential theory of escape-time maps, explains the "running derivative," and analyzes the precision — where the DE is conservative and safe, and where it can fail.

## 20.1 The problem: no SDF for a fractal

An escape-time fractal's surface is the boundary of the set of points whose orbit stays bounded. There is no elementary closed-form distance function. But the *iteration itself* carries enough information to estimate the distance. The key insight: **the rate at which the iteration "escapes" tells us how close we are to the boundary.**

## 20.2 The Douady–Hubbard potential

For a quadratic map, the **smooth iteration count** (from Chapter 19)

$$
\mu=n+1-\frac{\log(\log|z_n|)}{\log 2}
$$

is a real-valued function that grows smoothly near infinity. The **Douady–Hubbard potential** is essentially $G=\mu^\text{(scaled)}$, and it is **harmonic** (a solution of Laplace's equation) outside the Mandelbrot set. A harmonic function's behavior encodes the geometry of the boundary: its gradient is related to the reciprocal of the distance to the set (the "potential theory" connection).

## 20.3 Deriving the distance estimate

We want the distance from an exterior point $c$ to the fractal boundary. The standard result (Douady–Hubbard / used by Hart and the community) is

$$
\text{DE}(c)\approx\frac{\lvert z_n\rvert\,\log\lvert z_n\rvert}{2\,\lvert z_n'\rvert},
$$

i.e. $0.5\cdot\log(r)\cdot r/dr$ with $r=\lvert z_n\rvert$ and $dr=\lvert z_n'\rvert$.

**Sketch of the derivation.** Consider the smooth iteration count $\mu$ and its reciprocal-gradient: the distance to the boundary is roughly $1/|\nabla \mu|$. Near infinity, the behavior of the orbit is $z_n\sim R^2$ (quadratic escape), and the derivative of the "potential" with respect to $c$ pulls out a factor that leads to the $r\log r/dr$ form. The precise form:

$$
d=\frac{|z_n|\,\log|z_n|}{|\partial z_n/\partial c|}
$$

up to a constant. The factor $1/2$ is inserted to keep the estimate a *lower bound* (conservative), so it is safe for sphere tracing. In this sense **the DE is an approximation**, and the 0.5 factor is a safety margin, not an exact constant.

**Why the log and the r.** The $\log|z_n|$ appears because the potential (Green's function) grows like $\log|z_n|$ near infinity; the $|z_n|$ appears from the derivative of $\log|z_n|$. The denominator $|z_n'|$ is the *running derivative*, the sensitivity of the orbit to a change in the parameter $c$.

## 20.4 The running derivative

The **running derivative** is the magnitude of the derivative of the current iterate with respect to the (parameter) point:

$$
dr_k=\left|\frac{\partial z_k}{\partial c}\right|.
$$

It is accumulated during the iteration. For $z\mapsto z^p+c$:

$$
dr_{k+1}=p\,|z_k|^{p-1}\,dr_k+1,\qquad dr_0=0 .
$$

**Interpretation.** $dr$ measures how much the map *stretches* space at the current orbit point. A large $dr$ means the map is expansive there; the orbit is sensitive, and the local surface is "far from flat," so the safe step is small. A small $dr$ means the map is contracting, and the step can be large.

## 20.5 The scalar vs. full-Jacobian dilemma

The 2D Mandelbrot DE uses a single complex derivative $z'$. In 3D, the map is vector-valued, so the derivative is a **Jacobian matrix**. Two approaches:

1. **Scalar running derivative** (Buddhi/Makin). Track only the *magnitude* $dr$, updated by multiplying the per-step scale factors (for the Mandelbox, the fold/cancellation factors). This is cheap but approximates the true Jacobian by its dominant scalar behavior. It works well *because* the interesting folds are either isometries (unit scale) or uniform radial scalings.

2. **Full Jacobian via dual numbers.** Track the full $3\times3$ Jacobian $D$. Then the DE is more accurate:

$$
\text{DE}=\frac{\lVert z\rVert^2}{\lVert z\cdot D\rVert}\quad\text{(from }\ \frac{\lVert z\rVert}{\lVert D\rVert}\ \text{scaled)}
$$

or, more precisely, $\text{DE}=\lVert z\rVert/\lVert z\cdot D\rVert$ times a computable factor. This is more expensive (a matrix of dual numbers) but is exact for the derivative. In practice, the scalar form is used and is *good enough* for the Mandelbox; the full Jacobian is used where accuracy matters (e.g. for smooth surfaces that must not have banding).

### 20.5.1 Dual numbers

A **dual number** is $a+b\varepsilon$ with $\varepsilon^2=0$. It propagates derivatives through arithmetic without numerical differentiation: $f(a+b\varepsilon)=f(a)+f'(a)b\varepsilon$. For vector-valued maps, use a $3\times3$ matrix of dual numbers (or a "vector of dual matrices"). This gives an **exact derivative** at the cost of more arithmetic, and is the clean way to get an exact $D$.

## 20.6 Precision of the distance estimate

**Where the DE is conservative (safe).** The 0.5 factor makes the standard DE a *lower bound* on the distance in many cases, so it is safe for sphere tracing (it never undershoots the true distance... it underestimates, so it's conservative). This is why fractals render properly with sphere tracing.

**Where the DE is not exact.** The estimate is exact only in the limit of infinite iterations. With a finite iteration count (as in a real-time shader), the DE is approximate. Consequences:

- **Banding / stair-stepping.** Because the iteration count is quantized, the DE can have discontinuities when the orbit crosses a threshold — producing visible banding rings (Chapter 24). Smooth coloring and more iterations reduce this.
- **Underestimation near the surface.** Near the boundary, the DE is a good lower bound but is *not tight*; the marcher takes small steps there, which is slow but safe.
- **The 0.5 factor trade-off.** A factor closer to 1 gives a tighter, faster estimate but risks overstepping (tunneling). The 0.5 is a safety margin that guarantees the estimate is a lower bound asymptotically.

## 20.7 Alternative DE approximations

- **Escape-radius gradient (finite differences).** Compute the escape *length* and its gradient numerically; the DE is $0.5\cdot\text{potential}/\text{gradient}$. Only correct for the same iteration count everywhere (else artifacts).
- **Potential-gradient approximation.** Use the potential $p=\log|z|/\text{pow}^i$ and its difference; $\text{DE}=0.5\cdot G/|G'|$ as in Chapter 19.
- **The "distance to the set" via the potential.** $DE=0.5\cdot\text{potential}/|\nabla\text{potential}|$.

All of these are the *same* underlying formula, realized with different derivatives (analytic running derivative vs. finite-difference gradient).

## 20.8 Field class of DEs

**Distance estimators are an `APPROXIMATION`/`DISTANCE ESTIMATOR`**, not an exact SDF. When conservative they act as a *bound* (safe), but this is an empirical/heuristic guarantee, not a proven property for every map and iteration count. The book labels them as such. The practical rule: **use a DE for fractal rendering, expect slight banding and slight step-size conservatism, and treat "safe" with care.**

## 20.9 The "0.5" — a worked scaling sanity check

For $z\mapsto z^2+c$ with $z_n\gg1$, the orbit escapes like $|z_n|\approx|z_1|^{2^n}$, and $\log|z_n|\approx2^n\log|z_1|$. The running derivative $|z_n'|\approx2^n|z_1|^{2^n-1}$. Then

$$
\frac{|z_n|\,\log|z_n|}{|z_n'|}\approx\frac{|z_1|^{2^n}\cdot2^n\log|z_1|}{2^n|z_1|^{2^n-1}}\approx2\,|z_1|\log|z_1|,
$$

which is the boundary-distance estimate at the initial point. This confirms the dimensional/form structure and why the $1/2$ normalizes to the Euclidean distance.

## Exercises

1. **(Derivation)** Derive the running derivative for $z\mapsto z^p+c$.
2. **(Derivation)** Provide the sketch of the DE derivation via the potential and its gradient; state where the $1/2$ comes from.
3. **(Analytic)** Explain why a finite iteration count makes the DE approximate, and how it causes banding.
4. **(Derivation)** Show the dual-number approach to computing the full Jacobian, and the resulting DE.
5. **(Analytic)** Compare the scalar-running-derivative value vs. the full-Jacobian accuracy; when does the scalar approximation fail?
6. **(Implementation)** Implement the Mandelbulb DE with dual numbers and without; compare their visual/perf.
7. **(Design)** Give a DE that is *not* a safe bound (e.g. factor $>0.5$) and explain the visual consequence (banding/tunneling).
