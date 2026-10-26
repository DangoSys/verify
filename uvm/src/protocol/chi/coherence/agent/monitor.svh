class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  virtual coherence_control_if control;
  virtual stream_if #(`COH_REQ_WIDTH) req;
  virtual stream_if #(`COH_RSP_WIDTH) rx_rsp;
  virtual stream_if #(`COH_DAT_WIDTH) rx_dat;
  virtual stream_if #(`COH_TXRSP_WIDTH) tx_rsp;
  virtual stream_if #(`COH_TXDAT_WIDTH) tx_dat;
  virtual stream_if #(`COH_SNP_CHANNEL_WIDTH) snp;
  virtual stream_if #(`COH_MEMREQ_WIDTH) mem_req;
  virtual stream_if #(`COH_MEMRESP_WIDTH) mem_resp;
  uvm_analysis_port #(snapshot) ap;
  snapshot latest;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual coherence_control_if)::get(
            this, "", "control", control
        ) || !uvm_config_db#(virtual stream_if #(`COH_REQ_WIDTH))::get(
            this, "", "req", req
        ) || !uvm_config_db#(virtual stream_if #(`COH_RSP_WIDTH))::get(
            this, "", "rx_rsp", rx_rsp
        ) || !uvm_config_db#(virtual stream_if #(`COH_DAT_WIDTH))::get(
            this, "", "rx_dat", rx_dat
        ) || !uvm_config_db#(virtual stream_if #(`COH_TXRSP_WIDTH))::get(
            this, "", "tx_rsp", tx_rsp
        ) || !uvm_config_db#(virtual stream_if #(`COH_TXDAT_WIDTH))::get(
            this, "", "tx_dat", tx_dat
        ) || !uvm_config_db#(virtual stream_if #(`COH_SNP_CHANNEL_WIDTH))::get(
            this, "", "snp", snp
        ) || !uvm_config_db#(virtual stream_if #(`COH_MEMREQ_WIDTH))::get(
            this, "", "mem_req", mem_req
        ) || !uvm_config_db#(virtual stream_if #(`COH_MEMRESP_WIDTH))::get(
            this, "", "mem_resp", mem_resp
        ))
      `uvm_fatal("VIF", "Coherence interfaces missing")
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge control.clock);
      latest = snapshot::type_id::create("observed");
      latest.reset = control.reset;
      latest.outstanding = control.outstanding;
      latest.req_bits = req.bits;
      latest.req_valid = req.valid;
      latest.req_ready = req.ready;
      latest.rx_rsp_bits = rx_rsp.bits;
      latest.rx_rsp_valid = rx_rsp.valid;
      latest.rx_rsp_ready = rx_rsp.ready;
      latest.rx_dat_bits = rx_dat.bits;
      latest.rx_dat_valid = rx_dat.valid;
      latest.rx_dat_ready = rx_dat.ready;
      latest.tx_rsp_bits = tx_rsp.bits;
      latest.tx_rsp_valid = tx_rsp.valid;
      latest.tx_rsp_ready = tx_rsp.ready;
      latest.tx_dat_bits = tx_dat.bits;
      latest.tx_dat_valid = tx_dat.valid;
      latest.tx_dat_ready = tx_dat.ready;
      latest.snp_bits = snp.bits;
      latest.snp_valid = snp.valid;
      latest.snp_ready = snp.ready;
      latest.mem_req_bits = mem_req.bits;
      latest.mem_req_valid = mem_req.valid;
      latest.mem_req_ready = mem_req.ready;
      latest.mem_resp_bits = mem_resp.bits;
      latest.mem_resp_valid = mem_resp.valid;
      latest.mem_resp_ready = mem_resp.ready;
      ap.write(latest);
    end
  endtask
endclass
