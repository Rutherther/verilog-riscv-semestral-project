import cpu_types::*;

module decode(
  input        clk,

  input        forwarding_data_status_t data_in_pipeline,

  output [4:0] reg_a_1,
  output [4:0] reg_a_2,
  input [31:0] reg_rs1,
  input [31:0] reg_rs2,

  input        flush,

  input        stage_status_t stage_in,
  output       stage_status_t stage_out
);

  wire [2:0] alu_op;
  wire       alu_add_one;
  wire       alu_negate;
  wire       alu_sign;

  wire [4:0]  reg_rd;
  wire        reg_we;

  alu_1_source_t alu_1_src;
  alu_2_source_t alu_2_src;

  wire        stall_1, stall_2;
  wire [31:0] forwarded_reg_rs1, forwarded_reg_rs2;

  wire        memory_we;

  assign stage_out.data.target = reg_we && !stalling ? reg_rd : 0;
  assign stage_out.data.valid = 0; // the data cannot be valid at this point;

  assign stage_out.pc = stage_in.pc;
  assign stage_out.pc_plus_4 = stage_in.pc_plus_4;

  assign stage_out.instruction.reg_we = reg_we;

  assign stage_out.reg_rs1 = forwarded_reg_rs1;
  assign stage_out.reg_rs2 = forwarded_reg_rs2;

  assign stage_out.instruction.memory_we = memory_we;

  control_unit control_unit_inst(
    .instruction(stage_in.instruction.instruction),

    .ebreak(stage_out.instruction.ebreak),

    .immediate(stage_out.instruction.immediate),

    .alu_op(stage_out.instruction.alu_op),
    .alu_add_one(stage_out.instruction.alu_add_one),
    .alu_negate(stage_out.instruction.alu_negate),
    .alu_sign(stage_out.instruction.alu_sign),

    .memory_mask(stage_out.instruction.memory_mask),
    .memory_sign_extension(stage_out.instruction.memory_sign_extension),

    .memory_we(memory_we),

    .jump_instruction(stage_out.instruction.jump_instruction),
    .jump_negate_zero(stage_out.instruction.jump_negate_zero),

    .pc_src(stage_out.instruction.pc_src),
    .alu_src_1(stage_out.instruction.alu_1_src),
    .alu_src_2(stage_out.instruction.alu_2_src),
    .reg_rd_src(stage_out.instruction.reg_rd_src),

    .reg_rs1(reg_a_1),
    .reg_rs2(reg_a_2),
    .reg_rd(reg_rd),
    .reg_we(reg_we)
  );

  forwarder forwarder_a_inst(
    .clk(clk),
    .read_address(reg_a_1),
    .register_file_data(reg_rs1),
    .data_in_pipeline(data_in_pipeline),
    .stall(stall_1),
    .forwarding(),
    .data(forwarded_reg_rs1)
  );

  forwarder forwarder_b_inst(
    .clk(clk),
    .read_address(reg_a_2),
    .register_file_data(reg_rs2),
    .data_in_pipeline(data_in_pipeline),
    .stall(stall_2),
    .forwarding(),
    .data(forwarded_reg_rs2)
  );

  // stalling logic
  //   if should use reg_rs1 => wait until stall_1 == 0
  //   if should use reg_rs2 => wait until stall_2 == 0
  wire uses_reg_rs1, uses_reg_rs2;
  assign uses_reg_rs1 = (alu_1_src == REG_FILE_RS1);
  assign uses_reg_rs2 = (alu_2_src == REG_FILE_RS2) || memory_we;

  wire stalling;
  assign stalling = (uses_reg_rs1 && stall_1) || (uses_reg_rs2 && stall_2);
  assign stage_out.valid = !flush && !stalling && stage_in.valid;
  assign stage_out.ready = !stalling || !stage_in.valid;
    // if input is not valid, do not care about stalling...
endmodule
