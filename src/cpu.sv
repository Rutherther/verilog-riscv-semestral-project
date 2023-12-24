import cpu_types::*;

module cpu(
  input             clk,
  input             rst_n,

  // program memory
  input [31:0]      instruction,
  output [31:0] pc,

  // ram
  output [31:0]     memory_address,
  input [31:0]      memory_read,
  output [31:0]     memory_write,
  output [3:0]      memory_byte_enable,
  output            memory_we,

  output            ebreak
);
  parameter WIDTH = 32;

  reg [31:0]  pc_next;

  wire [4:0]  reg_a_1, reg_a_2, reg_a_w;
  wire [31:0] reg_rs1, reg_rs2;
  reg [31:0]  reg_write;
  wire        reg_we;

  reg        all_stages_ready;

  wire        jump;
  wire [31:0] jumping_pc_next;

  stage_status_t fetch_out;
  stage_status_t decode_out;
  stage_status_t execute_out;
  stage_status_t memory_access_out;

  stage_status_t decode_in;
  stage_status_t execute_in;
  stage_status_t memory_access_in;
  stage_status_t writeback_in;

  assign ebreak = memory_access_out.instruction.ebreak;

  // stage registers
  always_ff @(posedge clk) begin
    if (rst_n == 0) begin
      decode_in.data.target = 0;
      execute_in.data.target = 0;
      memory_access_in.data.target = 0;
      writeback_in.data.target = 0;
    end
    else begin
      if (decode_out.ready && execute_out.ready && memory_access_out.ready)
        decode_in = fetch_out;
      if (execute_out.ready && memory_access_out.ready)
        execute_in = decode_out;
      if (memory_access_out.ready)
        memory_access_in = execute_out;
      writeback_in = memory_access_out;
    end
  end

  assign all_stages_ready = fetch_out.ready && decode_out.ready && execute_out.ready && memory_access_out.ready;

  always_comb begin
    if (!all_stages_ready)
      pc_next = pc;
    else if (jump)
      pc_next = jumping_pc_next;
    else // assume no jump. If jump, if result will be thrown out
      pc_next = pc + 4;
  end

  // data for forwarding from the stages
  // Note: this is a record instead of an array
  // just because verilator didn't like it as an array
  // consider switching back to array.
  forwarding_data_status_t data_in_pipeline;
  assign data_in_pipeline.execute_out = execute_out.data;
  assign data_in_pipeline.access_out = memory_access_out.data;
  assign data_in_pipeline.writeback_in = writeback_in.data;

  fetch fetch_inst(
    .clk(clk),
    .pc(pc),
    .flush(jump),
    .mem_instruction(instruction),
    .stage_out(fetch_out)
  );

  decode decode_inst(
    .clk(clk),
    .flush(jump),
    .data_in_pipeline(data_in_pipeline),
    .reg_a_1(reg_a_1),
    .reg_a_2(reg_a_2),
    .reg_rs1(reg_rs1),
    .reg_rs2(reg_rs2),
    .stage_in(decode_in),
    .stage_out(decode_out)
  );

  execute execute_inst(
    .clk(clk),
    .jump(jump),
    .jump_pc(jumping_pc_next),
    .stage_in(execute_in),
    .stage_out(execute_out)
  );

  memory_access memory_access_inst(
    .clk(clk),
    .memory_read(memory_read),
    .memory_byte_enable(memory_byte_enable),
    .memory_write(memory_write),
    .memory_we(memory_we),
    .memory_address(memory_address),
    .stage_in(memory_access_in),
    .stage_out(memory_access_out)
  );

  writeback writeback_inst(
    .clk(clk),
    .reg_a_write(reg_a_w),
    .reg_we(reg_we),
    .reg_write(reg_write),
    .stage_in(writeback_in)
  );

  register_file #(.WIDTH(WIDTH), .ADDRESS_LENGTH(5)) register_file_inst(
    .clk(clk),
    .a1(reg_a_1),
    .a2(reg_a_2),
    .a3(reg_a_w),
    .we3(reg_we),
    .wd3(reg_write),
    .rd1(reg_rs1),
    .rd2(reg_rs2)
  );

  program_counter program_counter_inst(
    .clk(clk),
    .rst_n(rst_n),
    .pc(pc[11:0]),
    .pc_next(pc_next[11:0])
  );
endmodule
