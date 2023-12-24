import cpu_types::*;

module execute(
  input             clk,

  output            jump,
  output reg [31:0] jump_pc,

  input             stage_status_t stage_in,
  output            stage_status_t stage_out
);
  reg [31:0]  alu_1, alu_2;
  wire [31:0] alu_out;
  wire        branch_taken;
  wire        alu_zero;

  assign stage_out.instruction = stage_in.instruction;
  assign stage_out.pc = stage_in.pc;
  assign stage_out.pc_plus_4 = stage_in.pc_plus_4;
  assign stage_out.reg_rs1 = stage_in.reg_rs1;
  assign stage_out.reg_rs2 = stage_in.reg_rs2;

  assign stage_out.data.target = stage_in.valid ? stage_in.data.target : 0;
  assign stage_out.data.value = stage_in.instruction.reg_rd_src == RD_PC_PLUS ? stage_in.pc_plus_4 : alu_out;
  assign stage_out.data.valid = stage_in.valid && (stage_in.instruction.reg_rd_src != RD_MEMORY);

  assign stage_out.valid = stage_in.valid;
  assign stage_out.ready = 1;

  assign jump = stage_in.valid && (branch_taken || stage_in.instruction.pc_src == PC_ALU);

  assign branch_taken = stage_in.instruction.jump_instruction && (alu_zero ^ stage_in.instruction.jump_negate_zero);
  always_comb begin
    jump_pc = 32'bX;
    case (stage_in.instruction.pc_src)
      PC_PLUS : begin
        if (branch_taken)
          jump_pc = stage_in.pc + stage_in.instruction.immediate;
      end
      PC_ALU : jump_pc = alu_out;
    endcase
  end

  // alu source 1
  always_comb begin
    case (stage_in.instruction.alu_1_src)
      REG_FILE_RS1 : alu_1 = stage_in.reg_rs1;
      PC : alu_1 = stage_in.pc;
    endcase
  end

  // alu source 2
  always_comb begin
    case (stage_in.instruction.alu_2_src)
      REG_FILE_RS2 : alu_2 = stage_in.reg_rs2;
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
    .zero_flag(alu_zero)
  );
endmodule
