class bb_blink_env #(int IN_BW = 1, int OUT_BW = 1) extends uvm_env;
  `uvm_component_param_utils(bb_blink_env#(IN_BW, OUT_BW))

  bb_blink_cmd_agent#(IN_BW, OUT_BW)  cmd_agent;
  bb_blink_mem_model#(IN_BW, OUT_BW)  mem_model;
  bb_blink_read_monitor#(IN_BW, OUT_BW)  read_mon;
  bb_blink_write_monitor#(IN_BW, OUT_BW) write_mon;
  bb_mmio_read_monitor#(IN_BW, OUT_BW) mmio_read_mon;
  bb_mmio_write_monitor#(IN_BW, OUT_BW) mmio_write_mon;
  bb_blink_resp_monitor#(IN_BW, OUT_BW) resp_mon;
  bb_blink_cov#(IN_BW, OUT_BW) cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cmd_agent = bb_blink_cmd_agent#(IN_BW, OUT_BW)::type_id::create("cmd_agent", this);
    mem_model = bb_blink_mem_model#(IN_BW, OUT_BW)::type_id::create("mem_model", this);
    read_mon  = bb_blink_read_monitor#(IN_BW, OUT_BW)::type_id::create("read_mon", this);
    write_mon = bb_blink_write_monitor#(IN_BW, OUT_BW)::type_id::create("write_mon", this);
    mmio_read_mon = bb_mmio_read_monitor#(IN_BW, OUT_BW)::type_id::create("mmio_read_mon", this);
    mmio_write_mon = bb_mmio_write_monitor#(IN_BW, OUT_BW)::type_id::create("mmio_write_mon", this);
    resp_mon  = bb_blink_resp_monitor#(IN_BW, OUT_BW)::type_id::create("resp_mon", this);
    cov       = bb_blink_cov#(IN_BW, OUT_BW)::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    cmd_agent.cmd_ap.connect(cov.cmd_imp);
    read_mon.read_ap.connect(cov.read_imp);
    write_mon.write_ap.connect(cov.write_imp);
    resp_mon.resp_ap.connect(cov.resp_imp);
  endfunction
endclass
