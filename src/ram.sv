module ram (
  input         clk, we,
  input [31:0]  a, wd,
  output [31:0] rd);

  reg [31:0]    RAM[0:127];

  assign rd = RAM[a[8:2]]; // word aligned

  always @(posedge clk)
    if(we) RAM[a[8:2]] <= wd;

endmodule
