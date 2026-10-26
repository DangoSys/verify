class agent extends uvm_agent;
  `uvm_component_utils(agent)
  request_driver source;
  endpoint_driver endpoint;
  monitor mon;
  uvm_sequencer #(request_item) seqr;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    source = request_driver::type_id::create("source", this);
    endpoint = endpoint_driver::type_id::create("endpoint", this);
    mon = monitor::type_id::create("monitor", this);
    seqr = new("seqr", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    source.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
