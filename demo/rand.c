#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

int main(void)
{

   uintptr_t O = (uintptr_t)&O;

    printf("As pointer: %p\n", (void*)&O);
    printf("As uintptr_t: %" PRIuPTR "\n", O);

    // Keep only lower 16 bits
uintptr_t lower16 = ((uintptr_t)&lower16) & ((1ULL << 16) - 1);
//uintptr_t lower16 = (uintptr_t)&lower16 & 0xFFFF;
    printf("Full value     : 0x%" PRIxPTR "\n", O);
    printf("Lower 16 bits  : %" PRIuPTR "\n", lower16);
    return 0;
}






