class bb_blink_resp_monitor #(int IN_BW = 1, int OUT_BW = 1) extends uvm_monitor;
  `uvm_component_param_utils(bb_blink_resp_monitor#(IN_BW, OUT_BW))

  typedef virtual bb_blink_if#(IN_BW, OUT_BW) vif_t;
  vif_t vif;
  uvm_analysis_port #(bb_blink_resp_item) resp_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    resp_ap = new("resp_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bb_blink_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    bb_blink_resp_item item;
    wait (vif.reset === 1'b0);
    forever begin
      @(posedge vif.clock);
      if (vif.cmd_resp_valid && vif.cmd_resp_ready) begin
        item = bb_blink_resp_item::type_id::create("item");
        item.rob_id     = vif.cmd_resp_bits_rob_id;
        item.is_sub     = vif.cmd_resp_bits_is_sub;
        item.sub_rob_id = vif.cmd_resp_bits_sub_rob_id;
        resp_ap.write(item);
      end
    end
  endtask
endclass
