module register_file(clk, a1, a2, a3, we3, wd3, rd1, rd2);
  parameter WIDTH = 32;
  parameter ADDRESS_LENGTH = 5;
  parameter SIZE = 1 << ADDRESS_LENGTH;

  input clk;
  input [ADDRESS_LENGTH - 1:0] a1;
  input [ADDRESS_LENGTH - 1:0] a2;
  input [ADDRESS_LENGTH - 1:0] a3;

  input       we3; // write enable
  input [WIDTH - 1:0] wd3; // write data

  output reg [WIDTH - 1:0] rd1;
  output reg [WIDTH - 1:0] rd2;

  reg [WIDTH - 1:0]    gprs [SIZE];

  wire          clk;

  always_comb begin
    if (a1 == {ADDRESS_LENGTH{1'b0}})
      rd1 = gprs[a1];
    else
      rd1 = 32'b0;
  end

  always_comb begin
    if (a2 == {ADDRESS_LENGTH{1'b0}})
      rd2 = gprs[a2];
    else
      rd2 = 32'b0;
  end

  always_ff @(posedge clk) begin
    if (we3 && a3 != {ADDRESS_LENGTH{1'b0}})
      gprs[a3] <= wd3;
  end

endmodule
