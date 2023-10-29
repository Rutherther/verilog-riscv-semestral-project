
import cpu_types::*;

module tb_cpu_simple();
  reg clk, rst_n;

  wire [31:0] memory_address, memory_write, memory_out;
  wire        memory_we;

  memory_mask_t memory_mask;

  wire [31:0] pc;
  reg [31:0]  instruction;

  cpu uut(
    .clk(clk),
    .rst_n(rst_n),

    .instruction(instruction),
    .pc(pc),

    .memory_address(memory_address),
    .memory_out(memory_out),
    .memory_write(memory_write),
    .memory_mask(memory_mask),
    .memory_we(memory_we)
  );

  ram memory_inst(
    .clk(clk),
    .a(memory_address),
    .mask(memory_mask),
    .we(memory_we),
    .wd(memory_write),
    .rd(memory_out)
  );

  always_comb begin
    case(pc[5:2])
      // addi x2, x0, 30
      0: instruction = {12'd30, 5'b00000, 3'b000, 5'b00010, 7'b0010011};
      // addi x3, x0, 20
      1: instruction = {12'd20, 5'b00000, 3'b000, 5'b00011, 7'b0010011};
      // sub x1, x2, x3
      2: instruction = {7'b0100000, 5'b00011, 5'b00010, 3'b000, 5'b00001, 7'b0110011};
      // sw x1, 0(x0)
      3: instruction = {7'b0000000, 5'b00001, 5'b00000, 3'b010, 5'b00000, 7'b0100011};
      // sw x1, 4(x0)
      4: instruction = {7'b0000000, 5'b00001, 5'b00000, 3'b010, 5'b00100, 7'b0100011};
      // lw x12, 4(x0)
      5: instruction = {12'h000, 5'b00000, 3'b010, 5'b01100, 7'b0000011};
      // beq x2, x3, 2
      6: instruction = {7'b0000000, 5'b00011, 5'b00010, 3'b000, 5'b01000, 7'b1100011};
      // bne x2, x3, 2 (should jump by two instructions instead of 1)
      7: instruction = {7'b0000000, 5'b00011, 5'b00010, 3'b001, 5'b01000, 7'b1100011};
      // nop
      8: instruction = {12'b0, 5'b0, 3'b0, 5'b0, 7'b0010011};
      // nop
      9: instruction = {12'b0, 5'b0, 3'b0, 5'b0, 7'b0010011};
      // auipc x5, 0
      10: instruction = {20'b0, 5'b00101, 7'b0010111};
      // jalr x10, x0, 0
      11: instruction = {12'b0000000, 5'b00000, 3'b000, 5'b01010, 7'b1100111};
      // nop
      default : instruction = {12'b0, 5'b0, 3'b0, 5'b0, 7'b0010011};
    endcase
  end

  // expectation:
  // pc
  // 0  x2 = 30
  // 1  x3 = 20
  // 2  x1 = x2 - x3 = 10
  // 3  m(0) = x1 = 10
  // 4  m(4) = x1 = 10
  // 5  x12 = m(4) = x1 = 10
  // 6  --
  // 7  --
  // 9  --
  // 10 x5 = pc = 10 << 2
  // 11 jump to 0
  // 0  x10 = 12 << 2

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("cpu_simple.vcd");
    $dumpvars;

    rst_n = 0;
    #20
    rst_n = 1;

    #300 $finish;
  end
endmodule
