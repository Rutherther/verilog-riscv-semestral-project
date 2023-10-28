package cpu_types;
  typedef enum bit[0:0] { PC_PLUS, PC_ALU } pc_source_t;
  typedef enum bit[0:0] { REG_FILE_RS1, PC } alu_1_source_t;
  typedef enum bit[0:0] { REG_FILE_RS2, IMMEDIATE } alu_2_source_t;
  typedef enum bit[1:0] { RD_ALU, RD_PC_PLUS, RD_MEMORY } reg_rd_source_t;
endpackage
