# RISC-V single cycle processor in SystemVerilog
Available at https://github.com/Rutherther/verilog-riscv-semestral-project

This repository contains RISC-V processor written in SystemVerilog.
It contains both singlecycle and pipelined version.
Classic RISC pipeline is utilized.

## Architecture
The singlecycle version is located in `src/cpu_singlecycle.sv`.
The pipelined version is in `src/cpu.sv`.

There are five stages in the pipelined version
- Fetch (fetches instruction from memory)
- Decode (decodes the fetched instruction, performs jumps, gets data from forwarder)
- Execute (alu)
- Memory access (loads, stores)
- Writeback (stores data in registers)

There are forwards whenever possible for data dependencies.
The forward is realized inside of the decode stage
that will supply arguments to the execute stage.
If there is a read from memory, there has to be a stall,
the pipeline can stall. The stalling is implemented using
ready flags in each of the stages. It is thus possible to easily
implement a stage that would block for multiple cycles
instead of producing valid data every cycle.
For now, all of the stages take one cycle to produce valid data.

The forwarding is done by keeping address and data known in each stage
inside of the status.data. Outputs of execute, memory access, and
input of writeback are used for forwarding. It would be possible to
skip the writeback forwarding if instead the register file outputted data
to be written instead of the contents of the register until it's actually
written to. I am afraid this could cause other issues, hence I chose forwarding instead.

All stages have valid and ready flags.

Ready flag is used for stalling. If a stage is not ready, there cannot
be data going into it, and the pipeline before that has to be stopped,
including program counter changes. This is used for stalling when waiting for a read
out of the memory, but could also be used for making the execute stage more complex,
ie. making it work multiple cycles instead of a one. It should also be possible to implement
reads that are not aligned, by reading from two consequent positions in the memory in two cycles.

Valid flag is for "killing" data that cannot be valid. 
It's utilized when stalling - data from decode are not
valid in that case. When stalling, both valid and ready should be 0.

## Requirements
- make
- verilator
- riscv32-unknown-elf toolchain (binutils, gcc)
- python3

There is a flake file for dev shell with all required dependencies
including gtkwave for viewing vcd files.

## Testing
There are two separate testing mechanisms used,
one is using Verilog testbenches. These testbenches
are not automatically evaluated, but meant for observation
of waves.

Then there are ISA tests, official ones and few custom tests
as well. These may be ran from Python script and validate correct
functionality automatically.

### Verilog testbenches
All testbenches are located in `testbench/` folder.
These testbenches do not assert anything by themselves.
They pass simple arguments to the modules.

#### Individual modules
To run a module `$tb_module` (produce wave file),
use `make ./waves/$tb_module.vcd`.
To show this file, run
`make show MODULE=$tb_module`

#### Running programs
There is a special testbench for running programs
called `tb_cpu_program`.
It is used in the ISA tests as well.

To run a program, use `make run_program`.
By default, program for finding gcd will be ran,
with zeros in memory. (it expects
the numbers in memory, so it won't do much)

The target expects some arguments, namely
- `PROGRAM` - name of the program to run
- `MEMORY_LOAD` - path to the file to load memory from. Expected format is Verilog hex format. Do note that ram consists of 32 bit elements.
- `MEMORY_WRITE` - path to the file to write memory to. By default `out/program_$PROGRAM_memory_out.dat`, so doesn't have to be changed

For example, `make run_program PROGRAM=gcd MEMORY_LOAD=tests/custom/gcd/1071-462-21-input.dat`.
This will run gcd program with 1071 and 462 as arguments. Expected output is 21.
At the end of the program, registers are dumped to stdout. The value is in register 14 as well
as in the memory on address zero.

The program is expected to be at `programs/$PROGRAM.c`.
It is expected that it has a main function, no arguments are passed to main.
Main will be called from `programs/start.S`.

### Compiling C programs
Programs are compiled automatically when running
programs or tests.

To produce an object file for $program,
use `make ./programs/bin/start-$program.o`.
The file produced is the C program file linked with `./programs/start.S`
This file might be used for `objdump`.
There is make target for showing objdumps
`make objdump PROGRAM=$program`.

To produce elf file, use `make ./programs/bin/$program.bin`.
To produce a file that may be loaded from verilog with `readmemh`,
use `make ./programs/bin/$program.dat`.

### ISA tests
ISA tests are documented in [tests/README.md](tests/README.md)
