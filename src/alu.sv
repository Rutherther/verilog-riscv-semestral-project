module alu(
  input [2:0]              op,
  input [WIDTH - 1:0]      a, b,
  input                    sign,
  output reg [WIDTH - 1:0] out,
  output reg               zero_flag);
  parameter                WIDTH = 32;

  always_comb begin
    out = {WIDTH{1'bX}};
    case (op)
      3'b000 : out = a + b;
      3'b001 : out = a << b;
      3'b010 : out = signed'(a) < signed'(b);
      3'b011 : out = (a < b) ? 1 : 0;
      3'b100 : out = a ^ b;
      3'b101 : begin
        if (sign)
          out = a >> b;
        else
          out = a >>> b;
      end // should support arithmetical as well a >>> b
      3'b110 : out = a | b;
      3'b111 : out = a & b;
    endcase
  end

  always_comb
    zero_flag <= (out == 0) ? 1 : 0;

endmodule
