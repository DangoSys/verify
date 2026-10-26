class axis_sink #(int DATA_BITS = 32) extends uvm_component;
  `uvm_component_param_utils(axis_sink#(DATA_BITS))
  virtual axis_if#(DATA_BITS) vif;
  int unsigned ready_cycles;
  int unsigned stall_cycles;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if#(DATA_BITS))::get(this, "", "vif", vif))
      `uvm_fatal("AXIS_INTERFACE", "Sink interface is required")
    if (!$value$plusargs("SINK_READY=%d", ready_cycles) || ready_cycles == 0)
      `uvm_fatal("AXIS_READY", "A positive +SINK_READY is required")
    if (!$value$plusargs("SINK_STALL=%d", stall_cycles))
      `uvm_fatal("AXIS_STALL", "+SINK_STALL is required")
  endfunction

  task run_phase(uvm_phase phase);
    longint unsigned cycle = 0;
    vif.tready = 0;
    forever begin
      @(negedge vif.clock);
      vif.tready = !vif.reset && cycle % (ready_cycles + stall_cycles) < ready_cycles;
      cycle++;
    end
  endtask
endclass
