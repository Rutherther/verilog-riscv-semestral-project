import cpu_types::*;

module execute(
  input clk,

  input stage_status_t stage_in,
  output stage_status_t stage_out
);
  reg [31:0] alu_1, alu_2;
  wire [31:0] alu_out;

  assign stage_out.instruction = stage_in.instruction;
  assign stage_out.pc = stage_in.pc;
  assign stage_out.reg_rd1 = stage_in.reg_rd1;
  assign stage_out.reg_rd2 = stage_in.reg_rd2;

  assign stage_out.data.address = stage_in.valid ? stage_in.data.address : 0;
  assign stage_out.data.data = stage_in.instruction.reg_rd_src == RD_PC_PLUS ? stage_in.pc + 4 : alu_out;
  assign stage_out.data.valid = stage_in.valid && (stage_in.instruction.reg_rd_src != RD_MEMORY);

  assign stage_out.valid = stage_in.valid;
  assign stage_out.ready = 1;

  // alu source 1
  always_comb begin
    case (stage_in.instruction.alu_1_src)
      REG_FILE_RS1 : alu_1 = stage_in.reg_rd1;
      PC : alu_1 = stage_in.pc;
    endcase
  end

  // alu source 2
  always_comb begin
    case (stage_in.instruction.alu_2_src)
      REG_FILE_RS2 : alu_2 = stage_in.reg_rd2;
      IMMEDIATE : alu_2 = stage_in.instruction.immediate;
    endcase
  end

  alu #(.WIDTH(32)) alu_inst(
    .a(alu_1),
    .b(alu_2),
    .out(alu_out),

    .op(stage_in.instruction.alu_op),
    .b_add_one(stage_in.instruction.alu_add_one),
    .b_negate(stage_in.instruction.alu_negate),
    .sign(stage_in.instruction.alu_sign),
    .zero_flag()
  );
endmodule
