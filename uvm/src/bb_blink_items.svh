`uvm_analysis_imp_decl(_stim)
`uvm_analysis_imp_decl(_cmd)
`uvm_analysis_imp_decl(_read)
`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_resp)

class bb_blink_cmd_item extends uvm_sequence_item;
  rand bit [BB_BLINK_BID_W - 1:0] bid;
  rand bit [BB_BLINK_FUNCT7_W - 1:0] funct7;
  rand bit [BB_BLINK_ITER_W - 1:0] iter;
  rand bit op1_en;
  rand bit op2_en;
  rand bit wr_spad_en;
  rand bit op1_from_spad;
  rand bit op2_from_spad;
  rand bit [63:0] special;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] op1_bank;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] op2_bank;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] wr_bank;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] op1_col;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] op2_col;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] wr_col;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] meta_bank;
  rand bit [63:0] rs1;
  rand bit [63:0] rs2;
  rand bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  rand bit is_sub;
  rand bit [BB_BLINK_SUB_ROB_ID_W - 1:0] sub_rob_id;

  `uvm_object_utils_begin(bb_blink_cmd_item)
    `uvm_field_int(bid, UVM_ALL_ON)
    `uvm_field_int(funct7, UVM_ALL_ON)
    `uvm_field_int(iter, UVM_ALL_ON)
    `uvm_field_int(op1_en, UVM_ALL_ON)
    `uvm_field_int(op2_en, UVM_ALL_ON)
    `uvm_field_int(wr_spad_en, UVM_ALL_ON)
    `uvm_field_int(op1_from_spad, UVM_ALL_ON)
    `uvm_field_int(op2_from_spad, UVM_ALL_ON)
    `uvm_field_int(special, UVM_ALL_ON)
    `uvm_field_int(op1_bank, UVM_ALL_ON)
    `uvm_field_int(op2_bank, UVM_ALL_ON)
    `uvm_field_int(wr_bank, UVM_ALL_ON)
    `uvm_field_int(op1_col, UVM_ALL_ON)
    `uvm_field_int(op2_col, UVM_ALL_ON)
    `uvm_field_int(wr_col, UVM_ALL_ON)
    `uvm_field_int(meta_bank, UVM_ALL_ON)
    `uvm_field_int(rs1, UVM_ALL_ON)
    `uvm_field_int(rs2, UVM_ALL_ON)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(is_sub, UVM_ALL_ON)
    `uvm_field_int(sub_rob_id, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bb_blink_cmd_item");
    super.new(name);
  endfunction
endclass

class bb_blink_read_item extends uvm_sequence_item;
  bit [BB_BLINK_BANK_ID_W - 1:0] bank_id;
  bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  bit [BB_BLINK_GROUP_ID_W - 1:0] group_id;
  bit [BB_BLINK_BANK_ADDR_W - 1:0] addr;
  int port;

  `uvm_object_utils_begin(bb_blink_read_item)
    `uvm_field_int(bank_id, UVM_ALL_ON)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(group_id, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(port, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bb_blink_read_item");
    super.new(name);
  endfunction
endclass

class bb_blink_write_item extends uvm_sequence_item;
  bit [BB_BLINK_BANK_ID_W - 1:0] bank_id;
  bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  bit [BB_BLINK_GROUP_ID_W - 1:0] group_id;
  bit [BB_BLINK_BANK_ADDR_W - 1:0] addr;
  bit [BB_BLINK_BANK_MASK_W - 1:0] mask;
  bit [BB_BLINK_BANK_DATA_W - 1:0] data;
  int port;

  `uvm_object_utils_begin(bb_blink_write_item)
    `uvm_field_int(bank_id, UVM_ALL_ON)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(group_id, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(mask, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(port, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bb_blink_write_item");
    super.new(name);
  endfunction
endclass

class bb_blink_resp_item extends uvm_sequence_item;
  bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  bit is_sub;
  bit [BB_BLINK_SUB_ROB_ID_W - 1:0] sub_rob_id;

  `uvm_object_utils_begin(bb_blink_resp_item)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(is_sub, UVM_ALL_ON)
    `uvm_field_int(sub_rob_id, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bb_blink_resp_item");
    super.new(name);
  endfunction
endclass
