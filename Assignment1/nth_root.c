#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <conio.h>
#define iswap(x, y) ((x) ^= (y), (y) ^= (x), (x) ^= (y))

float fadd32(float a, float b) {
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;

    int32_t cmp_a = ia & 0x7fffffff;
    int32_t cmp_b = ib & 0x7fffffff;

    if (cmp_a < cmp_b)
        iswap(ia, ib);
    /* exponent */
    int32_t ea = (ia >> 23) & 0xff;
    int32_t eb = (ib >> 23) & 0xff;

    /* mantissa */
    int32_t ma = ia & 0x7fffff | 0x800000;
    int32_t mb = ib & 0x7fffff | 0x800000;

    int32_t align = (ea - eb > 24) ? 24 : (ea - eb);

    mb >>= align;
    if ((ia ^ ib) >> 31) {
        ma -= mb;
    } else {
        ma += mb;
    }

    int32_t clz = count_leading_zeros(ma);
    int32_t shift = 0;
    if (clz <= 8) {
        shift = 8 - clz;
        ma >>= shift;
        ea += shift;
    } else {
        shift = clz - 8;
        ma <<= shift;
        ea -= shift;
    }

    int32_t r = ia & 0x80000000 | ea << 23 | ma & 0x7fffff;
    float tr = a + b;
    return *(float *)&r;
}

int main() {
    float x = 554.83; 
    int n = 4;

    // printf("input x : ");
    // scanf("%f", &x);
    
    // printf("input n : ");
    // scanf("%d", &n);

    float result = nthRoot(x, n);
    printf("%d-th root of %lf is %lf\n", n, x, result);

    printf("Press any key to exit...\n");

    getch();

    return 0;
}
