import sys
import subprocess

sys.path.append('../')

from test_types import *
from pathlib import Path

def find_tests(groups_dir: Path, programs_dir: Path, out_dir: Path, filter_group_name: str|None, filter_test_name: str|None) -> list[TestGroup]:
    group_names: list[Path] = []
    if filter_group_name is None:
        group_names = [f for f in groups_dir.iterdir() if f.is_dir()]
    else:
        group_names = [groups_dir / filter_group_name]

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
        if filter_test_name is None:
            test_names = [f.name[:-len("-input.dat")] for f in group_dir.iterdir() if f.is_file() and f.name.endswith("-input.dat")]
        else:
            test_names = [filter_test_name]

        for test_name in test_names:
            test = Test(
                group,
                test_name,
                group_dir / f"{test_name}-input.dat",
                out_dir / f"{test_name}-output.dat",
                group_dir / f"{test_name}-expected.dat",
                out_dir / f"{test_name}-registers.dat",
            )

            if not test.memory_in_file.exists() or not test.memory_exp_file.exists():
                print("could not find both input and expected")
                continue

            tests.append(test)

        groups.append(group)


    return groups

def compile_program(make_dir: Path, test: Test) -> bool:
    group = test.group
    return subprocess.run(
        ["make", "-C", make_dir, group.dat_test_file.relative_to(make_dir)],
        stdout = subprocess.DEVNULL,
        stderr = subprocess.DEVNULL,
    ) == 0
