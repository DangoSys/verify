package ip_control_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "ip_test.svh"

  class protocol_test extends ip_test;
    `uvm_component_utils(protocol_test)
    virtual ip_control_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual ip_control_if)::get(this, "", "vif", vif))
        `uvm_fatal("VIF", "missing control interface")
      if (!uvm_config_db#(time)::get(this, "", "timeout", timeout))
        `uvm_fatal("TIMEOUT", "missing test timeout")
    endfunction

    task execute();
      @(negedge vif.clock);
      vif.start = 1;
      wait(vif.done);
    endtask
  endclass
endpackage
