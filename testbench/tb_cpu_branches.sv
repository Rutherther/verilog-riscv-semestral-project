import cpu_types::*;

module tb_cpu_branches();
  reg clk, rst_n;

  wire [31:0] memory_address, memory_write, memory_out;
  wire [3:0]  memory_write_byte_enable;
  wire        memory_we;

  wire [31:0] pc;
  reg [31:0]  instruction;

  wire        ebreak;

  cpu uut(
    .clk(clk),
    .rst_n(rst_n),

    .instruction(instruction),
    .pc(pc),

    .memory_address(memory_address),
    .memory_out(memory_out),
    .memory_write(memory_write),
    .memory_byte_enable(memory_write_byte_enable),
    .memory_we(memory_we),

    .ebreak(ebreak)
  );

  ram memory_inst(
    .clk(clk),
    .a(memory_address),
    .write_byte_enable(memory_write_byte_enable),
    .we(memory_we),
    .wd(memory_write),
    .rd(memory_out)
  );

  file_program_memory #(.FILE_NAME("programs/bin/branches.dat")) prog_mem_inst(
    .addr(pc[11:0]),
    .instruction(instruction)
  );

  always_ff @ (posedge ebreak) begin
    #15 $finish;
  end

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile("waves/tb_cpu_branches.vcd");
    $dumpvars;

    rst_n = 0;
    #20
    rst_n = 1;
  end
endmodule
