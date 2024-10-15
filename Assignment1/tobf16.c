#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <conio.h>


float fadd32(float a, float b) {
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;

    int32_t cmp_a = ia & 0x7fff;
    int32_t cmp_b = ib & 0x7fff;

    if (cmp_a < cmp_b)
        iswap(ia, ib);
    /* exponent */
    int32_t ea = (ia >> 7) & 0xff;
    int32_t eb = (ib >> 7) & 0xff;

    /* mantissa */
    int32_t ma = ia & 0x7f | 0x80;
    int32_t mb = ib & 0x7f | 0x80;

    int32_t align = (ea - eb > 7) ? 7 : (ea - eb);

    mb >>= align;
    if ((ia ^ ib) >> 15) {
        ma -= mb;
    } else {
        ma += mb;
    }

    // stop right here
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

    int32_t r = ia & 0x8000 | ea << 7 | ma & 0x7f;
    float tr = a + b;
    return *(float *)&r;
}

uint16_t m_count_leading_zeros(uint16_t x) {
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x5555);
    x = ((x >> 2) & 0x3333) + (x & 0x3333);
    x = ((x >> 4) + x) & 0x0f0f;
    x += (x >> 8);
    

    return (16 - (x & 0x7f));
}

int main(){
    int x;

    printf("input x : ");
    scanf("%d", &x);

    uint16_t n = (uint16_t)x;

    uint16_t result = m_count_leading_zeros(n);
    printf("clz is %d\n", result);

    printf("Press any key to exit...\n");

    getch();

    return 0;
}