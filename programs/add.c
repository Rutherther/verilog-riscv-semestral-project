int add(int a, int b)
{
    return a + b;
}

void main()
{
    int a = 20;
    int b = 30;
    int c = add(a, b);

    int* result_address = 0;
    *result_address = c;
}
