import cpu_types::*;

module jumps(
  input [31:0]  pc,
  input [31:0]  immediate,
  input         pc_source_t pc_src,
  input         jump_negate_zero,
  input         jump_instruction,

  input [2:0]   alu_op,
  input [31:0]  alu_a, alu_b,
  input         alu_sign,
  input         alu_b_add_one,
  input         alu_b_negate,

  output [31:0] pc_next,
  output        jumping
);
  wire [31:0] alu_out;
  wire        alu_zero;

  wire        branch_taken;

  assign jumping = branch_taken || pc_src == PC_ALU;

  assign branch_taken = jump_instruction && (alu_zero ^ jump_negate_zero);
  always_comb begin
    pc_next = 32'bX;
    case (pc_src)
      PC_PLUS : begin
        if (branch_taken)
          pc_next = pc + immediate;
      end
      PC_ALU : pc_next = alu_out;
    endcase
  end

  alu #(.WIDTH(32)) alu_inst(
    .a(alu_a),
    .b(alu_b),
    .out(alu_out),

    .op(alu_op),
    .b_add_one(alu_b_add_one),
    .b_negate(alu_b_negate),
    .sign(alu_sign),
    .zero_flag(alu_zero)
  );
endmodule
