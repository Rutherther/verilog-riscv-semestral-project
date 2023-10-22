module register_file(clk, A1, A2, A3, WE3, WD3, RD1, RD2);

  input clk;
  input [4:0] A1;
  input [4:0] A2;
  input [4:0] A3;

  input       WE3; // write enable
  input [31:0] WD3; // write data

  output [31:0] RD1;
  output [31:0] RD2;

  reg [31:0]    gprs [32];

  wire          clk;

  assign RD1 = gprs[A1];
  assign RD2 = gprs[A2];

  always_ff @(posedge clk) begin
    if (WE3)
      gprs[A3] <= WD3;
  end

endmodule
//
