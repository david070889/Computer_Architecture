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

static inline int64_t getbit(int64_t value, int n)
{
    return (value >> n) & 1;
}

static int32_t imul24(int32_t a, int32_t b)
{
    uint32_t r = 0;
    for (; b; b >>= 1)
        r = (r >> 1) + (a & -getbit(b, 0));
    return r;
}

float fmul32(float a, float b)
{
    /* TODO: Special values like NaN and INF */
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;
    if (ia == 0 || ib == 0) return 0;
    
    /* mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;

    int32_t sea = ia & 0xFF800000;
    int32_t seb = ib & 0xFF800000;

    /* result of mantissa */
    int32_t m = imul24(ma, mb);
    int32_t mshift = getbit(m, 24);
    m >>= mshift;

    int32_t r = ((sea - 0x3f800000 + seb) & 0xFF800000) + m - (0x800000 & -!mshift);
    int32_t ovfl = (r ^ ia ^ ib) >> 31;
    r = r ^ ( (r ^ 0x7f800000) & ovfl);
    return *(float *)&r;
}

static int32_t idiv24(int32_t a, int32_t b){
    uint32_t r = 0;
    for (int i = 0; i < 32; i++){
        r <<= 1;
        if (a - b < 0){
            a <<= 1;
            continue;
        }

        r |= 1;
        a -= b;
        a <<= 1;
    }

    return r;
}

float fdiv32(float a, float b)
{
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;
    if (a == 0) return a;
    if (b == 0) return *(float*)&(int){0x7f800000};
    /* mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;

    /* sign and exponent */
    int32_t sea = ia & 0xFF800000;
    int32_t seb = ib & 0xFF800000;

    /* result of mantissa */
    int32_t m = idiv24(ma, mb);
    int32_t mshift = !getbit(m, 31);
    m <<= mshift;

    int32_t r = ((sea - seb + 0x3f800000) - (0x800000 & -mshift)) | (m & 0x7fffff00) >> 8;
    int32_t ovfl = (ia ^ ib ^ r) >> 31;
    r = r ^ ((r ^ 0x7f800000) & ovfl);
    
    return *(float *) &r;
    // return a / b;
}


float my_power(float guess, float n){
    int x = (int)n;
    float temp = 1;
    for (int i = 0; i < x; i++){
        temp = fmul32(temp, guess);
    }
    return temp;
}

float fabsf(float x){
    uint32_t ix = *(uint32_t *)&x;
    uint32_t cmp_a = ix & 0x7fffffff;
    return *(float *)&ix;
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

int f2i32(int x) {
    int32_t a = *(int *)&x;
    int32_t ma = (a & 0x7FFFFF) | 0x800000;
    int32_t ea = ((a >> 23) & 0xFF) - 127;
    if (ea < 0)
        return 0;
    else if (ea <= 23)
        ma >>= (23 - ea);
    else
        ma <<= (ea - 23);

    return ma;
}

// 牛頓法計算 x 的 n 次方根
float nthRoot(float x, int n) {
    float f_n = (float)n;
    float guess = fdiv32(x, f_n); // 初始猜測值
    float epsilon = 0.0001; // 計算精度
    float n_One = -1;

    while (fcomparison(fabsf(fadd32(my_power(guess, f_n), -x)), epsilon)) {
        float new_guess = fdiv32(fadd32(fmul32(fadd32(f_n, n_One), guess), fdiv32(x, my_power(guess, fadd32(f_n, n_One)))), f_n);
        if (new_guess == guess){
            // printf("%f\n",new_guess);
            return guess;
        }
        guess = new_guess;
        // printf("%f\n",guess);
    }

    return guess;
}

int main() {
    float x;
    int n;

    printf("input x : ");
    scanf("%f", &x);
    
    printf("input n : ");
    scanf("%d", &n);

    float result = nthRoot(x, n);
    printf("%d-th root of %f is %f\n", n, x, result);

    printf("Press any key to exit...\n");

    getch();

    return 0;
}