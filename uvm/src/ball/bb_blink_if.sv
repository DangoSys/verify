interface bb_blink_if #(
  parameter int IN_BW  = 1,
  parameter int OUT_BW = 1
);
  logic         clock;
  logic         reset;

  logic         status_running;

  logic         cmd_req_ready;
  logic         cmd_req_valid;
  logic [`BB_ROB_ID_W-1:0] cmd_req_bits_rob_id;
  logic [  6:0] cmd_req_bits_funct;
  logic [ 63:0] cmd_req_bits_rs2;
  logic [ 33:0] cmd_req_bits_iter;
  logic [`BB_BANK_ID_W-1:0] cmd_req_bits_op1_bank;
  logic [`BB_BANK_ID_W-1:0] cmd_req_bits_op2_bank;
  logic [`BB_BANK_ID_W-1:0] cmd_req_bits_wr_bank;
  logic [`BB_GROUP_ID_W-1:0] cmd_req_bits_op1_group;
  logic [`BB_GROUP_ID_W-1:0] cmd_req_bits_op2_group;
  logic [`BB_GROUP_ID_W-1:0] cmd_req_bits_wr_group;
  logic [`BB_GROUP_COUNT_W-1:0] cmd_req_bits_op1_col;
  logic [`BB_GROUP_COUNT_W-1:0] cmd_req_bits_op2_col;
  logic [`BB_GROUP_COUNT_W-1:0] cmd_req_bits_wr_col;
  logic [`BB_BANK_ID_W-1:0] cmd_req_bits_wr_read_bank;
  logic [`BB_BANK_ID_W-1:0] cmd_req_bits_wr_arch_bank;

  logic         cmd_resp_ready;
  logic         cmd_resp_valid;
  logic [`BB_ROB_ID_W-1:0] cmd_resp_bits_rob_id;

  logic [`BB_BANK_ID_W-1:0] bank_read_bank_id   [IN_BW];
  logic [`BB_ROB_ID_W-1:0] bank_read_rob_id    [IN_BW];
  logic [`BB_GROUP_ID_W-1:0] bank_read_group_id  [IN_BW];
  logic         bank_read_req_ready [IN_BW];
  logic         bank_read_req_valid [IN_BW];
  logic [ 15:0] bank_read_req_addr  [IN_BW];
  logic         bank_read_resp_ready[IN_BW];
  logic         bank_read_resp_valid[IN_BW];
  logic [127:0] bank_read_resp_data [IN_BW];

  logic [`BB_BANK_ID_W-1:0] bank_write_bank_id   [OUT_BW];
  logic [`BB_ROB_ID_W-1:0] bank_write_rob_id    [OUT_BW];
  logic [`BB_GROUP_ID_W-1:0] bank_write_group_id  [OUT_BW];
  logic         bank_write_req_ready [OUT_BW];
  logic         bank_write_req_valid [OUT_BW];
  logic [ 15:0] bank_write_req_addr  [OUT_BW];
  logic [ 15:0] bank_write_req_mask  [OUT_BW];
  logic [127:0] bank_write_req_data  [OUT_BW];
  logic         bank_write_resp_ready[OUT_BW];
  logic         bank_write_resp_valid[OUT_BW];
  logic         bank_write_resp_ok   [OUT_BW];

  logic         mmio_read_req_ready [4];
  logic         mmio_read_req_valid [4];
  logic [ 12:0] mmio_read_req_addr  [4];
  logic         mmio_read_resp_ready[4];
  logic         mmio_read_resp_valid[4];
  logic [  7:0] mmio_read_resp_bits_data[4];

  logic         mmio_write_req_ready[4];
  logic         mmio_write_req_valid[4];
  logic [ 12:0] mmio_write_req_addr [4];
  logic [  7:0] mmio_write_req_data [4];
endinterface
