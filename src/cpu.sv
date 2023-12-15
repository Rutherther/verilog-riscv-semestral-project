import cpu_types::*;

module cpu(
  input             clk,
  input             rst_n,

  // program memory
  input [31:0]      instruction,
  output reg [31:0] pc,

  // ram
  output [31:0]     memory_address,
  input [31:0]      memory_out,
  output [31:0]     memory_write,
  output [3:0]      memory_byte_enable,
  output            memory_we,

  output            ebreak
);
  parameter WIDTH = 32;

  reg [31:0]  pc_next;

  wire [4:0]  reg_a_1, reg_a_2, reg_a_w;
  wire [31:0] reg_rd1, reg_rd2;
  reg [31:0]  reg_write;
  wire        reg_we;

  reg [2:0]  last_non_ready_stage;
  reg        all_stages_ready;

  wire        jump;
  wire [31:0] jumping_pc_next;

  stage_status_t stages_in[1:4];

  /// verilator doesn't like that data taken from stages_out[i]
  // are used in stages_out[i + 1]. But that shouldn't really matter
  // as there is not really a cyclic dependency.
  // It just seems that verilator is not very good at "separating"
  // array elements
/* verilator lint_off UNOPTFLAT */
  stage_status_t stages_out[0:3];
/* verilator lint_on UNOPTFLAT */

  assign ebreak = stages_out[ACCESS].instruction.ebreak;

  // stage registers
  always_ff @(posedge clk) begin
    if (rst_n == 0) begin
      for (int i = 0; i < $size(stages_in); i++) begin
        stages_in[i].data.address = 0;
      end
    end
    else begin
      for (int i = 0; i < $size(stages_in); i++) begin
        if (all_stages_ready || i >= last_non_ready_stage) begin
          stages_in[i + 1] = stages_out[i];
        end
      end
    end
  end

  // find first non ready stage. Stages before that will be stalled
  always_comb begin
    last_non_ready_stage = 0;
    all_stages_ready = 1'b1;
    for (int i = 0; i < $size(stages_out); i++) begin
      if (!stages_out[i].ready) begin
        last_non_ready_stage = i[2:0];
        all_stages_ready = 1'b0;
      end
    end
  end

  always_comb begin
    if (jump)
      pc_next = jumping_pc_next;
    else if (all_stages_ready) // assume no jump. If jump, if result will be thrown out
      pc_next = pc + 4;
    else // stalling (in any stage, meaning not fetching new instructions)
      pc_next = pc;
  end

  // data for forwarding from the stages
  // Note: this is a record instead of an array
  // just because verilator didn't like it as an array
  // consider switching back to array.
  forwarding_data_status_t data_in_pipeline;
  assign data_in_pipeline.execute_out = stages_out[EXECUTE].data;
  assign data_in_pipeline.access_out = stages_out[ACCESS].data;
  assign data_in_pipeline.writeback_in = stages_in[WRITEBACK].data;

  fetch fetch_inst(
    .clk(clk),
    .pc(pc),
    .mem_instruction(instruction),
    .stage_out(stages_out[FETCH])
  );

  decode decode_inst(
    .clk(clk),
    .jump(jump),
    .data_in_pipeline(data_in_pipeline),
    .reg_a_1(reg_a_1),
    .reg_a_2(reg_a_2),
    .reg_rd1(reg_rd1),
    .reg_rd2(reg_rd2),
    .stage_in(stages_in[DECODE]),
    .stage_out(stages_out[DECODE])
  );

  execute execute_inst(
    .clk(clk),
    .jump(jump),
    .jump_pc(jumping_pc_next),
    .stage_in(stages_in[EXECUTE]),
    .stage_out(stages_out[EXECUTE])
  );

  memory_access memory_access_inst(
    .clk(clk),
    .memory_out(memory_out),
    .memory_byte_enable(memory_byte_enable),
    .memory_write(memory_write),
    .memory_we(memory_we),
    .memory_address(memory_address),
    .stage_in(stages_in[ACCESS]),
    .stage_out(stages_out[ACCESS])
  );

  writeback writeback_inst(
    .clk(clk),
    .reg_a_write(reg_a_w),
    .reg_we(reg_we),
    .reg_write(reg_write),
    .stage_in(stages_in[WRITEBACK])
  );

  register_file #(.WIDTH(WIDTH), .ADDRESS_LENGTH(5)) register_file_inst(
    .clk(clk),
    .a1(reg_a_1),
    .a2(reg_a_2),
    .a3(reg_a_w),
    .we3(reg_we),
    .wd3(reg_write),
    .rd1(reg_rd1),
    .rd2(reg_rd2)
  );

  program_counter program_counter_inst(
    .clk(clk),
    .rst_n(rst_n),
    .pc(pc[11:0]),
    .pc_next(pc_next[11:0])
  );
endmodule
