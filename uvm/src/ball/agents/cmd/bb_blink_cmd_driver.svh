class bb_blink_cmd_driver #(int IN_BW = 1, int OUT_BW = 1) extends uvm_driver #(bb_blink_cmd_item);
  `uvm_component_param_utils(bb_blink_cmd_driver#(IN_BW, OUT_BW))

  typedef virtual bb_blink_if#(IN_BW, OUT_BW) vif_t;
  vif_t vif;
  uvm_analysis_port #(bb_blink_cmd_item) stim_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    stim_ap = new("stim_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bb_blink_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    bb_blink_cmd_item item, stim;
    drive_idle();
    wait (vif.reset === 1'b0);
    forever begin
      seq_item_port.get_next_item(item);
      if (!$cast(stim, item.clone()))
        `uvm_fatal("DRV", "clone failed")
      stim_ap.write(stim);
      drive_cmd(item);
      seq_item_port.item_done();
    end
  endtask

  task drive_idle();
    vif.cmd_req_valid <= 1'b0;
    vif.cmd_req_bits_rob_id <= '0;
    vif.cmd_req_bits_funct <= '0;
    vif.cmd_req_bits_rs2 <= '0;
    vif.cmd_req_bits_iter <= '0;
    vif.cmd_req_bits_op1_bank <= '0;
    vif.cmd_req_bits_op2_bank <= '0;
    vif.cmd_req_bits_wr_bank <= '0;
    vif.cmd_req_bits_op1_group <= '0;
    vif.cmd_req_bits_op2_group <= '0;
    vif.cmd_req_bits_wr_group <= '0;
    vif.cmd_req_bits_op1_col <= '0;
    vif.cmd_req_bits_op2_col <= '0;
    vif.cmd_req_bits_wr_col <= '0;
    vif.cmd_req_bits_wr_read_bank <= '0;
    vif.cmd_req_bits_wr_arch_bank <= '0;
  endtask

  task drive_cmd(bb_blink_cmd_item item);
    @(posedge vif.clock);
    vif.cmd_req_valid <= 1'b1;
    vif.cmd_req_bits_rob_id <= item.rob_id;
    vif.cmd_req_bits_funct <= item.funct;
    vif.cmd_req_bits_rs2 <= item.rs2;
    vif.cmd_req_bits_iter <= item.iter;
    vif.cmd_req_bits_op1_bank <= item.op1_bank;
    vif.cmd_req_bits_op2_bank <= item.op2_bank;
    vif.cmd_req_bits_wr_bank <= item.wr_bank;
    vif.cmd_req_bits_op1_group <= item.op1_group;
    vif.cmd_req_bits_op2_group <= item.op2_group;
    vif.cmd_req_bits_wr_group <= item.wr_group;
    vif.cmd_req_bits_op1_col <= item.op1_col;
    vif.cmd_req_bits_op2_col <= item.op2_col;
    vif.cmd_req_bits_wr_col <= item.wr_col;
    vif.cmd_req_bits_wr_read_bank <= item.wr_read_bank;
    vif.cmd_req_bits_wr_arch_bank <= item.wr_arch_bank;
    do @(posedge vif.clock); while (!vif.cmd_req_ready);
    drive_idle();
  endtask
endclass
