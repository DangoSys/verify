class reset_controller extends uvm_component;
  `uvm_component_utils(reset_controller)
  virtual clock_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual clock_if)::get(this, "", "timing", vif))
      `uvm_fatal("CLOCK_INTERFACE", "Reset controller requires a timing interface")
  endfunction

  task pulse(int unsigned cycles);
    if (cycles == 0) `uvm_fatal("RESET_CYCLES", "Reset requires at least one sampled cycle")
    @(negedge vif.clock);
    vif.reset = 1;
    repeat (cycles) @(negedge vif.clock);
    vif.reset = 0;
  endtask
endclass
