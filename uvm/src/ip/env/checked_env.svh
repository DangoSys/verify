class checked_env #(
    type REQUEST = uvm_sequence_item,
    type RESPONSE = REQUEST,
    type MODEL = uvm_component
) extends uvm_env;
  `uvm_component_param_utils(checked_env#(REQUEST, RESPONSE, MODEL))

  uvm_analysis_export #(REQUEST) input_export;
  uvm_analysis_export #(RESPONSE) output_export;
  MODEL model;
  in_order_scoreboard #(RESPONSE) scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    input_export  = new("input_export", this);
    output_export = new("output_export", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    model = MODEL::type_id::create("model", this);
    scoreboard = in_order_scoreboard#(RESPONSE)::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    input_export.connect(model.analysis_export);
    model.expected_ap.connect(scoreboard.expected_export);
    output_export.connect(scoreboard.actual_export);
  endfunction
endclass
