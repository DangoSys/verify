class env extends uvm_env;
  `uvm_component_utils(env)
  agent bus;
  system_model model;
  result_board #(completion, 1) scoreboard;
  uvm_analysis_imp #(bit, env) reset_export;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    reset_export = new("reset_export", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    model = system_model::type_id::create("model", this);
    bus = agent::type_id::create("bus", this);
    scoreboard = result_board#(completion, 1)::type_id::create("scoreboard", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    bus.endpoint.model = model;
    bus.mon.ap.connect(model.analysis_export);
    model.expected_ap.connect(scoreboard.expected_export);
    model.actual_ap.connect(scoreboard.actual_export);
    model.reset_ap.connect(reset_export);
  endfunction
  function void write(bit value);
    scoreboard.cancel_pending();
  endfunction
endclass
