int main() {

    // 0x0F000000
    __asm__(" \
      addi x1, x0, 0x0F\n \
      sll x1, x1, 24\n    \
      addi x1, x1, 0x0A\n \
      sw x1, 1(x0)\n      \
      lw x2, 1(x0)\n      \
      nop\n               \
      nop\n               \
      ebreak\n            \
    ");
}
