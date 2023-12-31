import cpu_types::*;

module control_unit(
  input [31:0]  instruction,

  output        memory_mask_t memory_mask,
  output        memory_sign_extension,

  // whether to save alu to memory
  output        memory_we,

  // going to pc (pc+4/imm, alu)
  output        pc_source_t pc_src,

  // if alu output zero(negated if zero_negate), jump (pc source pc + imm instead od pc + 4)
  output        jump_instruction,
  output        jump_negate_zero,

  output [31:0] immediate,

  // register file or pc
  output        alu_1_source_t alu_src_1,
  // register file or immediate
  output        alu_2_source_t alu_src_2,

  // going to alu
  output [2:0]  alu_op,
  output        alu_sign,
  output        alu_negate,
  output        alu_add_one,

  // going to register file
  output [4:0]  reg_rs1,
  output [4:0]  reg_rs2,
  // alu or memory
  output        reg_rd_source_t reg_rd_src,
  output [4:0]  reg_rd,
  output        reg_we,

  output        ebreak
);

  wire use_immediate;
  wire load_immediate;
  wire load_memory;
  wire load_pc, store_pc;
  wire conditional_jump, unconditional_jump;

  wire [2:0] alu_reg_op, alu_jump_op;
  wire       alu_reg_add_one, alu_reg_negate, alu_reg_signed;
  wire       alu_jump_add_one, alu_jump_negate;

  wire       alu_override;

  assign jump_instruction = conditional_jump;

  instruction_decoder decoder(
    .instruction(instruction),

    .ebreak(ebreak),

    .store_memory(memory_we),

    .load_memory(load_memory),

    .memory_mask(memory_mask),
    .memory_sign_extension(memory_sign_extension),

    .load_pc(load_pc),
    .store_pc(store_pc),

    .alu_reg_op(alu_reg_op),
    .alu_reg_add_one(alu_reg_add_one),
    .alu_reg_negate(alu_reg_negate),
    .alu_reg_signed(alu_reg_signed),

    .alu_jump_op(alu_jump_op),
    .alu_jump_add_one(alu_jump_add_one),
    .alu_jump_negate(alu_jump_negate),
    .jump_negate_zero(jump_negate_zero),

    .conditional_jump(conditional_jump),
    .unconditional_jump(unconditional_jump),

    .immediate(immediate),
    .use_immediate(use_immediate),
    .load_immediate(load_immediate),

    .reg_rs1(reg_rs1),
    .reg_rs2(reg_rs2),
    .reg_rd(reg_rd),
    .reg_we(reg_we)
  );

  // in these cases, alu is used just for addition, nothing else,
  // so use neither alu_jump, neither alu_reg, use zeros
  assign alu_override = load_memory || memory_we || load_pc || unconditional_jump || load_immediate;

  assign alu_op = conditional_jump ? alu_jump_op :
                  alu_override     ? 3'b000      :
                                     alu_reg_op;

  assign alu_add_one = conditional_jump ? alu_jump_add_one :
                       alu_override     ? 0'b0             :
                                          alu_reg_add_one;
  assign alu_negate = conditional_jump ? alu_jump_negate :
                      alu_override     ? 0'b0            :
                                         alu_reg_negate;
  assign alu_sign = conditional_jump ? 0'b0 :
                      alu_override     ? 0'b0 :
                                         alu_reg_signed;

  assign pc_src = unconditional_jump ? PC_ALU : PC_PLUS;
  assign alu_src_1 = load_pc ? PC : REG_FILE_RS1;
  assign reg_rd_src = store_pc ? RD_PC_PLUS : (load_memory ? RD_MEMORY : RD_ALU);
  assign alu_src_2 = use_immediate ? IMMEDIATE : REG_FILE_RS2;

endmodule
