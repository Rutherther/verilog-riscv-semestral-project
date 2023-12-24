module tb_register_file();

  reg clk;
  reg [4:0] a1, a2, a3;

  wire [31:0] rd1, rd2;

  reg         we3;
  reg [31:0]  wd3;

  register_file uut(
    .clk(clk),
    .a1(a1),
    .a2(a2),
    .a3(a3),
    .we3(we3),
    .wd3(wd3),
    .rd1(rd1),
    .rd2(rd2)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("waves/tb_register_file.vcd");
    $dumpvars;
    a1 = 0;
    a2 = 0;
    a3 = 0;

    #10 // r0 is always 0, even on write
      a3 = 0;
    wd3 = 200;
    we3 = 1;

    #10 // r1 is writable
      a3 = 1;
    a1 = 1;

    #10 // r2 is writable
      a3 = 2;
    a2 = 2;

    #10 // r1 is overridable
      a3 = 1;
    wd3 = 100;

    #10 // r1 is not overriden if not we
      wd3 = 150;
      we3 = 0;

    #10
      a2 = 1;
    a1 = 2;

    #10 $finish;
  end


endmodule
