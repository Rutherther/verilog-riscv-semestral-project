#!/usr/bin/env python3

import argparse
import sys
import subprocess
import re
from pathlib import Path
from dataclasses import dataclass

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class Test:
    pass

@dataclass
class TestGroup:
    tests: list[Test]
    directory: Path
    name: str
    c_test_file: Path # The C file to compile and use for this test
    dat_test_file: Path # The C file to compile and use for this test

    def __str__(self):
        return self.name

@dataclass
class Test:
    group: TestGroup
    name: str

    input_file: Path
    output_file: Path
    expected_file: Path

    def __str__(self):
        return f"{self.group.name}.{self.name}"

@dataclass
class Validation:
    test: Test
    expected: list[str]
    actual: list[str]
    matches: bool

def find_tests(groups_dir: Path, programs_dir: Path, out_dir: Path, group_name: str|None, test_name: str|None) -> list[TestGroup]:
    group_names: list[Path] = []
    if group_name is None:
        group_names = [f for f in groups_dir.iterdir() if f.is_dir()]
    else:
        group_names = [groups_dir / group_name]

    groups: list[TestGroup] = []
    for group_dir in group_names:
        tests: list[Test] = []
        group = TestGroup(
            tests = tests,
            directory = group_dir,
            name = group_dir.name,
            c_test_file = programs_dir / f"{group_dir.name}.c",
            dat_test_file = programs_dir / "bin" / f"{group_dir.name}.dat",
        )

        test_names = []
        if test_name is None:
            test_names = [f.name[:-len("-input.dat")] for f in group_dir.iterdir() if f.is_file() and f.name.endswith("-input.dat")]
        else:
            test_names = [test_name]

        for test_name in test_names:
            test = Test(
                group,
                test_name,
                group_dir / f"{test_name}-input.dat",
                out_dir / f"{test_name}-output.dat",
                group_dir / f"{test_name}-expected.dat",
            )

            if not test.input_file.exists() or not test.expected_file.exists():
                continue

            tests.append(test)

        groups.append(group)


    return groups

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

def compile_program(make_dir: Path, group: TestGroup) -> bool:
    return subprocess.run(
        ["make", "-C", make_dir, group.dat_test_file.relative_to(make_dir)],
        stdout = subprocess.DEVNULL,
        stderr = subprocess.DEVNULL,
    ) == 0

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

test_groups: list[TestGroup] = find_tests(groups_dir, programs_dir, out_dir, group_name, test_name)

# Official
# TODO

# Custom
if args.command == "list":
    print("Found these tests:")
    for group in test_groups:
        for test in group.tests:
            print(f"  {test}")
    sys.exit(0)

for group in test_groups:
    compile_program(project_dir, group)
    for test in group.tests:
        compile_test(project_dir, here / "comp_list.lst", out_dir, test)
        run_test(out_dir, test)

        validation = validate_test(test)

        if validation.matches:
            print(f"{test.group.name}.{test.name} {bcolors.OKGREEN}passed{bcolors.ENDC}")
        else:
            print(f"{test.group.name}.{test.name} {bcolors.FAIL}failed{bcolors.ENDC}")
            print(f"  Got {validation.actual}. Expected {validation.expected}")
