class axis_monitor #(int DATA_BITS = 32) extends uvm_monitor;
  `uvm_component_param_utils(axis_monitor#(DATA_BITS))
  virtual axis_if#(DATA_BITS) vif;
  uvm_analysis_port #(axis_item#(DATA_BITS)) ap;

  covergroup protocol with function sample(bit valid, bit ready, bit last);
    option.per_instance = 1;
    handshake: coverpoint {valid, ready} { bins states[] = {[0:3]}; }
    packet_end: coverpoint last iff (valid && ready);
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
    protocol = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if#(DATA_BITS))::get(this, "", "vif", vif))
      `uvm_fatal("AXIS_INTERFACE", "Monitor interface is required")
  endfunction

  task run_phase(uvm_phase phase);
    axis_item#(DATA_BITS) observed;
    forever begin
      @(posedge vif.clock);
      if (vif.reset) continue;
      protocol.sample(vif.tvalid, vif.tready, vif.tlast);
      if (!vif.tvalid || !vif.tready) continue;
      observed = axis_item#(DATA_BITS)::type_id::create("observed");
      observed.data = vif.tdata;
      observed.keep = vif.tkeep;
      observed.last = vif.tlast;
      ap.write(observed);
    end
  endtask
endclass
