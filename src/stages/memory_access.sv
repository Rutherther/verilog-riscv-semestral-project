import cpu_types::*;

module memory_access(
  input         clk,

  input [31:0]  memory_out,
  output [3:0]  memory_byte_enable,
  output [31:0] memory_write,
  output        memory_we,
  output [31:0] memory_address,

  input         stage_status_t stage_in,
  output        stage_status_t stage_out
);

  function bit[31:0] mem_sext_maybe;
    input [31:0] num;
    input        memory_mask_t mask;
    input        sext;
    begin
      case(mask)
        MEM_BYTE: return {{(32 - 8){sext & num[7]}}, num[7:0]};
        MEM_HALFWORD: return {{(32 - 16){sext & num[15]}}, num[15:0]};
        MEM_WORD: return num[31:0]; // rv32i, no 64 bit regs, no sign extension needed
        default: return 0;
      endcase
    end
  endfunction

  function bit[3:0] mask_to_mask_bytes;
    input memory_mask_t mask;
    begin
      case(mask)
        MEM_BYTE: return 4'b0001;
        MEM_HALFWORD: return 4'b0011;
        MEM_WORD: return 4'b1111;
        default: return 0;
      endcase
    end
  endfunction

  assign memory_byte_enable = mask_to_mask_bytes(.mask(stage_in.instruction.memory_mask)) << memory_address[1:0];
  assign memory_write = stage_in.reg_rd2 << (8*memory_address[1:0]);
  assign memory_address = stage_in.data.data;
  assign memory_we = stage_in.valid ? stage_in.instruction.memory_we : 0;

  assign stage_out.instruction = stage_in.instruction;
  assign stage_out.pc = stage_in.pc;
  assign stage_out.reg_rd1 = stage_in.reg_rd1;
  assign stage_out.reg_rd2 = stage_in.reg_rd2;

  assign stage_out.data.valid = stage_in.valid;
  assign stage_out.data.address = stage_in.valid ? stage_in.data.address : 0;
  assign stage_out.data.data =
    stage_in.instruction.reg_rd_src == RD_MEMORY ?
        mem_sext_maybe(
            .num(memory_out >> (8*memory_address[1:0])),
            .mask(stage_in.instruction.memory_mask),
            .sext(stage_in.instruction.memory_sign_extension)
        ) :
        stage_in.data.data;

  assign stage_out.valid = stage_in.valid;
  assign stage_out.ready = 1;
endmodule
