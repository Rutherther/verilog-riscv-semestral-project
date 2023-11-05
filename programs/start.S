.global _start

.text
_start:
    addi sp, x0, 124
    call main
_loop:
    ebreak
    j _loop
