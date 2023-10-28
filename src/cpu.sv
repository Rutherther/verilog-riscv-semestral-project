import cpu_types::*;

module cpu(
  input clk,
  input rst_n
);
  parameter WIDTH = 32;

  wire [31:0] instruction;

  reg [31:0]  pc_next;
  wire [31:0] pc;
  wire        pc_src;

  reg [31:0]  alu_1, alu_2;
  wire        alu_1_src, alu_2_src;

  wire [2:0]  alu_op;
  wire        alu_add_one, alu_negate, alu_signed;
  wire        alu_zero;
  wire [31:0] alu_out;

  wire [4:0]  reg_a_1, reg_a_2, reg_a_w;
  wire [31:0] reg_rd1, reg_rd2;
  reg [31:0]  reg_write;
  wire [1:0]  reg_write_src;
  wire        reg_we;

  wire [31:0] memory_address;
  wire [31:0] memory_out, memory_write;
  wire        memory_we;

  wire [31:0] immediate;

  wire        jump_instruction, jump_negate_zero;
  wire        jump_taken;

  assign memory_write = reg_rd2;
  assign memory_address = alu_out;

  // alu source 1
  always_comb begin
    case (alu_1_src)
      REG_FILE_RS1 : alu_1 = reg_rd1;
      PC : alu_1 = pc;
    endcase
  end

  // alu source 2
  always_comb begin
    case (alu_2_src)
      REG_FILE_RS2 : alu_2 = reg_rd2;
      IMMEDIATE : alu_2 = immediate;
    endcase
  end

  // pc source
  assign jump_taken = jump_instruction && (alu_out[0] ^ jump_negate_zero);
  always_comb begin
    case (pc_src)
      PC_PLUS : begin
        if (jump_taken)
          pc_next = pc + immediate;
        else
          pc_next = pc + 4;
      end
      PC_ALU : pc_next = alu_out;
    endcase
  end

  // register file write source
  always_comb begin
    case (reg_write_src)
      RD_ALU : reg_write = alu_out;
      RD_PC_PLUS : reg_write = pc + 4;
      RD_MEMORY : reg_write = memory_out;
      default : ;
    endcase
  end

  control_unit control_unit_inst(
    .instruction(instruction),

    .immediate(immediate),

    .alu_op(alu_op),
    .alu_add_one(alu_add_one),
    .alu_negate(alu_negate),
    .alu_signed(alu_signed),

    .memory_we(memory_we),

    .jump_instruction(jump_instruction),
    .jump_negate_zero(jump_negate_zero),

    .pc_src(pc_src),
    .alu_src_1(alu_1_src),
    .alu_src_2(alu_2_src),
    .reg_rd_src(reg_write_src),

    .reg_rs1(reg_a_1),
    .reg_rs2(reg_a_2),
    .reg_rd(reg_a_w),
    .reg_we(reg_we)
  );

  alu #(.WIDTH(WIDTH)) alu_inst(
    .a(alu_1),
    .b(alu_2),

    .out(alu_out),

    .op(alu_op),
    .b_add_one(alu_add_one),
    .b_negate(alu_negate),
    .sign(alu_signed),
    .zero_flag(alu_zero)
  );

  register_file #(.WIDTH(WIDTH), .ADDRESS_LENGTH(5)) register_file_inst(
    .clk(clk),
    .a1(reg_a_1),
    .a2(reg_a_2),
    .a3(reg_a_w),
    .we3(reg_we),
    .wd3(reg_write),
    .rd1(reg_rd1),
    .rd2(reg_rd2)
  );

  program_counter program_counter_inst(
    .clk(clk),
    .rst_n(rst_n),
    .pc(pc[11:0]),
    .pc_next(pc_next[11:0])
  );

  program_memory program_memory_inst(
    .addr(pc[11:0]),
    .instruction(instruction)
  );

  ram memory_inst(
    .clk(clk),
    .a(memory_address),
    .we(memory_we),
    .wd(memory_write),
    .rd(memory_out)
  );
endmodule
