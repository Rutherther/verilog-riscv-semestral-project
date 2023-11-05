import cpu_types::*;

module ram (
  input         clk, we,
  input [31:0]  a, wd,
  input [3:0]   write_byte_enable,
  output [31:0] rd);

  reg [31:0]      mask;
  reg [31:0]      memory[128];

  assign rd = memory[a[8:2]]; // word aligned

  always_comb begin
    mask = {
            {8{write_byte_enable[3]}},
            {8{write_byte_enable[2]}},
            {8{write_byte_enable[1]}},
            {8{write_byte_enable[0]}}
            };
  end

  always_ff @ (posedge clk)
    if(we)
      memory[a[8:2]] = (rd & ~mask) | (wd & mask);

endmodule
