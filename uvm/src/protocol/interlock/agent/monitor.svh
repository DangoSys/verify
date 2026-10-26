class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  virtual interlock_if vif;
  uvm_analysis_port #(cycle_item) ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual interlock_if)::get(this, "", "vif", vif))
      `uvm_fatal("VIF", "Interlock monitor requires an interface")
  endfunction
  task run_phase(uvm_phase phase);
    cycle_item observed;
    forever begin
      @(posedge vif.clock);
      observed = cycle_item::type_id::create("observed");
      observed.sampled = vif.signals;
      observed.reset = vif.reset;
      ap.write(observed);
    end
  endtask
endclass
