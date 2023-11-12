module alu(
  input [2:0]              op,
  input [WIDTH - 1:0]      a, b,
  input                    sign,
  input                    b_add_one,
  input                    b_negate,
  output reg [WIDTH - 1:0] out,
  output reg               zero_flag);
  parameter                WIDTH = 32;

  reg [WIDTH - 1:0]        real_b;

  always_comb begin
    if (b_negate)
      real_b = ~b;
    else
      real_b = b;
    real_b = real_b + (b_add_one ? 1 : 0);
  end


  always_comb begin

    case (op)
      3'b000 : out = a + real_b;
      3'b001 : out = a << real_b[4:0];
      3'b010 : out = (signed'(a) < signed'(real_b)) ? 1 : 0;
      3'b011 : out = (a < real_b) ? 1 : 0;
      3'b100 : out = a ^ real_b;
      3'b101 : begin
        if (sign)
          out = signed'(a) >>> signed'(real_b[4:0]);
        else
          out = a >> real_b[4:0];
      end
      3'b110 : out = a | real_b;
      3'b111 : out = a & real_b;
      default: out = {WIDTH{1'bX}};
    endcase
  end

  always_comb
    zero_flag = (out == 0) ? 1 : 0;

endmodule
