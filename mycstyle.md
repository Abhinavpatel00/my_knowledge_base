- declare variable at start of function 

- prefers ids over pointers so called weak pointers 

- prefer static memory over dynamic 

- avoid too much overfilling of stack  while using stack  or prefering too much static its sometimes easy to crash the stack and error is very hard to trace 

- align struct  and variable in a table like formatting much like john carmack

- design code such  that it doesnt need much null checks


# Coding Doctrine

This project prioritizes data-oriented design, predictable performance, explicit ownership, and simple machinery.

## Core Principles

* Prefer IDs/handles over long-lived pointers.
* Prefer static, fixed-capacity, or arena-backed storage when appropriate.
* Minimize global state and hidden side effects.
* Prefer explicit parameter passing and return values.
* Make ownership and lifetimes explicit.
* Design APIs so invalid states are difficult to represent.
* Prefer compile-time knowledge where useful.
* Optimize data movement and memory bandwidth before instruction count.
* Measure before and after meaningful optimizations.

## Data-Oriented Design

Data layout is a primary design decision. Design around access patterns and processing requirements rather than object-oriented abstractions.

Prefer:

```c
TextureId  texture;
MeshId     mesh;
MaterialId material;
```

over long-lived pointers:

```c
Texture  *texture;
Mesh     *mesh;
Material *material;
```

Prefer dense arrays, sparse sets, fixed-capacity pools, arenas, and handles.

Examples:

```c
Arena   arena;

Texture textures[MAX_TEXTURES];
Entity  entities[MAX_ENTITIES];
```

Minimize struct size and organize data according to access patterns. Separate hot and cold data when beneficial.

When a required data-oriented primitive is missing from `mylib`, add the reusable primitive to `external/mu` rather than introducing an ad-hoc solution.

## Memory

Prefer predictable allocation strategies.

Use static or fixed-capacity storage when appropriate, but do not blindly make everything static. Excessive static allocation wastes memory and creates unnecessary capacity limits.

Treat stack space as limited. Avoid large local allocations, oversized temporary structs, and unnecessarily deep call chains. Stack failures can be difficult to diagnose.

Avoid hidden allocations in performance-critical code.

## Performance

Prioritize:

1. Memory bandwidth
2. Cache locality
3. Contiguous data access
4. Reduced pointer chasing
5. Batch processing
6. Predictable control flow
7. Reduced branches
8. Instruction count

Prefer data layouts that allow sequential processing.

Organize data around the operation that consumes it rather than around arbitrary ownership relationships.

Keep hot loops simple, predictable, and free from unnecessary validation or indirection.

## Preparation and Execution

Separate preparation from execution when practical.

Preparation may perform:

* Validation
* ID resolution
* Sorting
* Culling
* Batching
* Command generation

Execution should operate on prepared data with minimal branching, indirection, and validation.

The principle is:

> Push validation to boundaries. Keep inner loops clean.

## Invariants

Do not eliminate null checks by ignoring errors. Eliminate them by establishing stronger invariants.

Avoid deeply nested defensive checks:

```c
Texture *texture = get_texture(id);

if (texture) {
    if (texture->image) {
        if (texture->view) {
            ...
        }
    }
}
```

Prefer APIs and initialization rules that guarantee valid state before entering performance-critical code.

If an operation can genuinely fail, make that failure explicit through a boolean result, invalid ID, error value, or output parameter.

The goal is not "fewer null checks."

The goal is stronger contracts.

## APIs

Prefer APIs that make misuse difficult.

Good APIs establish clear ownership, lifetime, validity, and failure semantics.

Avoid APIs that require every caller to repeatedly reconstruct the same validity assumptions.

Prefer resolving and validating resources at system boundaries rather than throughout inner loops.

## Functions

Prefer meaningful, substantial functions.

Do not split code into many tiny functions merely for abstraction or style.

Extract a function when it provides meaningful reuse, improves reasoning, establishes a useful boundary, or makes testing easier.

Avoid abstraction for abstraction's sake.

## Global State

Minimize global state and side effects.

Prefer:

```c
render_frame(Renderer *renderer, Frame *frame);
```

over hidden access to global renderer state.

Important state should generally be passed explicitly.

Hidden dependencies make code harder to reason about, test, profile, and optimize.

## Naming

Types use `PascalCase`.

Functions use `snake_case`.

Variables and fields use `snake_case`.

Align related declarations for readability:

```c
TextureId  texture_id;
MeshId     mesh_id;
MaterialId material_id;

uint32_t   width;
uint32_t   height;
uint32_t   stride;
```

Favor compact, visually scannable layouts.

## Storage and Data Structures

Preferred structures include:

* Dense arrays
* Sparse sets
* Fixed-capacity arrays
* Pools
* Arenas
* ID/handle-based resource tables
* Structure-of-arrays layouts when fields are processed independently
* Array-of-structures layouts when records are processed together

Choose structures based on:

* Access pattern
* Lifetime
* Mutation frequency
* Memory locality
* Iteration requirements
* Capacity requirements

Do not introduce a complex data structure without a concrete reason.

## External Libraries

External libraries should not dictate engine architecture.

When `mylib` lacks a primitive required by the project's data-oriented design, extend `external/mu` with a small reusable primitive rather than introducing a competing allocation or ownership model.

## Optimization

Prefer simple machinery whose cost is visible.

Optimization workflow:

```text
Measure
→ identify bottleneck
→ change data/layout/algorithm
→ measure again
→ keep the change if it improves the real workload
```

Do not sacrifice substantial clarity for hypothetical performance.

Prefer optimizing data movement before instruction count.

The compiler can eliminate instructions. It cannot rescue a fundamentally poor data layout.

## Code Quality

* Keep control flow obvious.
* Keep ownership obvious.
* Keep lifetimes predictable.
* Avoid hidden work.
* Avoid unnecessary indirection.
* Avoid unnecessary abstraction.
* Avoid unnecessary allocation.
* Prefer simple mechanisms with measurable costs.
* Use assertions to enforce important invariants in debug builds.
* Comments should explain why, not restate what the code already says.
