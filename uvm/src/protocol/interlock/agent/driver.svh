class driver extends uvm_driver #(cycle_item);
  `uvm_component_utils(driver)
  virtual interlock_if vif;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual interlock_if)::get(this, "", "vif", vif))
      `uvm_fatal("VIF", "Interlock driver requires an interface")
  endfunction
  task run_phase(uvm_phase phase);
    cycle_item req;
    forever begin
      seq_item_port.get_next_item(req);
      @(negedge vif.clock);
      vif.reset = req.reset;
      vif.signals.dispatch_bits = req.pins.dispatch_bits;
      vif.signals.dispatch_valid = req.pins.dispatch_valid;
      vif.signals.cancel_bits = req.pins.cancel_bits;
      vif.signals.cancel_valid = req.pins.cancel_valid;
      vif.signals.access_info_bits = req.pins.access_info_bits;
      vif.signals.access_info_valid = req.pins.access_info_valid;
      vif.signals.maintenance_ready = req.pins.maintenance_ready;
      vif.signals.maintained_bits = req.pins.maintained_bits;
      vif.signals.maintained_valid = req.pins.maintained_valid;
      vif.signals.grant_ready = req.pins.grant_ready;
      vif.signals.done_bits = req.pins.done_bits;
      vif.signals.done_valid = req.pins.done_valid;
      vif.signals.complete_ready = req.pins.complete_ready;
      vif.signals.cpu_query_bits = req.pins.cpu_query_bits;
      @(posedge vif.clock);
      req.sampled = vif.signals;
      #1;
      seq_item_port.item_done();
    end
  endtask
endclass
