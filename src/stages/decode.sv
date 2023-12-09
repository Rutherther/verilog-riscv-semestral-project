import cpu_types::*;

module decode(
  input         clk,

  input         forwarding_data_status_t data_in_pipeline,

  output [4:0]  reg_a_1,
  output [4:0]  reg_a_2,
  input [31:0]  reg_rd1,
  input [31:0]  reg_rd2,

  output        jump,
  output [31:0] pc_next,

  input         stage_status_t stage_in,
  output        stage_status_t stage_out
);

  parameter FORWARDING_STAGES = 3; // , execute(out), memory(out), writeback(in)

  wire [2:0] alu_op;
  wire       alu_add_one;
  wire       alu_negate;
  wire       alu_sign;

  wire [31:0] immediate;
  wire        jump_instruction, jump_negate_zero;
  wire        jump_taken;

  wire        pc_src;

  wire [4:0]  reg_rd;
  wire        reg_we;

  alu_1_source_t alu_1_src;
  alu_2_source_t alu_2_src;

  wire        stall_1, stall_2;
  wire [31:0] forwarded_reg_rd1, forwarded_reg_rd2;

  wire        memory_we;

  assign stage_out.data.address = reg_we && !stalling ? reg_rd : 0;

  assign stage_out.pc = stage_in.pc;

  assign stage_out.instruction.reg_we = reg_we;

  assign stage_out.reg_rd1 = forwarded_reg_rd1;
  assign stage_out.reg_rd2 = forwarded_reg_rd2;

  assign stage_out.instruction.immediate = immediate;
  assign stage_out.instruction.alu_1_src = alu_1_src;
  assign stage_out.instruction.alu_2_src = alu_2_src;
  assign stage_out.instruction.alu_op = alu_op;
  assign stage_out.instruction.alu_add_one = alu_add_one;
  assign stage_out.instruction.alu_negate = alu_negate;
  assign stage_out.instruction.alu_sign = alu_sign;
  assign stage_out.instruction.memory_we = memory_we;

  control_unit control_unit_inst(
    .instruction(stage_in.instruction.instruction),

    .ebreak(stage_out.instruction.ebreak),

    .immediate(immediate),

    .alu_op(alu_op),
    .alu_add_one(alu_add_one),
    .alu_negate(alu_negate),
    .alu_sign(alu_sign),

    .memory_mask(stage_out.instruction.memory_mask),
    .memory_sign_extension(stage_out.instruction.memory_sign_extension),

    .memory_we(memory_we),

    .jump_instruction(jump_instruction),
    .jump_negate_zero(jump_negate_zero),

    .pc_src(pc_src),
    .alu_src_1(alu_1_src),
    .alu_src_2(alu_2_src),
    .reg_rd_src(stage_out.instruction.reg_rd_src),

    .reg_rs1(reg_a_1),
    .reg_rs2(reg_a_2),
    .reg_rd(reg_rd),
    .reg_we(reg_we)
  );

  forwarder forwarder_a_inst(
    .clk(clk),
    .read_address(reg_a_1),
    .register_file_data(reg_rd1),
    .data_in_pipeline(data_in_pipeline),
    .stall(stall_1),
    .data(forwarded_reg_rd1)
  );

  forwarder forwarder_b_inst(
    .clk(clk),
    .read_address(reg_a_2),
    .register_file_data(reg_rd2),
    .data_in_pipeline(data_in_pipeline),
    .stall(stall_2),
    .data(forwarded_reg_rd2)
  );

  // alu source 1
  reg [31:0] alu_1, alu_2;
  always_comb begin
    case (alu_1_src)
      REG_FILE_RS1 : alu_1 = forwarded_reg_rd1;
      PC : alu_1 = stage_in.pc;
    endcase
  end

  // alu source 2
  always_comb begin
    case (alu_2_src)
      REG_FILE_RS2 : alu_2 = forwarded_reg_rd2;
      IMMEDIATE : alu_2 = immediate;
    endcase
  end

  // // jumping logic
  wire jumps_jumping;
  jumps jumps_inst(
    .pc(stage_in.pc),
    .immediate(immediate),
    .pc_src(pc_src),
    .jump_negate_zero(jump_negate_zero),
    .jump_instruction(jump_instruction),

    .alu_op(alu_op),
    .alu_a(alu_1),
    .alu_b(alu_2),
    .alu_sign(alu_sign),
    .alu_b_add_one(alu_add_one),
    .alu_b_negate(alu_negate),

    .pc_next(pc_next),
    .jumping(jumps_jumping)
  );

  assign jump = !stalling && jumps_jumping;

  // stalling logic
  //   if should use reg_rd1 => wait until stall_1 == 0
  //   if should use reg_rd2 => wait until stall_2 == 0
  wire uses_reg_rd1, uses_reg_rd2;
  assign uses_reg_rd1 = (alu_1_src == REG_FILE_RS1);
  assign uses_reg_rd2 = (alu_2_src == REG_FILE_RS2) || memory_we;

  wire stalling;
  assign stalling = (uses_reg_rd1 && stall_1) || (uses_reg_rd2 && stall_2);
  assign stage_out.valid = !stalling;
  assign stage_out.ready = !stalling;
endmodule
