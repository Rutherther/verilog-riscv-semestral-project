import cpu_types::*;

module ram (
  input         clk, we,
  input [31:0]  a, wd,
  input [3:0]   write_byte_enable,
  input         dump,
  output [31:0] rd);

  reg [31:0]      mask;
  reg [31:0]      memory[1023];

  assign rd = memory[a[11:2]]; // word aligned

  parameter        LOAD_FILE = 0;
  parameter string LOAD_FILE_PATH = "";
  parameter        WRITE_FILE = 0;
  parameter string WRITE_FILE_PATH = "";

  always_comb begin
    mask = {
            {8{write_byte_enable[3]}},
            {8{write_byte_enable[2]}},
            {8{write_byte_enable[1]}},
            {8{write_byte_enable[0]}}
            };
  end

  initial
    if (LOAD_FILE == 1) begin
      $display("Loading file %s into memory.", LOAD_FILE_PATH);
      $readmemh(LOAD_FILE_PATH, memory);
    end

  initial begin
    if (WRITE_FILE == 1) begin
      wait (dump == 1);
      #5
      $display("Writing memory to file %s.", WRITE_FILE_PATH);
      $writememh(WRITE_FILE_PATH, memory);
    end
  end

  always_ff @ (posedge clk)
    if(we)
      memory[a[11:2]] = (rd & ~mask) | (wd & mask);

endmodule
