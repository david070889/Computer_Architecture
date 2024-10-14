#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <conio.h>


#define iswap(x, y) ((x) ^= (y), (y) ^= (x), (x) ^= (y))
uint32_t count_leading_zeros(uint32_t x) {
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x55555555);
    x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);

    return (32 - (x & 0x7f));
}

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

float fabsf(float x){
    uint32_t ix = *(uint32_t *)&x;
    uint32_t cmp_a = ix & 0x7fffffff;
    return *(float *)&ix;
}

int fcomparison(float a, float b){
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;

    /* mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;

    /* exponent */
    int32_t ea = ia & 0x7F800000;
    int32_t eb = ib & 0x7F800000;

    if (ea > eb){
        return 1;
    } 
    else if (ea < eb){
        return 0;
    } 
    else{
        if (ma > mb){
            return 1;
        } 
        else{
            return 0;
        }
    }



}

int main() {
    float x;
    float n;

    printf("input x : ");
    scanf("%f", &x);

    printf("input n : ");
    scanf("%f", &n);

    float result = fcomparison(x, n);
    printf("%lf is bigger than %lf %lf\n", x, n, result);

    printf("Press any key to exit...\n");

    getch();

    return 0;
}
