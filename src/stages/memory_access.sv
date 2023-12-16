import cpu_types::*;

module memory_access(
  input             clk,

  input [31:0]      memory_out,
  output reg [3:0]  memory_byte_enable,
  output reg [31:0] memory_write,
  output            memory_we,
  output [31:0]     memory_address,

  input             stage_status_t stage_in,
  output            stage_status_t stage_out
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

  reg [31:0]  read_data;
  reg [31:0]  stored_read_data;
  reg         misaligned_access; // signals that two addresses will have to be accessed
  reg         offset_position;
  wire        is_read;
  wire        is_write;
  wire [1:0]  bit_position;
  memory_mask_t       memory_mask;

  assign memory_mask = stage_in.instruction.memory_mask;
  assign is_read = stage_in.valid && stage_in.instruction.reg_rd_src == RD_MEMORY;
  assign is_write = stage_in.valid && stage_in.instruction.memory_we;
  assign bit_position = memory_address[1:0];

  assign misaligned_access = (is_read || is_write) &&
                          ((bit_position == 2'b11 && memory_mask == MEM_HALFWORD) ||
                          (bit_position != 0 && memory_mask == MEM_WORD)); // for MEM_BYTE, cannot happen

  always_ff @ (posedge clk) begin
    stored_read_data = read_data;

    if (misaligned_access) begin
      if (offset_position == 1'b1) begin
        offset_position = 1'b0;
      end
      else begin
        offset_position = offset_position + 1;
      end
    end
    else begin
      offset_position = 1'b0;
    end
  end

  always_comb begin
    read_data = 32'bX;
    memory_write = 32'bX;
    memory_byte_enable = 4'bX;
    // regular access (or not access at all)
    if (offset_position == 1'b0) begin
      memory_byte_enable = mask_to_mask_bytes(.mask(memory_mask)) << bit_position;
      memory_write = stage_in.reg_rd2 << (8*bit_position);
      read_data = mem_sext_maybe(
          .num(memory_out >> (8 * bit_position)),
          .mask(memory_mask),
          .sext(stage_in.instruction.memory_sign_extension)
      );
    end // misaligned access:
    else if (offset_position == 1'b0) begin
      memory_byte_enable = mask_to_mask_bytes(.mask(memory_mask)) << bit_position;
      memory_write = stage_in.reg_rd2 << (8*bit_position);
      read_data = memory_out >> (8 * bit_position);
    end // second stage of misaligned access:
    else if (offset_position == 1'b1) begin
      memory_byte_enable = mask_to_mask_bytes(.mask(memory_mask)) >> (4 - {2'b0, bit_position});
      memory_write = stage_in.reg_rd2 >> (4 - {2'b0, bit_position})*8;
      read_data = mem_sext_maybe(
        .num((memory_out << (4 - {2'b0, bit_position}) * 8) | stored_read_data),
        .mask(memory_mask),
        .sext(stage_in.instruction.memory_sign_extension)
      );
    end

  end

  assign memory_address = stage_in.data.data + {29'b0, offset_position, 2'b0};

  // 1. figure out if two addresses will have to be read
  // if yes, set ready to 0
  // 2. read from the first address, shift it accordingly
  // 3. read from second address, or it to the result
  //   this way only one 32-bit register should be needed for the storage
  //   alternative would be to have two registers, and them, shift them. get last 32 bits.

  assign memory_we = is_write;

  assign stage_out.instruction = stage_in.instruction;
  assign stage_out.pc = stage_in.pc;
  assign stage_out.reg_rd1 = stage_in.reg_rd1;
  assign stage_out.reg_rd2 = stage_in.reg_rd2;

  assign stage_out.data.valid = stage_in.valid && (offset_position == 1'b1 || !misaligned_access);
  assign stage_out.data.address = stage_in.valid ? stage_in.data.address : 0;
  assign stage_out.data.data =
    is_read ?
        read_data :
        stage_in.data.data;

  assign stage_out.valid = stage_in.valid && (offset_position == 1'b1 || !misaligned_access);
  assign stage_out.ready = offset_position == 1'b1 || !misaligned_access;
endmodule
