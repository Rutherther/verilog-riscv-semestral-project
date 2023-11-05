void main()
{
    int *result_address = 0;
    int a = 1;
    int b = 5;

    if (a < b) {
        *result_address = 1;
    } else {
        *result_address = 2;
    }

    if (a >= b) {
        *result_address = 1;
    } else {
        *result_address = 2;
    }

    if (a != b) {
        *result_address = 1;
    } else {
        *result_address = 2;
    }

    if (a == b) {
        *result_address = 1;
    } else {
        *result_address = 2;
    }

    if (a <= b) {
        *result_address = 1;
    } else {
        *result_address = 2;
    }

    if (a > b) {
        *result_address = 1;
    } else {
        *result_address = 2;
    }
}
