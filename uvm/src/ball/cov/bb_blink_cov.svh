class bb_blink_cov #(int IN_BW = 1, int OUT_BW = 1) extends uvm_component;
  `uvm_component_param_utils(bb_blink_cov#(IN_BW, OUT_BW))

  int cmd_fire_count;
  int read_fire_count[IN_BW];
  int write_fire_count[OUT_BW];
  int resp_fire_count;

  int cur_read_port;
  int cur_write_port;

  uvm_analysis_imp_cmd #(bb_blink_cmd_item, bb_blink_cov#(IN_BW, OUT_BW)) cmd_imp;
  uvm_analysis_imp_read #(bb_blink_read_item, bb_blink_cov#(IN_BW, OUT_BW)) read_imp;
  uvm_analysis_imp_write #(bb_blink_write_item, bb_blink_cov#(IN_BW, OUT_BW)) write_imp;
  uvm_analysis_imp_resp #(bb_blink_resp_item, bb_blink_cov#(IN_BW, OUT_BW)) resp_imp;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cmd_imp = new("cmd_imp", this);
    read_imp = new("read_imp", this);
    write_imp = new("write_imp", this);
    resp_imp = new("resp_imp", this);
  endfunction

  function void write_cmd(bb_blink_cmd_item item);
    cmd_fire_count++;
  endfunction

  function void write_read(bb_blink_read_item item);
    if (item.port < 0 || item.port >= IN_BW)
      `uvm_fatal("COV", $sformatf("read item port %0d out of range", item.port))
    cur_read_port = item.port;
    read_fire_count[item.port]++;
  endfunction

  function void write_write(bb_blink_write_item item);
    if (item.port < 0 || item.port >= OUT_BW)
      `uvm_fatal("COV", $sformatf("write item port %0d out of range", item.port))
    cur_write_port = item.port;
    write_fire_count[item.port]++;
  endfunction

  function void write_resp(bb_blink_resp_item item);
    resp_fire_count++;
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (cmd_fire_count == 0)
      `uvm_fatal("COV", "cmd handshake never fired")
    for (int i = 0; i < IN_BW; i++)
      if (read_fire_count[i] == 0)
        `uvm_fatal("COV", $sformatf("read port %0d never fired", i))
    for (int i = 0; i < OUT_BW; i++)
      if (write_fire_count[i] == 0)
        `uvm_fatal("COV", $sformatf("write port %0d never fired", i))
    if (resp_fire_count == 0)
      `uvm_fatal("COV", "resp never fired")
  endfunction
endclass
