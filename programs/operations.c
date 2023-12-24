int main()
{
    int *load_address = 0;
    int *result_address = 0;

    int a = *load_address;
    int b = *(load_address + 1);

    *(result_address + 0) = a + b;
    *(result_address + 1) = a - b;
    *(result_address + 2) = a > b;
    *(result_address + 3) = a < b;
    *(result_address + 4) = a << b;
    *(result_address + 5) = a >> b;
}
