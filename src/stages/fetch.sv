import cpu_types::*;

module fetch(
  input        clk,
  input [31:0] pc,
  input [31:0] mem_instruction,
  input        jump,

  output       stage_status_t stage_out
);
  assign stage_out.instruction.instruction = mem_instruction;
  assign stage_out.valid = !jump;
  assign stage_out.pc = pc;
  assign stage_out.ready = 1;
endmodule
