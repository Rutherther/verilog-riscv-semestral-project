import cpu_types::*;

module tb_cpu_program();
  reg clk, rst_n;

  wire [31:0] memory_address, cpu_memory_address, memory_write, memory_out;
  wire [3:0]  memory_write_byte_enable;
  wire        memory_we;

  wire [31:0] pc;
  reg [31:0]  instruction;

  wire        ebreak;

  parameter string  CPU_PROGRAM_PATH;
  parameter string  CPU_PROGRAM_NAME;

  parameter         MEMORY_LOAD_FILE = 0;
  parameter string  MEMORY_LOAD_FILE_PATH = "";
  parameter         MEMORY_WRITE_FILE = 0;
  parameter string  MEMORY_WRITE_FILE_PATH = "";

  // assign 0xFF... when ebreak. To save the memory to a file.
  assign memory_address = ebreak == 1'b1 ? {32{1'b1}} : cpu_memory_address;

  cpu uut(
    .clk(clk),
    .rst_n(rst_n),

    .instruction(instruction),
    .pc(pc),

    .memory_address(cpu_memory_address),
    .memory_out(memory_out),
    .memory_write(memory_write),
    .memory_byte_enable(memory_write_byte_enable),
    .memory_we(memory_we),

    .ebreak(ebreak)
  );

  ram #(
    .LOAD_FILE(MEMORY_LOAD_FILE),
    .LOAD_FILE_PATH(MEMORY_LOAD_FILE_PATH),
    .WRITE_FILE(MEMORY_WRITE_FILE),
    .WRITE_FILE_PATH(MEMORY_WRITE_FILE_PATH)
  ) memory_inst(
    .clk(clk),
    .a(memory_address),
    .write_byte_enable(memory_write_byte_enable),
    .we(memory_we),
    .wd(memory_write),
    .rd(memory_out)
  );

  file_program_memory #(
    .FILE_NAME(CPU_PROGRAM_PATH)
  ) prog_mem_inst(
    .addr(pc[14:0]),
    .instruction(instruction)
  );

  always_ff @ (posedge ebreak) begin
    $display("ebreak at %d", pc);
    #15 $finish;
  end

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile({"waves/cpu_program_", CPU_PROGRAM_NAME, ".vcd"});
    $dumpvars;

    rst_n = 0;
    #20
    rst_n = 1;
  end
endmodule
