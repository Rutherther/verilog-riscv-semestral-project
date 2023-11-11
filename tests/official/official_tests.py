import sys
import subprocess

sys.path.append('../')

from test_types import *
from pathlib import Path

def find_tests(out_dir: Path) -> list[TestGroup]:
    here = Path(__file__).parent
    result = subprocess.run(
        [ "make", "-C", here, "-s", "list" ],
        check = True,
        capture_output = True,
    )

    test_names = result.stdout.decode("utf-8").strip().split(' ')

    groups = []
    for test_name in test_names:
        tests = []
        group = TestGroup(
            tests = tests,
            directory = here,
            name = "rv32ui",
            c_test_file = out_dir / f"rv32ui_{test_name}.c",
            dat_test_file = out_dir / f"rv32ui_{test_name}.dat",
        )
        tests.append(Test(
            group = group,
            name = test_name,
            input_file = here / "input.dat",
            output_file = out_dir / f"{group.name}-output.dat",
            expected_file = here / "expected.dat",
        ))

        groups.append(group)

    return groups

def compile_program(make_dir: Path, test: Test) -> bool:
    return subprocess.run(
        ["make", "-C", Path(__file__).parent, f"./out/{test.group.name}_{test.name}.dat"],
        check = True,
        stdout = subprocess.DEVNULL,
        stderr = subprocess.DEVNULL,
    ) == 0
