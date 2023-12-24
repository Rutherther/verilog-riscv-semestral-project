import cpu_types::*;

module tb_ram();
  reg clk;

  reg [31:0] a;

  wire [31:0] rd;

  reg [3:0]  write_byte_enable;
  reg         we;
  reg [31:0]  wd;

  reg         dump;


  ram uut(
    .clk(clk),
    .a(a),
    .rd(rd),
    .we(we),
    .wd(wd),
    .dump(dump),
    .write_byte_enable(write_byte_enable)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("waves/tb_ram.vcd");
    $dumpvars;

    write_byte_enable = 4'b1111;


    #10
    a = 32'd103;
    we = 1;
    wd = 32'h5;

    #10
    a = 32'd107;
    we = 1;
    wd = 32'h1;

    #10
    wd = 32'h0;
    we = 0;
    a = 32'd103;

    #10
    we = 0;
    a = 32'd107;

    #10
    we = 1;
    write_byte_enable = 4'b1100;

    wd = 32'hFFFFFFFF;

    #10
    we = 0;

    #10 $finish;
  end


endmodule
