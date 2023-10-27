module instruction_decoder(
  input [31:0]     instruction,

  // whether to use memory as a source, instead of alu
  output reg       load_memory,
  output reg       store_memory,

  // TODO: implement
  // mask to use for halfwords, bits, etc.
  // used when loading memory, storing memory,
  // registers...
  output [31:0]    mask,

  // put alu_jump to alu if conditional_jump
  //
  // if unconditional_jump, source of pd is alu
  // elsif conditional_jump, source of pd is pd + imm
  // else source of pd is pd + 4
  //
  // if store pd => rd = pd + 4

  // inputs for alu, in case instruction is not conditional_jump
  output [2:0]     alu_reg_op, // the operation selection for alu
  output           alu_reg_add_one, //  whether to add one to rs2 (may be used for two's complement)
  output           alu_reg_negate, // whether to negate rs2 (may be used for two's complement)
  output           alu_reg_signed, // whether the operation for alu is signed
  output reg       load_pc, // should load pc to alu #1
  output reg       store_pc, // should store pc + 4

  output reg       unconditional_jump, // jump, always. To alu output.

  output reg       conditional_jump, // should jump if alu zero_flag correct
  output reg       alu_jump_op, // operation for alu for conditional jumps
  output reg       alu_jump_add_one, // add one for conditional jumps
  output reg       jump_negate_zero, // whether to negate zero flag from alu

  // whether to use immediate instead of rs2.
  // if false, immediate still may be added to second operand
  output           use_immediate,
  output [31:0]    immediate,

  // inputs to register file
  output [4:0]     reg_rs1,
  output reg [4:0] reg_rs2,
  output [4:0]     reg_rd,
  output           reg_we
);
  typedef enum bit[2:0] {Unknown, R, I, S, SB, U, UJ} instruction_type_type;
  instruction_type_type instruction_type;

  wire [2:0]    funct3;
  wire [6:0]    funct7;
  wire [6:0]    opcode;

  assign funct3 = instruction[14:12];
  assign funct7 = instruction[31:25];
  assign opcode = instruction[6:0];

  assign reg_rs1 = instruction[19:15];
  assign reg_rd = instruction[11:7];

  always_comb begin
    case (instruction_type)
      I : immediate = {20'b0, instruction[31:20]};
      S : immediate = {20'b0, instruction[31:25], instruction[11:7]};
      SB : immediate = {19'b0, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
      U : immediate = {instruction[31:12], 12'b0};
      UJ : immediate = {11'b0, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
      default: immediate = 32'b0;
    endcase
  end

  always_comb begin
    alu_reg_add_one = 1'b0;
    alu_reg_negate = 1'b0;
    if (funct3 == 0 && funct7[5] == 1) begin
      // subtraction
      alu_reg_add_one = 1'b1;
      alu_reg_negate = 1'b1;
    end
  end

  always_comb begin
    if (instruction_type == I ||
        instruction_type == U ||
        instruction_type == UJ ||
        instruction_type == S ||
        instruction_type == SB) begin
      // TODO: does this make sense? is putting 0s to rs2 really needed? imm should
      // be used always in this case
      reg_rs2 = 5'b00000;
      use_immediate = 1;
    end
    else begin
      reg_rs2 = instruction[24:20];
      use_immediate = 0;
    end
  end

  assign alu_reg_op = funct3;
  assign alu_reg_signed = funct7[5];

  assign mask = 32'b1;   // TODO (word, bit instructions, etc.)

  always_comb begin
     case (opcode[6:2])
      5'b00000 : instruction_type = I;
      5'b00011 : instruction_type = I; // fence
      5'b00100 : instruction_type = I;
      5'b00101 : instruction_type = U; // auipc
      5'b00110 : instruction_type = I;
      5'b01000 : instruction_type = S;
      5'b01100 : instruction_type = R;
      5'b01101 : instruction_type = U; // lui
      5'b01110 : instruction_type = R;
      5'b11000 : instruction_type = SB;
      5'b11001 : instruction_type = I; // jalr
      5'b11011 : instruction_type = UJ; // jal
      5'b11100 : instruction_type = I;
      default  : instruction_type = Unknown;
    endcase;
  end;

  always_comb begin
    store_memory = 1'b0;
    load_memory = 1'b0;
    load_pc = 1'b0;
    store_pc = 1'b0;
    reg_we = 1'b1;
    conditional_jump = 1'b0;
    unconditional_jump = 1'b0;

    // TODO: support mask
    // TODO: multiplication
    // NOTE: ecall, ebreak, CSRRW, CSRRS, SCRRC, CSRRWI, CSRRSI, CSRRCI unsupported
    case (opcode[6:2])
      5'b01100 : reg_we = 1'b1;
      5'b00100 : reg_we = 1'b1;
      5'b00000 : load_memory = 1'b1;
      5'b01000 : begin
        store_memory = 1'b1;
        reg_we = 1'b0;
      end
      5'b11000 : begin // branches
        conditional_jump = 1'b1;
        reg_we = 1'b0;
      end
      5'b11011 : begin // jump and link
        load_pc = 1'b1; // relative to pc
        unconditional_jump = 1'b1; // jump
        store_pc = 1'b1; // link #1
        reg_we = 1'b1; // link #2
      end
      5'b11001 : begin // jump and link register
        load_pc = 1'b1; // relative to pc
        unconditional_jump = 1'b1; // jump
        store_pc = 1'b1; // link #1
        reg_we = 1'b1; // link #2
      end
      5'b01101 : begin // load upper imm
        reg_we = 1'b1;
      end
      5'b00101 : begin // add upper imm to PC
        load_pc = 1'b1;
        reg_we = 1'b1;
      end
      default : ;
    endcase;
  end;

endmodule