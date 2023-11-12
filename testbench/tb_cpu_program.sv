import cpu_types::*;

module tb_cpu_program();
  reg clk, rst_n;

  wire [31:0] memory_address, memory_write, memory_out;
  wire [3:0]  memory_write_byte_enable;
  wire        memory_we;

  wire [31:0] pc;
  reg [31:0]  instruction;

  wire        ebreak;

  parameter string  CPU_PROGRAM_PATH;

  parameter string  TRACE_FILE_PATH = "trace.vcd";

  parameter         MEMORY_LOAD_FILE = 0;
  parameter string  MEMORY_LOAD_FILE_PATH = "";
  parameter         MEMORY_WRITE_FILE = 0;
  parameter string  MEMORY_WRITE_FILE_PATH = "";

  parameter         REGISTER_DUMP_FILE = 0;
  parameter string  REGISTER_DUMP_FILE_PATH = "";

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
    .rd(memory_out),
    .dump(ebreak)
  );

  file_program_memory #(
    .FILE_NAME(CPU_PROGRAM_PATH)
  ) prog_mem_inst(
    .addr(pc[19:0]),
    .instruction(instruction)
  );

  always_ff @ (posedge ebreak) begin
    $display("ebreak at %d", pc);

    if (REGISTER_DUMP_FILE == 1)
      $writememh(REGISTER_DUMP_FILE_PATH, uut.register_file_inst.gprs);

    for (int i = 1; i < 32; i++) begin
      $display("R%0d:%0d", i, uut.register_file_inst.gprs[i]);
    end
    #15 $finish;
  end

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $dumpfile(TRACE_FILE_PATH);
    $dumpvars;

    rst_n = 0;
    #20
    rst_n = 1;
  end
endmodule
