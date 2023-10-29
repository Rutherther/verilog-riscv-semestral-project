MEMORY
{
    ram : ORIGIN = 0x00000000, LENGTH = 1K - 1
}

SECTIONS
{
	.text = 0x0;
    .bss : {
        __bss_start = .;
        *(.bss)
        *(COMMON)
        __bss_end = .;
    } > ram
    .stack : {
        __stack_start = .;
        *(.stack)
        __stack_end = .;
    } > ram
}

