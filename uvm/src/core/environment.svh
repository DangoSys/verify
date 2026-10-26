class environment #(type REQUEST, type RESPONSE, type MODEL) extends uvm_env;
  `uvm_component_param_utils(environment#(REQUEST, RESPONSE, MODEL))
  uvm_analysis_export #(REQUEST) input_export;
  uvm_analysis_export #(RESPONSE) output_export;
  MODEL model;
  result_board #(RESPONSE, 0) scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    input_export = new("input_export", this);
    output_export = new("output_export", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    model = MODEL::type_id::create("model", this);
    scoreboard = result_board#(RESPONSE, 0)::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    input_export.connect(model.analysis_export);
    model.expected_ap.connect(scoreboard.expected_export);
    output_export.connect(scoreboard.actual_export);
  endfunction
endclass
