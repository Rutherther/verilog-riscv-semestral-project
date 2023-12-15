package cpu_types;
  typedef enum bit[0:0] { PC_PLUS, PC_ALU } pc_source_t;
  typedef enum bit[0:0] { REG_FILE_RS1, PC } alu_1_source_t;
  typedef enum bit[0:0] { REG_FILE_RS2, IMMEDIATE } alu_2_source_t;
  typedef enum bit[1:0] { RD_ALU, RD_PC_PLUS, RD_MEMORY } reg_rd_source_t;

  typedef enum bit[1:0] { MEM_BYTE, MEM_HALFWORD, MEM_WORD } memory_mask_t;

  typedef struct {
    bit [31:0] instruction;

    bit [31:0] immediate;
    bit ebreak;

    alu_1_source_t alu_1_src;
    alu_2_source_t alu_2_src;

    bit [2:0] alu_op;
    bit alu_add_one;
    bit alu_negate;
    bit alu_sign;

    memory_mask_t memory_mask;
    bit memory_sign_extension;
    bit memory_we;

    bit reg_we;

    reg_rd_source_t reg_rd_src;

  } decoded_instruction_t;

  // For pipelining, used in execute, memory, and writeback stages.
  // The instruction decode stage will check if any tag matches the
  // address being read from. If yes, it has to be forwarded instead
  // of getting it from the register. Additionaly, if the data
  // are invalid, stalling will be necessary.
  typedef struct {
    bit [4:0]  address; // The address the data will be written to
    bit [31:0] data; // The data to be written to the address
    bit        valid; // Are the data valid? (data will be invalid for memory operations in execute stage)
  } register_data_status_t;

  typedef struct {
    register_data_status_t execute_out;
    register_data_status_t access_out;
    register_data_status_t writeback_in;
  } forwarding_data_status_t;

  typedef struct {
    decoded_instruction_t instruction;
    register_data_status_t data;

    bit [31:0] pc;

    bit [31:0] reg_rd1;
    bit [31:0] reg_rd2;

    bit valid;
    bit ready;
    // !ready == stall
  } stage_status_t;

  const int FETCH = 0;
  const int DECODE = 1;
  const int EXECUTE = 2;
  const int ACCESS = 3;
  const int WRITEBACK = 4;
endpackage
