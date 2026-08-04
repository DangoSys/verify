class bb_blink_read_monitor #(int IN_BW = 1, int OUT_BW = 1) extends uvm_monitor;
  `uvm_component_param_utils(bb_blink_read_monitor#(IN_BW, OUT_BW))

  typedef virtual bb_blink_if#(IN_BW, OUT_BW) vif_t;
  vif_t vif;
  uvm_analysis_port #(bb_blink_read_item) read_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    read_ap = new("read_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bb_blink_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    bb_blink_read_item item;
    wait (vif.reset === 1'b0);
    forever begin
      @(posedge vif.clock);
      for (int i = 0; i < IN_BW; i++) begin
        if (vif.bank_read_req_valid[i] && vif.bank_read_req_ready[i]) begin
          item = bb_blink_read_item::type_id::create("item");
          item.bank_id  = vif.bank_read_bank_id[i];
          item.rob_id   = vif.bank_read_rob_id[i];
          item.group_id = vif.bank_read_group_id[i];
          item.addr     = vif.bank_read_req_addr[i];
          item.port     = i;
          read_ap.write(item);
        end
      end
    end
  endtask
endclass

class bb_blink_write_monitor #(int IN_BW = 1, int OUT_BW = 1) extends uvm_monitor;
  `uvm_component_param_utils(bb_blink_write_monitor#(IN_BW, OUT_BW))

  typedef virtual bb_blink_if#(IN_BW, OUT_BW) vif_t;
  vif_t vif;
  uvm_analysis_port #(bb_blink_write_item) write_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    write_ap = new("write_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bb_blink_if not found")
  endfunction

  task run_phase(uvm_phase phase);
    bb_blink_write_item item;
    wait (vif.reset === 1'b0);
    forever begin
      @(posedge vif.clock);
      for (int i = 0; i < OUT_BW; i++) begin
        if (vif.bank_write_req_valid[i] && vif.bank_write_req_ready[i]) begin
          item = bb_blink_write_item::type_id::create("item");
          item.bank_id  = vif.bank_write_bank_id[i];
          item.rob_id   = vif.bank_write_rob_id[i];
          item.group_id = vif.bank_write_group_id[i];
          item.addr     = vif.bank_write_req_addr[i];
          item.mask     = vif.bank_write_req_mask[i];
          item.data    = vif.bank_write_req_data[i];
          item.port     = i;
          write_ap.write(item);
        end
      end
    end
  endtask
endclass
