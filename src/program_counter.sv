// + 4 normally
// or if should jump, jump to given address (either pc + imm or rs1 + imm)

module program_counter(
  input                    clk,
  input                    rst_n,
  input [WIDTH - 1:0]      pc_next,
  output reg [WIDTH - 1:0] pc
);
  parameter WIDTH = 12;

  always_ff @ (posedge clk)
    if (rst_n == 1'b0)
      pc <= 0;
    else
      pc <= pc_next;

endmodule
