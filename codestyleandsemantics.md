
---
static void exec_draw_direct(VkCommandBuffer cmd, const void* data)
{
    const DrawCmd* d = data;

    vkCmdDraw(cmd,
              d->direct.vertexCount,
              d->direct.instanceCount,
              d->direct.firstVertex,
              d->direct.firstInstance);
}

static void exec_draw_indexed(VkCommandBuffer cmd, const void* data)
{
    const DrawCmd* d = data;

    vkCmdDrawIndexed(cmd,
                     d->indexed.indexCount,
                     d->indexed.instanceCount,
                     d->indexed.firstIndex,
                     d->indexed.vertexOffset,
                     d->indexed.firstInstance);
}

typedef void (*PassExecFn)(Renderer*,
                           RendererPipelines*,
                           VkCommandBuffer,
                           const void*);

typedef struct
{
    PassExecFn exec;

    uint32_t pipeline_id;

    VkRenderingInfo* rendering;

    uint32_t draw_count;
    DrawCmd* draws;

} GraphicsPass;
static void exec_graphics_pass(Renderer* r,
                               RendererPipelines* pipelines,
                               VkCommandBuffer cmd,
                               const void* data)
{
    const GraphicsPass* pass = data;

    vkCmdBeginRendering(cmd, pass->rendering);

    vkCmdBindPipeline(cmd,
                      VK_PIPELINE_BIND_POINT_GRAPHICS,
                      pipelines->pipelines[pass->pipeline_id]);

    vk_cmd_set_viewport_scissor(cmd, r->swapchain.extent);

    for (uint32_t i = 0; i < pass->draw_count; i++)
    {
        pass->draws[i].exec(cmd, &pass->draws[i]);
    }

    vkCmdEndRendering(cmd);
}
DrawCmd draw = {
    .exec = exec_draw_direct,
    .direct = {
        .vertexCount = 55555 * 3,
        .instanceCount = 1,
        .firstVertex = 0,
        .firstInstance = 0
    }
};

GraphicsPass pass = {
    .exec = exec_graphics_pass,
    .pipeline_id = TRIANGLE_PIPELINE,
    .rendering = &rendering,
    .draw_count = 1,
    .draws = &draw
};
---
record_frame()
{
    begin_rendering();
    bind_pipeline(TRIANGLE_PIPELINE);
    push_constants();
    draw();
    end_rendering();
}


Replace:

for (...) {
    switch(d->type)

With function pointers:

typedef void (*DrawExecFn)(VkCommandBuffer, const DrawCmd*);

static void exec_draw_direct(...);
static void exec_draw_indexed(...);

static DrawExecFn draw_table[] = {
    exec_draw_direct,
    exec_draw_indirect,
    exec_draw_indexed,
    exec_draw_indexed_indirect,
    exec_draw_indexed_indirect_count
};

Then:

draw_table[d->type](cmd, d);

You remove the switch tree.

---
#include <vulkan/vulkan.h>
#include <stdint.h>
#include <stdio.h>

// =============================================================
// 1. MASTER VARIANT LIST (Single Source of Truth)
// =============================================================

#define DRAW_TYPES                         \
    X(DIRECT)                              \
    X(INDIRECT)                            \
    X(INDEXED)                             \
    X(INDEXED_INDIRECT)                    \
    X(INDEXED_INDIRECT_COUNT)


// =============================================================
// 2. ENUM GENERATED FROM MASTER LIST
// =============================================================

typedef enum {
#define X(name) DRAW_##name,
    DRAW_TYPES
#undef X
    DRAW_COUNT
} DrawType;


// =============================================================
// 3. DRAW COMMAND STRUCT
// =============================================================

typedef struct DrawCmd
{
    DrawType type;

    union
    {
        struct {
            uint32_t vertexCount;
            uint32_t instanceCount;
            uint32_t firstVertex;
            uint32_t firstInstance;
        } direct;

        struct {
            VkBuffer     buffer;
            VkDeviceSize offset;
            uint32_t     drawCount;
            uint32_t     stride;
        } indirect;

        struct {
            uint32_t indexCount;
            uint32_t instanceCount;
            uint32_t firstIndex;
            int32_t  vertexOffset;
            uint32_t firstInstance;
        } indexed;

        struct {
            VkBuffer     buffer;
            VkDeviceSize offset;
            uint32_t     drawCount;
            uint32_t     stride;
        } indexed_indirect;

        struct {
            VkBuffer     buffer;
            VkDeviceSize offset;
            VkBuffer     countBuffer;
            VkDeviceSize countOffset;
            uint32_t     maxDrawCount;
            uint32_t     stride;
        } indexed_indirect_count;
    };

} DrawCmd;


// =============================================================
// 4. DECLARE ALL DRAW FUNCTIONS (AUTO-GENERATED)
// =============================================================

#define X(name) \
    static void draw_##name(VkCommandBuffer cmd, const DrawCmd* d);

DRAW_TYPES
#undef X


// =============================================================
// 5. IMPLEMENTATIONS
// =============================================================

static void draw_DIRECT(VkCommandBuffer cmd, const DrawCmd* d)
{
    vkCmdDraw(cmd,
              d->direct.vertexCount,
              d->direct.instanceCount,
              d->direct.firstVertex,
              d->direct.firstInstance);
}

static void draw_INDIRECT(VkCommandBuffer cmd, const DrawCmd* d)
{
    vkCmdDrawIndirect(cmd,
                      d->indirect.buffer,
                      d->indirect.offset,
                      d->indirect.drawCount,
                      d->indirect.stride);
}

static void draw_INDEXED(VkCommandBuffer cmd, const DrawCmd* d)
{
    vkCmdDrawIndexed(cmd,
                     d->indexed.indexCount,
                     d->indexed.instanceCount,
                     d->indexed.firstIndex,
                     d->indexed.vertexOffset,
                     d->indexed.firstInstance);
}

static void draw_INDEXED_INDIRECT(VkCommandBuffer cmd, const DrawCmd* d)
{
    vkCmdDrawIndexedIndirect(cmd,
                             d->indexed_indirect.buffer,
                             d->indexed_indirect.offset,
                             d->indexed_indirect.drawCount,
                             d->indexed_indirect.stride);
}

static void draw_INDEXED_INDIRECT_COUNT(VkCommandBuffer cmd, const DrawCmd* d)
{
    vkCmdDrawIndexedIndirectCount(cmd,
                                  d->indexed_indirect_count.buffer,
                                  d->indexed_indirect_count.offset,
                                  d->indexed_indirect_count.countBuffer,
                                  d->indexed_indirect_count.countOffset,
                                  d->indexed_indirect_count.maxDrawCount,
                                  d->indexed_indirect_count.stride);
}


// =============================================================
// 6. DISPATCH TABLE (AUTO-GENERATED)
// =============================================================

typedef void (*DrawFn)(VkCommandBuffer, const DrawCmd*);

static DrawFn draw_table[DRAW_COUNT] = {
#define X(name) draw_##name,
    DRAW_TYPES
#undef X
};


// =============================================================
// 7. EXECUTION FUNCTION
// =============================================================

static inline void execute_draw(VkCommandBuffer cmd, const DrawCmd* d)
{
    draw_table[d->type](cmd, d);
}


// =============================================================
// 8. EXAMPLE USAGE
// =============================================================

void record_example(VkCommandBuffer cmd)
{
    DrawCmd draw = {
        .type = DRAW_DIRECT,
        .direct = {
            .vertexCount   = 3,
            .instanceCount = 1,
            .firstVertex   = 0,
            .firstInstance = 0
        }
    };

    execute_draw(cmd, &draw);
}
---


