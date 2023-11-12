
int main()
{
    char *load_address = 0;
    int *result_address = 0;

    char a = *load_address;
    char b = *(load_address + 1);
    char c = *(load_address + 2);
    char d = *(load_address + 3);

    *(result_address + 3) = a;
    *(result_address + 2) = b;
    *(result_address + 1) = c;
    *(result_address + 0) = d;

    char* result_bytes = (char*)(result_address + 4);

    *(result_bytes + 0) = a;
    *(result_bytes + 1) = b;
    *(result_bytes + 2) = c;
    *(result_bytes + 3) = d;
}
