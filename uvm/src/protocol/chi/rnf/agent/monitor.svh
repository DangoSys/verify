class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  virtual chi_rnf_if vif;
  uvm_analysis_port #(sample_item) ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual chi_rnf_if)::get(this, "", "vif", vif))
      `uvm_fatal("VIF", "CHI monitor interface is required")
  endfunction
  task run_phase(uvm_phase phase);
    sample_item t;
    forever begin
      @(posedge vif.clock);
      t = sample_item::type_id::create("observed");
      t.sampled.reset = vif.reset;
      t.sampled.access_valid = vif.access_valid;
      t.sampled.access_ready = vif.access_ready;
      t.sampled.access_write = vif.access_write;
      t.sampled.access_addr = vif.access_addr;
      t.sampled.access_data = vif.access_data;
      t.sampled.access_mask = vif.access_mask;
      t.sampled.access_atomic = vif.access_atomic;
      t.sampled.access_atomic_word = vif.access_atomic_word;
      t.sampled.result_valid = vif.result_valid;
      t.sampled.result_ready = vif.result_ready;
      t.sampled.result_error = vif.result_error;
      t.sampled.result_data = vif.result_data;
      t.sampled.req_valid = vif.req_valid;
      t.sampled.req_ready = vif.req_ready;
      t.sampled.rsp_valid = vif.rsp_valid;
      t.sampled.rsp_ready = vif.rsp_ready;
      t.sampled.dat_valid = vif.dat_valid;
      t.sampled.dat_ready = vif.dat_ready;
      t.sampled.rx_rsp_valid = vif.rx_rsp_valid;
      t.sampled.rx_rsp_ready = vif.rx_rsp_ready;
      t.sampled.rx_dat_valid = vif.rx_dat_valid;
      t.sampled.rx_dat_ready = vif.rx_dat_ready;
      t.sampled.snp_valid = vif.snp_valid;
      t.sampled.snp_ready = vif.snp_ready;
      t.sampled.req = vif.req;
      t.sampled.rsp = vif.rsp;
      t.sampled.rx_rsp = vif.rx_rsp;
      t.sampled.dat = vif.dat;
      t.sampled.rx_dat = vif.rx_dat;
      t.sampled.snp = vif.snp;
      t.sampled.outstanding = vif.outstanding;
      ap.write(t);
    end
  endtask
endclass
