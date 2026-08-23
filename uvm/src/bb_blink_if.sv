interface bb_blink_if #(
  parameter int IN_BW  = 1,
  parameter int OUT_BW = 1
);
  logic         clock;
  logic         reset;

  logic         cmd_req_ready;
  logic         cmd_req_valid;
  logic [  4:0] cmd_req_bits_cmd_bid;
  logic [  6:0] cmd_req_bits_cmd_funct7;
  logic [ 33:0] cmd_req_bits_cmd_iter;
  logic         cmd_req_bits_cmd_op1_en;
  logic         cmd_req_bits_cmd_op2_en;
  logic         cmd_req_bits_cmd_wr_spad_en;
  logic         cmd_req_bits_cmd_op1_from_spad;
  logic         cmd_req_bits_cmd_op2_from_spad;
  logic [ 63:0] cmd_req_bits_cmd_special;
  logic [  4:0] cmd_req_bits_cmd_op1_bank;
  logic [  4:0] cmd_req_bits_cmd_op2_bank;
  logic [  4:0] cmd_req_bits_cmd_wr_bank;
  logic [  4:0] cmd_req_bits_cmd_op1_col;
  logic [  4:0] cmd_req_bits_cmd_op2_col;
  logic [  4:0] cmd_req_bits_cmd_wr_col;
  logic [  4:0] cmd_req_bits_cmd_meta_bank;
  logic [ 63:0] cmd_req_bits_cmd_rs1;
  logic [ 63:0] cmd_req_bits_cmd_rs2;
  logic [  3:0] cmd_req_bits_rob_id;
  logic         cmd_req_bits_is_sub;
  logic [  7:0] cmd_req_bits_sub_rob_id;

  logic         cmd_resp_ready;
  logic         cmd_resp_valid;
  logic [  3:0] cmd_resp_bits_rob_id;
  logic         cmd_resp_bits_is_sub;
  logic [  7:0] cmd_resp_bits_sub_rob_id;

  logic [  4:0] bank_read_bank_id   [IN_BW];
  logic [  3:0] bank_read_rob_id    [IN_BW];
  logic [  4:0] bank_read_group_id  [IN_BW];
  logic         bank_read_req_ready [IN_BW];
  logic         bank_read_req_valid [IN_BW];
  logic [  9:0] bank_read_req_addr  [IN_BW];
  logic         bank_read_resp_ready[IN_BW];
  logic         bank_read_resp_valid[IN_BW];
  logic [127:0] bank_read_resp_data [IN_BW];

  logic [  4:0] bank_write_bank_id   [OUT_BW];
  logic [  3:0] bank_write_rob_id    [OUT_BW];
  logic [  4:0] bank_write_group_id  [OUT_BW];
  logic         bank_write_req_ready [OUT_BW];
  logic         bank_write_req_valid [OUT_BW];
  logic [  9:0] bank_write_req_addr  [OUT_BW];
  logic [ 15:0] bank_write_req_mask  [OUT_BW];
  logic [127:0] bank_write_req_data  [OUT_BW];
  logic         bank_write_resp_ready[OUT_BW];
  logic         bank_write_resp_valid[OUT_BW];
  logic         bank_write_resp_ok   [OUT_BW];

  logic         sub_rob_req_ready;
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
