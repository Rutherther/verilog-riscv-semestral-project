.globl main
.globl _start
.globl __start

.option norelax

.text

__start:
_start:
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    addi sp, x0, 1020
    addi a0, zero, 0
    addi a1, zero, 0
    call main
quit:
	addi    a0, zero, 0
	addi    a7, zero, 93  /* SYS_exit */
	ecall
loop:
    ebreak
    beq     zero, zero, loop

.bss

.end _start
