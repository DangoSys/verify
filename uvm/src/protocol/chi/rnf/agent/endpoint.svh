class endpoint_driver extends uvm_component;
  `uvm_component_utils(endpoint_driver)
  virtual chi_rnf_if vif;
  protocol_model state;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual chi_rnf_if)::get(this, "", "vif", vif))
      `uvm_fatal("VIF", "CHI endpoint interface is required")
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.clock);
      vif.req_ready = !vif.reset && !state.hold_req && state.cycle % 7 >= 2;
      vif.rsp_ready = !vif.reset && !state.hold_rsp && state.cycle % 11 >= 5;
      vif.dat_ready = !vif.reset && !state.hold_output_dat && state.cycle % 13 >= 6;
      vif.result_ready = !vif.reset && state.cycle % 9 >= 3;
      if (!state.rsp_active && state.rx_rsp_queue.size()) begin
        vif.rx_rsp = state.rx_rsp_queue.pop_front();
        state.rsp_active = 1;
      end
      if (!state.dat_active && !state.hold_fill && !state.hold_dat && state.rx_dat_queue.size()) begin
        if (state.reverse_transactions) vif.rx_dat = state.rx_dat_queue.pop_back();
        else vif.rx_dat = state.rx_dat_queue.pop_front();
        state.dat_active = 1;
      end
      if (!state.rsp_active) vif.rx_rsp = state.idle.rx_rsp;
      if (!state.dat_active) vif.rx_dat = state.idle.rx_dat;
      vif.rx_rsp_valid = state.rsp_active && !vif.reset;
      vif.rx_dat_valid = state.dat_active && !vif.reset;
    end
  endtask
endclass
