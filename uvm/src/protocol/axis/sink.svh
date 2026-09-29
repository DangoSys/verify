class axis_sink #(
    int DATA_BITS = 32
) extends uvm_component;
  int unsigned ready_cycles = 1;
  int unsigned stall_cycles = 3;
  `uvm_component_param_utils(axis_sink#(DATA_BITS))

  virtual axis_if #(DATA_BITS) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if #(DATA_BITS))::get(this, "", "vif", vif)) begin
      `uvm_fatal("AXIS_VIF", "sink requires vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    int unsigned cycle = 0;
    if (ready_cycles == 0) `uvm_fatal("AXIS_CONFIG", "ready_cycles must be positive")
    vif.tready <= 1'b0;
    forever begin
      @(negedge vif.clock);
      cycle++;
      vif.tready <= !vif.reset && (cycle % (ready_cycles + stall_cycles)) < ready_cycles;
    end
  endtask
endclass
