#include <stdio.h>
#include <stdint.h>

uint64_t add(uint64_t x, uint64_t y) {
    printf("USED IN JASMIN: add(%lu, %lu)\n", x, y);
    return x + y;
}

extern uint64_t run_add(uint64_t a, uint64_t b);

int main(void) {
    uint64_t result;

    result = run_add(5, 3);
    printf("RESULT        : run_add(5, 3) = %lu \n", result);

    printf("\n");

    result = run_add(100, 200);
    printf("RESULT        : run_add(100,200) = %lu \n", result);

    return 0;
}
