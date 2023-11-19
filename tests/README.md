# RISC-V tests
Under the hood, the tests use `tb_cpu_program` Verilog testbench.

Python script called `run.py` is used for testing.
This will use makefiles under the hood,
one from the project root, and other from `tests/official` subdirectory.

## Test types
There are two types of tests,
official riscv tests that work by selftesting
the processor. That means that if there is a problem
with more instructions like branches, store words,
it's possible that the tests will pass even though
the processor is not working properly.

The other type are custom tests. These do not depend
on functionality of processor instructions.
There is just a few of these. For each program,
it's possible to specify different memory to load,
so multiple parameters are passed to the same program.

## Test success validation
To validate test success, memory is dumped to a file
at the end of the test - upon getting to ebreak instruction.
This memory is then validated against file with expected memory
values. The memory file format is Verilogs hex format.

Selftests are checked the same way, but upon success, on address
zero, there should be 0xAA. On fail, 0xFF.
Here are the macros used for test pass and fail
``` assembly
#define RVTEST_PASS                                                     \
        addi x1, zero, 0xAA;                                            \
        sw x1, 0(zero);                                                 \
        nop;                                                            \
        ebreak;

#define TESTNUM gp
#define RVTEST_FAIL                                                     \
        addi x1, zero, 0xFF;                                            \
        sw x1, 0(zero);                                                 \
        sw x1, 4(TESTNUM);                                              \
        nop;                                                            \
        ebreak;
```
These macros are defined in `tests/official/env/p/riscv_test.h`.

## Usage
To run the tests, `run.py` can be used.
By default, it will run the custom tests.

It must be supplied one of run or list subcommands.
To list all the tests, use `./run.py list`. To run the tests,
supply `./run.py run`.

Every test has a group. For custom tests the group specifies the program to run.
Name of the test specifies the arguments.
For official tests, there is only one group so far, `rv32ui`.

It's possible to filter one or more of the tests,
by using `--filter` flag. For example `./run.py run --filter gcd`
to run only tests from the gcd group. For running only one test
from the group, specify it after a dot. For example `./run.py --filter gcd.1071-462-21`.

```
usage: run.py [-h] [-f [FILTER ...]] [-t {custom,official}] [--trace] [--print-registers] {run,list}

Test simple RISC-V processor written in Verilog.

positional arguments:
  {run,list}            What to do. Either run the test, or run testcases based on filter.

options:
  -h, --help            show this help message and exit
  -f [FILTER ...], --filter [FILTER ...]
                        filter, should be in group.test format
  -t {custom,official}, --type {custom,official}
                        type of the testcases, either custom testcases or official riscv selftests
  --trace               trace, produce vcd file
  --print-registers     dump registers on ebreak to stdout
```

## Creating custom tests
To create a custom test, two things are needed.

First, a C program has to be made. This program is expected to be located in
`../programs/`. It should have a `main` function. This function will be called.
It should ideally load parameters from the beginning of the memory, and save
the result to the memory afterwards, again, at the beginning of the memory.

Second, arguments have to be specified. To do this, first create a directory
`custom/$program`. In this directory, files with parameters should be placed.
For each test, two files are needed, input memory and expected memory.

Name of the files should be `$test-input.dat` and `$test-expected.dat`.
They should be in Verilog hex format (input will be read by readmemh, expected
data will be compared against file written with writememh). Only first few
words have to be specified, no need to put in full memory image.

I have chosen to name the files by parameters passed in, every parameter
separated by a dash. And at the end, the expected result is listed.
For example, gcd.1071-462-21 will pass in 1071 and 462 as arguments
to the gcd program. The expected result (gcd(1071, 462)) is 21.

## Existing custom test programs (groups)
- gcd
  - Calculates gcd of two numbers
- branches
  - Tries all branch instructions
- memory_bytes
  - Tries to read and write bytes to memory
