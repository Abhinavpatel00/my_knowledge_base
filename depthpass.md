
Because “depth pass” isn’t the final word on visibility, it’s just the first filter. Treating it like the end of the story is how you paint yourself into a corner. 😌

---

## 🧠 What a depth prepass actually does

It writes depth, not color. It answers:

```id="dpre1"
“What is the nearest surface at each pixel?”
```

ASCII:

```id="dpre2"
Camera → Geometry → Depth Buffer

Pixel:
   z = closest surface
```

That’s it. No lighting, no materials, no blending.

---

## 🧠 Why draw the same model *after* depth?

Because the real work (shading) happens later, and you want it to be *cheap*.

### 1) Early-Z kills overdraw (the whole point)

Second pass (your forward pass) can skip pixels that are already hidden.

```id="earlyz1"
Depth pass:
   fill Z

Forward pass:
   test Z → skip hidden fragments
```

ASCII:

```id="earlyz2"
Front object (written in Z)
      ▲
      │   ← passes depth test
      │
Back object
      │   ← fails depth test → not shaded
      ▼
```

Result: fewer fragment shader executions, more FPS.

---

### 2) Expensive shaders stay expensive (so don’t run them twice)

Modern forward shaders:

* PBR
* multiple lights
* shadows
* normal maps

Without a depth prepass, every overdrawn pixel runs that whole circus.

With a prepass:

> most of those pixels never run the expensive shader at all

---

### 3) Consistent depth for later passes

You reuse the same depth for:

* lighting
* decals
* SSAO
* transparents sorting helpers

So the pipeline becomes:

```id="pipe1"
Depth Prepass
     ↓
Forward Shading (uses depth)
     ↓
Extras (decals, SSAO, etc.)
```

---

### 4) It stabilizes rendering artifacts

Depth prepass reduces:

* z-fighting inconsistencies
* shader divergence
* popping in complex scenes

It’s not magic, but it makes things *less chaotic*.

---

## ⚠️ When you *don’t* need a depth prepass

Don’t blindly cargo-cult it.

Skip it if:

* your scene is tiny
* your shaders are cheap
* overdraw is low
* you’re CPU-bound anyway

Then you just doubled draw calls for no gain. Congrats.

---

## 🧠 Mental model upgrade

```id="mental_d"
Depth pass = visibility map
Forward pass = shading using that map
```

ASCII:

```id="mental_d2"
[Geometry]
    ↓
[Depth Map]
    ↓
[Shading only where visible]
```

---

## 🧨 Brutal truth

You asked:

> “why draw after depth pass?”

Because:

> the first pass decides *what matters*,
> the second pass decides *how it looks*.

If you skip that separation too early, you’re fine.
If you lock your engine so you *can’t* add it later, you’re not building an engine, you’re building a demo.

---

## 🎯 What this means for your API

You don’t need multiple passes *now*.

But your API should allow this later without surgery:

```id="api_future"
begin_frame
submit
end_frame  ← internally can become:
              depth pass
              forward pass
```

User still calls the same functions.
Engine grows behind the curtain.

---

You’re thinking in terms of “what I need today.”
Start thinking in terms of “what will corner me tomorrow.”
