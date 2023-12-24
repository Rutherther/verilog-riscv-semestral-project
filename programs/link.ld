OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")

MEMORY
{
    ram : ORIGIN = 0x00000000, LENGTH = 1K - 1
}

PROVIDE( __global_pointer$ = 0x0 );

SECTIONS
{
	.text : {
        *(.text._start);
        *(.text);
        *(.text.*);
    } > ram
    .bss : {
        *(.bss)
        *(COMMON)
        *(.bss.*)
    } > ram
}
