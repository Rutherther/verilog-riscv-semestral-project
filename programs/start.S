.global _start

.text
_start:
    addi sp, x0, 127
    call main
_loop:
    j _loop
