import cpu_types::*;

module tb_control_unit();
  reg [31:0] instruction;

  wire       memory_we;

  pc_source_t pc_src;

  wire jump_instruction;
  wire jump_negate_zero;

  wire [31:0] immediate;

  alu_1_source_t alu_src_1;
  alu_2_source_t alu_src_2;

  wire [2:0]  alu_op;
  wire        alu_signed;
  wire        alu_negate;
  wire        alu_add_one;

  wire [4:0]  reg_rs1;
  wire [4:0]  reg_rs2;

  reg_rd_source_t reg_rd_src;
  wire [4:0]  reg_rd;
  wire        reg_we;

  memory_mask_t memory_mask;
  wire memory_sign_extension;

  control_unit uut(
    .instruction(instruction),
    .memory_we(memory_we),
    .pc_src(pc_src),
    .jump_instruction(jump_instruction),
    .jump_negate_zero(jump_negate_zero),
    .immediate(immediate),
    .alu_src_1(alu_src_1),
    .alu_src_2(alu_src_2),
    .alu_op(alu_op),
    .alu_signed(alu_signed),
    .alu_negate(alu_negate),
    .alu_add_one(alu_add_one),
    .reg_rs1(reg_rs1),
    .reg_rs2(reg_rs2),
    .reg_rd_src(reg_rd_src),
    .reg_rd(reg_rd),
    .reg_we(reg_we),
    .memory_mask(memory_mask),
    .memory_sign_extension(memory_sign_extension)
  );

  initial begin
    $dumpfile("control_unit.vcd");
    $dumpvars;

    // addi
    //            imm[11:0] rs1       add     rd        alu imm op
    instruction = {12'h111, 5'b00010, 3'b000, 5'b00001, 7'b0010011};

    #5 // add
    //        funct7 (add) rs2      rs1       add/sub rd        alu reg op
    instruction = {7'b0, 5'b00010, 5'b00011, 3'b000, 5'b00001, 7'b0110011};

    #5 // sub
    //             funct7 (sub) rs2      rs1       add/sub rd        alu reg op
    instruction = {7'b0100000, 5'b00011, 5'b00010, 3'b000, 5'b00001, 7'b0110011};

    #5 // load byte
    //             imm[11:0] rs1      byte    rd        load
    instruction = {12'h111, 5'b00010, 3'b000, 5'b00001, 7'b0000011};

    #5 // load word
    //             imm[11:0] rs1      word    rd        load
    instruction = {12'h111, 5'b00010, 3'b010, 5'b00001, 7'b0000011};

    #5 // store byte
    //             imm[11:5]   rs2       rs1       byte    imm[4:0]  store
    instruction = {7'b0000001, 5'b00001, 5'b00010, 3'b000, 5'b00001, 7'b0100011};

    #5 // store word
    //             imm[11:5]   rs2       rs1       word    imm[4:0]  store
    instruction = {7'b0000001, 5'b00001, 5'b00010, 3'b010, 5'b00001, 7'b0100011};

    #5 // beq
    //          imm[12|10:5]   rs2       rs1       beq  imm[4:1|11]  branch
    instruction = {7'b1100000, 5'b00001, 5'b00010, 3'b000, 5'b00011, 7'b1100011};

    #5 // bge
    instruction = {7'b0000001, 5'b00001, 5'b00010, 3'b101, 5'b00001, 7'b1100011};

    #5 // bltu
    instruction = {7'b0000001, 5'b00001, 5'b00010, 3'b110, 5'b00001, 7'b1100011};

    #5 // jal
    //            imm[20|10:1|11|19:12]      rd        jal
    instruction = {20'b10000000001100000001, 5'b00001, 7'b1101111};

    #5 // jalr
    //            imm[12|10:5]  rs1       000     rd        jalr
    instruction = {12'b0000001, 5'b00001, 3'b000, 5'b00001, 7'b1100111};

    #5 // auipc
    instruction = {20'hA000A, 5'b00001, 7'b0010111};

    #5 // lui
    instruction = {20'hA000A, 5'b00001, 7'b0110111};

    #5
    instruction = 32'b1000000000101111101011110010011;


    #5 $finish;
  end

endmodule
