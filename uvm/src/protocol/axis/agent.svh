class axis_source_agent #(int DATA_BITS = 32) extends uvm_agent;
  `uvm_component_param_utils(axis_source_agent#(DATA_BITS))
  uvm_sequencer #(axis_item#(DATA_BITS)) seqr;
  axis_source_driver#(DATA_BITS) driver;
  axis_monitor#(DATA_BITS) mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = axis_monitor#(DATA_BITS)::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      seqr = uvm_sequencer#(axis_item#(DATA_BITS))::type_id::create("seqr", this);
      driver = axis_source_driver#(DATA_BITS)::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) driver.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
