module register_file(clk, a1, a2, a3, we3, wd3, rd1, rd2);

  input clk;
  input [4:0] a1;
  input [4:0] a2;
  input [4:0] a3;

  input       we3; // write enable
  input [31:0] wd3; // write data

  output [31:0] rd1;
  output [31:0] rd2;

  reg [31:0]    gprs [32];

  wire          clk;

  always_comb begin
    if (a1 == 5'b0)
      rd1 = gprs[a1];
    else
      rd1 = 32'b0;
  end

  always_comb begin
    if (a2 == 5'b0)
      rd2 = gprs[a2];
    else
      rd2 = 32'b0;
  end

  always_ff @(posedge clk) begin
    if (we3 && a3 != 5'b0)
      gprs[a3] <= wd3;
  end

endmodule
//
