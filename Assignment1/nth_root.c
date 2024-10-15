#include <stdio.h>
#include <math.h>
#include <conio.h>

// 牛頓法計算 x 的 n 次方根
float nthRoot(float x, int n) {
    float guess = x / n; // initial guess
    float epsilon = 0.00001; // precision

    while (fabs(pow(guess, n) - x) > epsilon) {
        float new_guess = ((n - 1) * guess + x / pow(guess, n - 1)) / n;
        if (new_guess == guess){
            printf("%lf\n",new_guess);
            return guess;
        }
        guess = new_guess;
        printf("%lf\n",guess);
    }
    return guess;
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
