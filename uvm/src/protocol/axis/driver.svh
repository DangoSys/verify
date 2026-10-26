class axis_source_driver #(int DATA_BITS = 32) extends uvm_driver #(axis_item#(DATA_BITS));
  `uvm_component_param_utils(axis_source_driver#(DATA_BITS))
  virtual axis_if#(DATA_BITS) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if#(DATA_BITS))::get(this, "", "vif", vif))
      `uvm_fatal("AXIS_INTERFACE", "Source interface is required")
  endfunction

  task run_phase(uvm_phase phase);
    axis_item#(DATA_BITS) transaction;
    vif.tvalid = 0;
    forever begin
      seq_item_port.get_next_item(transaction);
      do @(negedge vif.clock); while (vif.reset);
      vif.tdata = transaction.data;
      vif.tkeep = transaction.keep;
      vif.tlast = transaction.last;
      vif.tvalid = 1;
      do begin
        @(posedge vif.clock);
        if (vif.reset) `uvm_fatal("AXIS_RESET", "Reset cancelled an active source transaction")
      end while (!vif.tready);
      @(negedge vif.clock);
      vif.tvalid = 0;
      seq_item_port.item_done();
    end
  endtask
endclass
