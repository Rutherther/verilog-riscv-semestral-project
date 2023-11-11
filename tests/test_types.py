from dataclasses import dataclass
from pathlib import Path

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
