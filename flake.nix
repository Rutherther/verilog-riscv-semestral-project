{
  description = "Verilog, RISC-V, Python environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }: let
  in flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            riscPkgs = import nixpkgs {
              inherit system;
              crossSystem.config = "riscv32-none-elf";
            };
        in rec {
          devShells.default = pkgs.mkShell {
            name = "pap-processor-singlecycle";

            packages = [
              # verilog simulation
              pkgs.verilog
              pkgs.verilator

              # wave viewer
              pkgs.gtkwave

              # riscv toolchain
              # building c, assembly
              riscPkgs.buildPackages.binutils
              riscPkgs.buildPackages.gcc

              # for testing
              pkgs.python3

              # lsp
              pkgs.svls
              pkgs.pyright
            ];
          };
        }
      );
}
