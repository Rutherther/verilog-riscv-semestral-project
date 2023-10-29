MODULE=tb_control_unit

## Verilog part
.PHONY:sim
sim: waveform.vcd

.PHONY:verilate
verilate: .stamp.verilate

.PHONY:build

build: obj_dir/V$(MODULE)

.PHONY:waves
show: ./waves/$(MODULE).vcd
	gtkwave ./waves/$(MODULE).vcd

./waves/%.vcd: ./obj_dir/V% ./waves
	$<

./waves:
	mkdir -p $@

./obj_dir/Vtb_%: testbench/tb_%.sv src/%.sv
	verilator --binary --trace \
		src/cpu_types.sv \
		src/instruction_decoder.sv \
		src/control_unit.sv \
		src/alu.sv \
		src/register_file.sv \
		src/program_counter.sv \
		src/ram.sv \
		src/cpu.sv \
		src/file_program_memory.sv \
		$< \
        --top $(notdir $(basename $<))

## C part
CFLAGS=-march=rv32i -mabi=ilp32 -O0 -c
ASFLAGS=-march=rv32i -mabi=ilp32
LDFLAGS=-Tprograms/link.ld

CC=riscv32-none-elf-gcc
AS=riscv32-none-elf-as
LD=riscv32-none-elf-ld
OBJDUMP=riscv32-none-elf-objdump
OBJCOPY=riscv32-none-elf-objcopy

./programs/bin:
	mkdir -p $@

./programs/bin/start.o: ./programs/start.S ./programs/bin
	$(AS) $(ASFLAGS) $< -o $@

./programs/bin/%.o: ./programs/%.c ./programs/bin
	$(CC) $(CFLAGS) $< -o $@

./programs/bin/start-%.o: ./programs/bin/start.o ./programs/bin/%.o
	$(LD) $(LDFLAGS) $^ -o $@

./programs/bin/%.bin: ./programs/bin/start-%.o
	$(OBJCOPY) $< -O binary $@

./programs/bin/%.dat: ./programs/bin/%.bin
	od $< -t x4 -A n > $@

objdump/%: ./programs/bin/%.bin
	$(OBJDUMP) -d -M no-aliases $<

.PHONY: clean
clean:
	rm -rf ./waves
	rm -rf ./programs/bin
	rm -rf ./obj_dir
	rm -rf waveform.vcd
