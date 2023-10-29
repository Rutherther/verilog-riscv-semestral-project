
import cpu_types::*;

module tb_cpu_add();
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

  file_program_memory #(.FILE_NAME("programs/bin/add.dat")) prog_mem_inst(
    .addr(pc[11:0]),
    .instruction(instruction)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("waves/tb_cpu_add.vcd");
    $dumpvars;

    rst_n = 0;
    #20
    rst_n = 1;

    #500 $finish;
  end
endmodule
