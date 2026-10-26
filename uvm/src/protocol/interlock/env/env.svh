class env extends uvm_env;
  `uvm_component_utils(env)
  agent bus;
  ownership_model model;
  result_board #(permit_item, 0) scoreboard;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    bus = agent::type_id::create("bus", this);
    model = ownership_model::type_id::create("model", this);
    scoreboard = result_board#(permit_item, 0)::type_id::create("scoreboard", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    bus.mon.ap.connect(model.analysis_export);
    model.expected_ap.connect(scoreboard.expected_export);
    model.actual_ap.connect(scoreboard.actual_export);
  endfunction
endclass
