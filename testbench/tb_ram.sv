import cpu_types::*;

module tb_ram();

  reg clk;

  reg [31:0] a;

  wire [31:0] rd;

  memory_mask_t mask;

  reg         we;
  reg [31:0]  wd;

  ram uut(
    .clk(clk),
    .a(a),
    .rd(rd),
    .mask(mask),
    .we(we),
    .wd(wd)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("waves/tb_ram.vcd");
    $dumpvars;

    #10
    a = 32'd103;
    mask = MEM_WORD;
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

    #10 $finish;
  end


endmodule
