module tb_alu();
  reg [31:0] a, b;
  reg [2:0]  op;
  reg        sign, add_one, negate;


  wire [31:0] out;
  wire        zero_flag;

  alu uut(
    .op(op),
    .a(a),
    .b(b),
    .out(out),
    .b_negate(negate),
    .b_add_one(add_one),
    .sign(sign),
    .zero_flag(zero_flag)
  );

  initial begin
    $dumpfile("waves/tb_alu.vcd");
    $dumpvars;

    a = 30;
    b = 20;
    op = 3'b000;
    negate = 1'b0;
    add_one = 1'b0;
    sign = 1'b0;

    // add

    #10 // subtract
      negate = 1'b1;
    add_one = 1'b1;

    #10 // shift left
      a = 1;
    b = 2;
    negate = 1'b0;
    add_one = 1'b0;

    op = 3'b001;

    #10 // signed comparison a < b
      op = 3'b010;
    #10
      a = -10;
    b = 10;
    #10 // unsigned comparison
      op = 3'b011;
    #10 // xor
      op = 3'b100;
    #10 // shift right logical
      a = -1;
    b = 2;
    op = 3'b101;
    #10 // shift right arithmetical
      sign = 1'b1;
    #10 // or
      sign = 1'b0;
      op = 3'b110;
    #10 // and
      op = 3'b111;

    #10 $finish;
  end
endmodule
