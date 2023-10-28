module program_memory
(
  input [WIDTH - 1:0] addr,
  output [31:0] instruction
);
  parameter WIDTH = 12;
  parameter MEM_SIZE = 1 << (WIDTH - 2) - 1;

  reg [31:0] imem[0:MEM_SIZE];

  initial $readmemh("memfile.dat", imem);

  assign instruction = imem[addr[WIDTH - 1:2]];

endmodule;
