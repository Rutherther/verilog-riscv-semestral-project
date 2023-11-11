.global _start

.text
_start:
    addi sp, x0, 1020
    call main
loop:
    ebreak
    j loop
