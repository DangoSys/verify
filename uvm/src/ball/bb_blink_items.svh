`uvm_analysis_imp_decl(_stim)
`uvm_analysis_imp_decl(_cmd)
`uvm_analysis_imp_decl(_read)
`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_resp)
`uvm_analysis_imp_decl(_mmio_read)
`uvm_analysis_imp_decl(_mmio_write)

class bb_blink_cmd_item extends uvm_sequence_item;
  rand bit [BB_BLINK_ROB_ID_W - 1:0] rob_id;
  rand bit [BB_BLINK_FUNCT_W - 1:0] funct;
  rand bit [BB_BLINK_RS2_W - 1:0] rs2;
  rand bit [BB_BLINK_ITER_W - 1:0] iter;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] op1_bank;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] op2_bank;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] wr_bank;
  rand bit [BB_BLINK_GROUP_ID_W - 1:0] op1_group;
  rand bit [BB_BLINK_GROUP_ID_W - 1:0] op2_group;
  rand bit [BB_BLINK_GROUP_ID_W - 1:0] wr_group;
  rand bit [BB_BLINK_GROUP_COUNT_W - 1:0] op1_col;
  rand bit [BB_BLINK_GROUP_COUNT_W - 1:0] op2_col;
  rand bit [BB_BLINK_GROUP_COUNT_W - 1:0] wr_col;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] wr_read_bank;
  rand bit [BB_BLINK_BANK_ID_W - 1:0] wr_arch_bank;

  `uvm_object_utils_begin(bb_blink_cmd_item)
    `uvm_field_int(rob_id, UVM_ALL_ON)
    `uvm_field_int(funct, UVM_ALL_ON)
    `uvm_field_int(rs2, UVM_ALL_ON)
    `uvm_field_int(iter, UVM_ALL_ON)
    `uvm_field_int(op1_bank, UVM_ALL_ON)
    `uvm_field_int(op2_bank, UVM_ALL_ON)
    `uvm_field_int(wr_bank, UVM_ALL_ON)
    `uvm_field_int(op1_group, UVM_ALL_ON)
    `uvm_field_int(op2_group, UVM_ALL_ON)
    `uvm_field_int(wr_group, UVM_ALL_ON)
    `uvm_field_int(op1_col, UVM_ALL_ON)
    `uvm_field_int(op2_col, UVM_ALL_ON)
    `uvm_field_int(wr_col, UVM_ALL_ON)
    `uvm_field_int(wr_read_bank, UVM_ALL_ON)
    `uvm_field_int(wr_arch_bank, UVM_ALL_ON)
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

  `uvm_object_utils_begin(bb_blink_resp_item)
    `uvm_field_int(rob_id, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bb_blink_resp_item");
    super.new(name);
  endfunction
endclass

class bb_mmio_read_item extends uvm_sequence_item;
  bit [12:0] addr;
  int port;
  `uvm_object_utils_begin(bb_mmio_read_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(port, UVM_ALL_ON)
  `uvm_object_utils_end
  function new(string name = "bb_mmio_read_item");
    super.new(name);
  endfunction
endclass

class bb_mmio_write_item extends uvm_sequence_item;
  bit [12:0] addr;
  bit [7:0] data;
  int port;
  `uvm_object_utils_begin(bb_mmio_write_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(port, UVM_ALL_ON)
  `uvm_object_utils_end
  function new(string name = "bb_mmio_write_item");
    super.new(name);
  endfunction
endclass
