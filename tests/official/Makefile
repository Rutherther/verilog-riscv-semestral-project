XLEN = 32
src_dir = .
isa_dir = ./riscv-tests/isa

CFLAGS=-march=rv32i -mabi=ilp32 -c

CC=riscv32-none-elf-gcc
LD=riscv32-none-elf-ld
OBJCOPY=riscv32-none-elf-objcopy

include ${isa_dir}/rv32ui/Makefrag

./out/rv32ui_%.o: ${isa_dir}/rv32ui/%.S ./out
	$(CC) $(CFLAGS) -I${isa_dir}/macros/scalar -I${src_dir}/env/p $< -o $@.out
	$(LD) -T${src_dir}/env/p/link.ld $@.out -o $@

./out/rv32ui_%.bin: ./out/rv32ui_%.o ./out
	$(OBJCOPY) $< -O binary $@

./out/rv32ui_%.dat: ./out/rv32ui_%.bin ./out
	od $< -t x4 -A n -v > $@

./out:
	mkdir $@

.PHONY: clean list
list:
	@echo ${rv32ui_sc_tests}

clean:
	rm -rf ./out
