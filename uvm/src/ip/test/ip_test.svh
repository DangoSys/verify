virtual class ip_test extends uvm_test;
  time timeout = 100us;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  pure virtual task execute();

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    fork
      execute();
      begin
        #(timeout);
        `uvm_fatal("IP_TIMEOUT", $sformatf("test exceeded %0t", timeout))
      end
    join_any
    disable fork;
    phase.drop_objection(this);
  endtask
endclass
