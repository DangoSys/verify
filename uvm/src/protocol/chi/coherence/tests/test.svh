class protocol_test extends base_test;
  `uvm_component_utils(protocol_test)
  env test_env;
  virtual coherence_control_if control;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    test_env = env::type_id::create("env", this);
    if (!uvm_config_db#(virtual coherence_control_if)::get(this, "", "control", control))
      `uvm_fatal("VIF", "Coherence timing interface is required")
    if (`COH_AGENTS < 2 || `COH_SETS < `COH_MSHRS || `COH_WAYS != 2)
      `uvm_fatal("CONFIG", "Coherence scenarios require two agents, two ways, and one set per MSHR")
  endfunction
  task execute();
    access_sequence seq = access_sequence::type_id::create("scenario");
    seq.test_env = test_env;
    seq.control  = control;
    seq.start(test_env.bus.seqr);
  endtask
endclass
