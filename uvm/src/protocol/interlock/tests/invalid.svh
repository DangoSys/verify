class invalid_test extends base_test;
  `uvm_component_utils(invalid_test)
  agent bus;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    bus = agent::type_id::create("bus", this);
  endfunction
  task execute();
    invalid_sequence seq = invalid_sequence::type_id::create("scenario");
    seq.start(bus.seqr);
  endtask
endclass
