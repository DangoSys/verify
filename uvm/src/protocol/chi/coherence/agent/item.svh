class request_item extends uvm_sequence_item;
  `uvm_object_utils(request_item)
  req_t payload;
  bit send = 1;
  bit reset_command;
  int cycles = 1;
  bit check_blocked;
  function new(string name = "request_item");
    super.new(name);
  endfunction
endclass

class snapshot extends uvm_sequence_item;
  `uvm_object_utils(snapshot)
  bit reset;
  int unsigned outstanding;
  logic [`COH_REQ_WIDTH-1:0] req_bits;
  bit req_valid, req_ready;
  logic [`COH_RSP_WIDTH-1:0] rx_rsp_bits;
  bit rx_rsp_valid, rx_rsp_ready;
  logic [`COH_DAT_WIDTH-1:0] rx_dat_bits;
  bit rx_dat_valid, rx_dat_ready;
  logic [`COH_TXRSP_WIDTH-1:0] tx_rsp_bits;
  bit tx_rsp_valid, tx_rsp_ready;
  logic [`COH_TXDAT_WIDTH-1:0] tx_dat_bits;
  bit tx_dat_valid, tx_dat_ready;
  logic [`COH_SNP_CHANNEL_WIDTH-1:0] snp_bits;
  bit snp_valid, snp_ready;
  logic [`COH_MEMREQ_WIDTH-1:0] mem_req_bits;
  bit mem_req_valid, mem_req_ready;
  logic [`COH_MEMRESP_WIDTH-1:0] mem_resp_bits;
  bit mem_resp_valid, mem_resp_ready;
  function new(string name = "snapshot");
    super.new(name);
  endfunction
endclass
