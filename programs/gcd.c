#ifdef unix
#include <stdio.h>
#endif

int int_remainder(int a, int b) {
    while (a >= b) {
        a -= b;
    }

    return a;
}

int gcd(int a, int b)
{
    int previous_r = b;

    int current_r;
    while ((current_r = int_remainder(a, previous_r)) != 0) {
        a = previous_r;
        previous_r = current_r;
    }

    return previous_r;
}

void main()
{
    int a = 1071;
    int b = 462;

    #ifdef unix
    printf("a: ");
    scanf("%d", &a);
    printf("b: ");
    scanf("%d", &b);
    #endif

    int res = gcd(a, b);

    #ifdef unix
    printf("%d\n", res);
    #endif

}
