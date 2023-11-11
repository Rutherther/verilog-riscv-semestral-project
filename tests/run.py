#!/usr/bin/env python3

import sys
import argparse
import sys
import subprocess
import re
from pathlib import Path

from test_types import bcolors, TestGroup, Test, Validation

sys.path.append('./custom')
sys.path.append('./official')

import custom_tests
import official_tests

def validate_test(test: Test) -> Validation:
    expected = test.expected_file.read_text()
    actual = test.output_file.read_text()

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

def compile_test(project_dir: Path, comp_list: Path, out_dir: Path, test: Test) -> bool:
    generics = {
        'CPU_PROGRAM_PATH': f"\\\"{test.group.dat_test_file}\\\"",
        'CPU_PROGRAM_NAME': f"\\\"{test.group.dat_test_file.stem}\\\"",
        'MEMORY_LOAD_FILE': 1,
        'MEMORY_LOAD_FILE_PATH': f"\\\"{test.input_file}\\\"",
        'MEMORY_WRITE_FILE': 1,
        'MEMORY_WRITE_FILE_PATH': f"\\\"{test.output_file}\\\"",
    }

    params = []
    for gname, gvalue in generics.items():
        params.append(f"-G{gname}={gvalue}")

    params.append("--binary")
    params.append("--Mdir")
    params.append(f"{out_dir}")
    params.append("-o")
    params.append(f"test_{test.group.name}_{test.name}")
    params.append("--top")
    params.append("tb_cpu_program")

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
    return subprocess.run(
        [out_dir / f"test_{test.group.name}_{test.name}"],
        stdout = subprocess.DEVNULL,
        shell = True,
        check = True,
    ).returncode == 0

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

args = parser.parse_args()

here = Path(__file__).parent
project_dir = here.parent
programs_dir = project_dir / "programs"
out_dir = here / "out"
groups_dir = here / "custom"

# TODO support multiple tests
group_name, test_name = args.filter[0].split('.') if args.filter is not None else (None, None)

if args.type == "custom":
    test_groups: list[TestGroup] = custom_tests.find_tests(
        groups_dir, programs_dir, out_dir, group_name, test_name
    )
    if args.command == "list":
        print("Found these tests:")
        for group in test_groups:
            for test in group.tests:
                print(f"  {test}")
        sys.exit(0)

    for group in test_groups:
        custom_tests.compile_program(project_dir, group)
        for test in group.tests:
            compile_test(project_dir, here / "comp_list.lst", out_dir, test)
            run_test(out_dir, test)

            validation = validate_test(test)

            if validation.matches:
                print(f"{test.group.name}.{test.name} {bcolors.OKGREEN}passed{bcolors.ENDC}")
            else:
                print(f"{test.group.name}.{test.name} {bcolors.FAIL}failed{bcolors.ENDC}")
                print(f"  Got {validation.actual}. Expected {validation.expected}")
else: # official
    test_groups: list[TestGroup] = official_tests.find_tests(
        here / "official" / "out"
    )

    if args.command == "list":
        print("Found these tests:")
        for group in test_groups:
            for test in group.tests:
                print(f"  {test}")
        sys.exit(0)

    for group in test_groups:
        for test in group.tests:
            official_tests.compile_program(project_dir, test)
            compile_test(project_dir, here / "comp_list.lst", out_dir, test)
            run_test(out_dir, test)

            validation = validate_test(test)

            if validation.matches:
                print(f"{test.group.name}.{test.name} {bcolors.OKGREEN}passed{bcolors.ENDC}")
            else:
                print(f"{test.group.name}.{test.name} {bcolors.FAIL}failed{bcolors.ENDC}")
                print(f"  Got {validation.actual}. Expected {validation.expected}")
