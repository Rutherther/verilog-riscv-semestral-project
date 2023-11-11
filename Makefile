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

./waves/cpu_program_%.vcd: ./obj_dir/Vtb_cpu_program_% ./waves
	$<

./waves/%.vcd: ./obj_dir/V% ./waves
	$<

./waves:
	mkdir -p $@

# These are runtime dependencies, not build time dependencies.
.PRECIOUS: ./programs/bin/%.dat ./programs/bin/%.bin

./obj_dir/Vtb_cpu_program_%: ./programs/bin/%.dat testbench/tb_cpu_program.sv src/*.sv
	verilator --binary --trace \
		-GCPU_PROGRAM_PATH="\"$<\"" \
		-GCPU_PROGRAM_NAME="\"$(notdir $(basename $<))\"" \
		--trace-max-array 512 \
		src/cpu_types.sv \
		src/instruction_decoder.sv \
		src/control_unit.sv \
		src/alu.sv \
		src/register_file.sv \
		src/program_counter.sv \
		src/ram.sv \
		src/cpu.sv \
		src/file_program_memory.sv \
		testbench/tb_cpu_program.sv \
		-o Vtb_cpu_program_$(notdir $(basename $<)) \
		--top tb_cpu_program

./obj_dir/Vtb_%: testbench/tb_%.sv src/*.sv
	verilator --binary --trace \
		--trace-max-array 512 \
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

objdump/%: ./programs/bin/start-%.o
	$(OBJDUMP) -d -M no-aliases $<

.PHONY: clean
clean:
	rm -rf ./waves
	rm -rf ./programs/bin
	rm -rf ./obj_dir
	rm -rf waveform.vcd
