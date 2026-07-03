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
  rand bit [31:0] scale_bits;
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
    `uvm_field_int(scale_bits, UVM_ALL_ON)
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

  function void do_copy(uvm_object rhs);
    bb_blink_cmd_item rhs_;

    super.do_copy(rhs);
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("COPY", "rhs is not bb_blink_cmd_item")
    end

    bid = rhs_.bid;
    funct7 = rhs_.funct7;
    iter = rhs_.iter;
    op1_en = rhs_.op1_en;
    op2_en = rhs_.op2_en;
    wr_spad_en = rhs_.wr_spad_en;
    op1_from_spad = rhs_.op1_from_spad;
    op2_from_spad = rhs_.op2_from_spad;
    scale_bits = rhs_.scale_bits;
    op1_bank = rhs_.op1_bank;
    op2_bank = rhs_.op2_bank;
    wr_bank = rhs_.wr_bank;
    op1_col = rhs_.op1_col;
    op2_col = rhs_.op2_col;
    wr_col = rhs_.wr_col;
    meta_bank = rhs_.meta_bank;
    rs1 = rhs_.rs1;
    rs2 = rhs_.rs2;
    rob_id = rhs_.rob_id;
    is_sub = rhs_.is_sub;
    sub_rob_id = rhs_.sub_rob_id;
  endfunction
endclass

class bb_blink_read_item extends uvm_sequence_item;
  bit [BB_BLINK_BANK_ID_W - 1:0] bank_id;
  bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  bit [BB_BLINK_GROUP_ID_W - 1:0] group_id;
  bit [BB_BLINK_BANK_ADDR_W - 1:0] addr;

  `uvm_object_utils_begin(bb_blink_read_item)
    `uvm_field_int(bank_id, UVM_ALL_ON)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(group_id, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bb_blink_read_item");
    super.new(name);
  endfunction
endclass

class bb_blink_write_item extends uvm_sequence_item;
  bit [BB_BLINK_BANK_ID_W - 1:0] bank_id;
  bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  bit [BB_BLINK_BANK_ADDR_W - 1:0] addr;
  bit [BB_BLINK_BANK_MASK_W - 1:0] mask;
  bit [BB_BLINK_BANK_DATA_W - 1:0] data;

  `uvm_object_utils_begin(bb_blink_write_item)
    `uvm_field_int(bank_id, UVM_ALL_ON)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(mask, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
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
