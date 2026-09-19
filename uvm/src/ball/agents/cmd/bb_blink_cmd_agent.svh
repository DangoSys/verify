class bb_blink_cmd_agent #(int IN_BW = 1, int OUT_BW = 1) extends uvm_agent;
  `uvm_component_param_utils(bb_blink_cmd_agent#(IN_BW, OUT_BW))

  uvm_sequencer #(bb_blink_cmd_item) seqr;
  bb_blink_cmd_driver #(IN_BW, OUT_BW) drv;
  bb_blink_cmd_monitor #(IN_BW, OUT_BW) mon;
  uvm_analysis_port #(bb_blink_cmd_item) stim_ap;
  uvm_analysis_port #(bb_blink_cmd_item) cmd_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    stim_ap = new("stim_ap", this);
    cmd_ap  = new("cmd_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = uvm_sequencer#(bb_blink_cmd_item)::type_id::create("seqr", this);
    drv  = bb_blink_cmd_driver#(IN_BW, OUT_BW)::type_id::create("drv", this);
    mon  = bb_blink_cmd_monitor#(IN_BW, OUT_BW)::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
    drv.stim_ap.connect(stim_ap);
    mon.cmd_ap.connect(cmd_ap);
  endfunction
endclass
