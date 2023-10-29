import cpu_types::*;

module ram (
  input         clk, we,
  input [31:0]  a, wd,
  input         memory_mask_t mask,
  output [31:0] rd);

  reg [4095:0]    RAM;

  assign rd = RAM[(a[11:0] * 8) +:32]; // word aligned

  always @(posedge clk)
    if(we) begin
      case(mask)
        MEM_BYTE: RAM[(a[11:0] * 8) +:8] <= wd[7:0];
        MEM_HALFWORD: RAM[(a[11:0] * 8) +:16] <= wd[15:0];
        MEM_WORD: RAM[(a[11:0] * 8) +:32] <= wd[31:0];
        default: ;
      endcase
    end

endmodule
