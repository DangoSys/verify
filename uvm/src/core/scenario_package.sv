package scenario_pkg;
  import uvm_pkg::*;
  import verification_pkg::*;
  `include "uvm_macros.svh"
  class protocol_test extends base_test;
    `uvm_component_utils(protocol_test)
    virtual scenario_if vif;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual scenario_if)::get(this, "", "vif", vif))
        `uvm_fatal("SCENARIO", "Missing scenario interface")
    endfunction
    task execute();
      @(negedge vif.clock);
      vif.start = 1;
      wait (vif.done);
      @(negedge vif.clock);
    endtask
  endclass
endpackage
