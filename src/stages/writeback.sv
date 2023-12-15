import cpu_types::*;

module writeback(

  input         clk,

  output [4:0]  reg_a_write,
  output        reg_we,
  output [31:0] reg_write,

  input         stage_status_t stage_in
);
  assign reg_a_write = stage_in.data.address;
  assign reg_we = stage_in.valid && stage_in.data.valid && stage_in.instruction.reg_we; // stage_in.data.address != 0
  assign reg_write = stage_in.data.data;
endmodule
