class bb_blink_cmd_monitor #(int IN_BW = 1, int OUT_BW = 1) extends uvm_monitor;
  `uvm_component_param_utils(bb_blink_cmd_monitor#(IN_BW, OUT_BW))

  typedef virtual bb_blink_if#(IN_BW, OUT_BW) vif_t;
  vif_t vif;
  uvm_analysis_port #(bb_blink_cmd_item) cmd_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cmd_ap = new("cmd_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bb_blink_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    bb_blink_cmd_item item;

    wait (vif.reset === 1'b0);
    forever begin
      @(posedge vif.clock);
      if (!vif.reset && vif.cmd_req_valid && vif.cmd_req_ready) begin
        item = bb_blink_cmd_item::type_id::create("item");
        item.rob_id = vif.cmd_req_bits_rob_id;
        item.funct = vif.cmd_req_bits_funct;
        item.rs2 = vif.cmd_req_bits_rs2;
        item.iter = vif.cmd_req_bits_iter;
        item.op1_bank = vif.cmd_req_bits_op1_bank;
        item.op2_bank = vif.cmd_req_bits_op2_bank;
        item.wr_bank = vif.cmd_req_bits_wr_bank;
        item.op1_group = vif.cmd_req_bits_op1_group;
        item.op2_group = vif.cmd_req_bits_op2_group;
        item.wr_group = vif.cmd_req_bits_wr_group;
        item.op1_col = vif.cmd_req_bits_op1_col;
        item.op2_col = vif.cmd_req_bits_op2_col;
        item.wr_col = vif.cmd_req_bits_wr_col;
        item.wr_read_bank = vif.cmd_req_bits_wr_read_bank;
        item.wr_arch_bank = vif.cmd_req_bits_wr_arch_bank;
        cmd_ap.write(item);
      end
    end
  endtask
endclass
