import cpu_types::*;

module forwarder(
  input             clk,
  input [4:0]       read_address,
  input [31:0]      register_file_data,
  input             forwarding_data_status_t data_in_pipeline,

  output            forwarding,
  output reg        stall,
  output reg [31:0] data
);
  // if any data in the pipeline match the reading address,
  // these will be used instead of the register_file_data
  //
  // if there are multiple matches, the first one is taken
  // to get the most recent data

  always_comb begin
    stall = 0;
    data = register_file_data;
    forwarding = 0;

    if (read_address != 0 && data_in_pipeline.execute_out.target == read_address) begin
      stall = !data_in_pipeline.execute_out.valid;
      data = data_in_pipeline.execute_out.value;
      forwarding = 1;
    end
    else if (read_address != 0 && data_in_pipeline.access_out.target == read_address) begin
      stall = !data_in_pipeline.access_out.valid;
      data = data_in_pipeline.access_out.value;
      forwarding = 1;
    end
    else if (read_address != 0 && data_in_pipeline.writeback_in.target == read_address) begin
      stall = !data_in_pipeline.writeback_in.valid;
      data = data_in_pipeline.writeback_in.value;
      forwarding = 1;
    end
  end
endmodule
