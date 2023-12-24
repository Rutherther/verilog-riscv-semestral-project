void main()
{
    int *result_address = 0;
    int *load_address = 0;
    int a = *(load_address);
    int b = *(load_address + 1);

    if (a < b) {
        *(result_address + 0) = 1;
    } else {
        *(result_address + 0) = 2;
    }

    if (a >= b) {
        *(result_address + 1) = 1;
    } else {
        *(result_address + 1) = 2;
    }

    if (a != b) {
        *(result_address + 2) = 1;
    } else {
        *(result_address + 2) = 2;
    }

    if (a == b) {
        *(result_address + 3) = 1;
    } else {
        *(result_address + 3) = 2;
    }

    if (a <= b) {
        *(result_address + 4) = 1;
    } else {
        *(result_address + 4) = 2;
    }

    if (a > b) {
        *(result_address + 5) = 1;
    } else {
        *(result_address + 5) = 2;
    }
}
