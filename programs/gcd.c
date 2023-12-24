#ifdef unix
#include <stdio.h>
#endif

int int_remainder(int a, int b)
{
    if (b == 0) {
        return 0;
    }

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

#ifdef unix
void main()
{
    int a, b;
    printf("a: ");
    scanf("%d", &a);
    printf("b: ");
    scanf("%d", &b);
    int res = gcd(a, b);
    printf("%d\n", res);
}
#else
void main()
{
    int* a_address = (int*)4;
    int* b_address = (int*)8;

    int a = *a_address;
    int b = *b_address;

    int res = gcd(a, b);

    int* result_address = 0;
    *result_address = res;
}
#endif

