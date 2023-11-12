#!/usr/bin/env python3

import sys
import argparse
import sys
import subprocess
import re
import shutil
from pathlib import Path

from test_types import bcolors, TestGroup, Test, Validation

sys.path.append('./custom')
sys.path.append('./official')

import custom_tests
import official_tests

PROGRAM_FILE = "program.dat"
MEMORY_WRITE_FILE = "memory_out.dat"
MEMORY_LOAD_FILE = "memory_in.dat"
REGISTER_FILE = "register_dump.dat"
SIMULATE_EXE = "simulate_cpu_program"
TRACE_FILE = "trace.vcd"

def validate_test(test: Test) -> Validation:
    expected = test.memory_exp_file.read_text()
    actual = test.memory_out_file.read_text()

    expected_arr = list(filter(lambda word: word != "", re.split(r"[\n ]+", expected)))
    actual_arr = re.split(r"[\n ]+", actual)
    # trim leading
    actual_arr = actual_arr[:len(expected_arr)]

    return Validation(
        test = test,
        expected = expected_arr,
        actual = actual_arr,
        matches = (actual_arr == expected_arr)
    )

def print_registers(test: Test):
    reg_names = [ "ze", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"]
    values = ["00000000"] + re.split(r"[\n ]+", test.register_dump_file.read_text())

    print("  ", end = '')
    for i, (name, value) in enumerate(zip(reg_names, values)):
        print(f"{name}: 0x{value}", end = '\n  ' if i % 4 == 3 else ' ')

def compile(project_dir: Path, comp_list: Path, out_dir: Path, trace: bool) -> bool:
    program_path = out_dir / PROGRAM_FILE
    memory_load_file = out_dir / MEMORY_LOAD_FILE
    memory_write_file = out_dir / MEMORY_WRITE_FILE
    register_file = out_dir / REGISTER_FILE
    trace_file = out_dir / TRACE_FILE

    generics = {
        'CPU_PROGRAM_PATH': f"\\\"{program_path}\\\"",
        'TRACE_FILE_PATH': f"\\\"{trace_file}\\\"",
        'REGISTER_DUMP_FILE': 1,
        'REGISTER_DUMP_FILE_PATH': f"\\\"{register_file}\\\"",
        'MEMORY_LOAD_FILE': 1,
        'MEMORY_LOAD_FILE_PATH': f"\\\"{memory_load_file}\\\"",
        'MEMORY_WRITE_FILE': 1,
        'MEMORY_WRITE_FILE_PATH': f"\\\"{memory_write_file}\\\"",
    }

    params = []
    for gname, gvalue in generics.items():
        params.append(f"-G{gname}={gvalue}")

    params.append("--binary")
    params.append("--Mdir")
    params.append(f"{out_dir}")
    params.append("-o")
    params.append(SIMULATE_EXE)
    params.append("--top")
    params.append("tb_cpu_program")

    if trace:
        params.append("--trace")
        params.append("--trace-max-array 4096")

    for line in comp_list.read_text().split('\n'):
        if line != "":
            params.append(f"{project_dir / line}")

    return subprocess.run(
        str.join(" ", [ "verilator" ] + params),
        stdout = subprocess.DEVNULL,
        shell = True,
        check = True,
    ).returncode == 0

def run_test(out_dir: Path, test: Test) -> bool:
    program_path = out_dir / PROGRAM_FILE
    memory_load_file = out_dir / MEMORY_LOAD_FILE
    memory_write_file = out_dir / MEMORY_WRITE_FILE
    register_file = out_dir / REGISTER_FILE

    shutil.copy(test.memory_in_file, memory_load_file)
    shutil.copy(test.group.dat_test_file, program_path)

    subprocess.run(
        [out_dir / SIMULATE_EXE],
        stdout = subprocess.DEVNULL,
        shell = True,
        check = True,
    )

    shutil.copy(memory_write_file, test.memory_out_file)
    shutil.copy(register_file, test.register_dump_file)

    return True

def filter_tests(groups: list[TestGroup], group_name: str|None, test_name: str|None) -> list[TestGroup]:
    if group_name is not None:
        groups = list(filter(lambda g: g.name == group_name, groups))

    if test_name is not None:
        for group in groups:
            group.tests = list(filter(lambda t: t.name == test_name, group.tests))

    return groups

# Program
parser = argparse.ArgumentParser("Test simple RISC-V processor written in Verilog.")
parser.add_argument(
    "command",
    choices = [ "run", "list"],
    help = "What to do. Either run the test, or run testcases based on filter."
)
parser.add_argument(
    "-f",
    "--filter",
    type = str,
    nargs = "*",
    help = "Filter, should be in group.test format."
)
parser.add_argument(
    "-t",
    "--type",
    choices = ["custom", "official"],
    default = "custom",
    help = "Type of the testcases, either custom testcases or official riscv selftests.",
)
parser.add_argument(
    "--trace",
    action = "store_true",
    help = "Trace, produce vcd file",
)
parser.add_argument(
    "--print-registers",
    action = "store_true",
    help = "Trace, produce vcd file",
)
# parser.add_argument(
#     "--print-memory",
#     type = int,
#     help = "Trace, produce vcd file",
# )

args = parser.parse_args()

here = Path(__file__).parent
project_dir = here.parent
programs_dir = project_dir / "programs"
out_dir = here / "out"
groups_dir = here / "custom"

# TODO support multiple filters
filt = args.filter[0].split('.') if args.filter is not None and len(args.filter) > 0 else [None, None]

group_name = filt[0]
test_name = None
if len(filt) >= 2:
    test_name = filt[1]

compile(project_dir, here / "comp_list.lst", out_dir, args.trace)

if args.type == "custom":
    test_groups: list[TestGroup] = custom_tests.find_tests(
        groups_dir, programs_dir, out_dir, group_name, test_name
    )
    compile_program = custom_tests.compile_program
else: # official
    test_groups: list[TestGroup] = official_tests.find_tests(
        here / "official" / "out",
    )
    test_groups = filter_tests(test_groups, group_name, test_name)
    compile_program = official_tests.compile_program

if args.command == "list":
    print("Found these tests:")
    for group in test_groups:
        for test in group.tests:
            print(f"  {test}")
    sys.exit(0)

for group in test_groups:
    for test in group.tests:
        compile_program(project_dir, test)
        run_test(out_dir, test)

        validation = validate_test(test)

        if validation.matches:
            print(f"{test.group.name}.{test.name} {bcolors.OKGREEN}passed{bcolors.ENDC}")
        else:
            print(f"{test.group.name}.{test.name} {bcolors.FAIL}failed{bcolors.ENDC}")
            print(f"  Got {validation.actual}. Expected {validation.expected}")

        if args.print_registers:
            print_registers(test)
