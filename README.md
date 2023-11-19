# RISC-V single cycle processor in SystemVerilog
Available at https://github.com/Rutherther/verilog-riscv-semestral-project

This repository contains RISC-V processor written in SystemVerilog.

## Architecture

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
