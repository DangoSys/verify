class axis_source_driver #(
    int DATA_BITS = 32
) extends uvm_driver #(axis_item #(DATA_BITS));
  typedef axis_item#(DATA_BITS) item;
  `uvm_component_param_utils(axis_source_driver#(DATA_BITS))

  virtual axis_if #(DATA_BITS) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if #(DATA_BITS))::get(this, "", "vif", vif)) begin
      `uvm_fatal("AXIS_VIF", "source driver requires vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    item req;
    vif.tvalid <= 1'b0;
    forever begin
      seq_item_port.get_next_item(req);
      do @(negedge vif.clock); while (vif.reset);
      vif.tvalid <= 1'b1;
      vif.tdata  <= req.data;
      vif.tkeep  <= req.keep;
      vif.tlast  <= req.last;
      do begin
        @(posedge vif.clock);
        if (vif.reset) `uvm_fatal("AXIS_RESET", "reset interrupted an active source transfer")
      end while (!vif.tready);
      @(negedge vif.clock);
      vif.tvalid <= 1'b0;
      seq_item_port.item_done();
    end
  endtask
endclass

class axis_monitor #(
    int DATA_BITS = 32
) extends uvm_monitor;
  typedef axis_item#(DATA_BITS) item;
  `uvm_component_param_utils(axis_monitor#(DATA_BITS))

  virtual axis_if #(DATA_BITS) vif;
  uvm_analysis_port #(item) ap;

  covergroup protocol_cov with function sample (bit valid, bit ready, bit last);
    option.per_instance = 1;
    handshake: coverpoint {
      valid, ready
    } {
      bins idle = {2'b00};
      bins ready_only = {2'b01};
      bins stalled = {2'b10};
      bins transferred = {2'b11};
    }
    packet_end: coverpoint last iff (valid && ready);
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    protocol_cov = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual axis_if #(DATA_BITS))::get(this, "", "vif", vif)) begin
      `uvm_fatal("AXIS_VIF", "monitor requires vif")
    end
  endfunction

  task run_phase(uvm_phase phase);
    item observed;
    forever begin
      @(posedge vif.clock);
      if (!vif.reset) protocol_cov.sample(vif.tvalid, vif.tready, vif.tlast);
      if (!vif.reset && vif.tvalid && vif.tready) begin
        observed = item::type_id::create("observed");
        observed.data = vif.tdata;
        observed.keep = vif.tkeep;
        observed.last = vif.tlast;
        ap.write(observed);
      end
    end
  endtask
endclass

class axis_source_agent #(
    int DATA_BITS = 32
) extends uvm_agent;
  typedef axis_item#(DATA_BITS) item;
  typedef axis_source_driver#(DATA_BITS) source_driver;
  typedef axis_monitor#(DATA_BITS) monitor;
  `uvm_component_param_utils(axis_source_agent#(DATA_BITS))

  uvm_sequencer #(item) seqr;
  source_driver driver;
  monitor mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr   = uvm_sequencer#(item)::type_id::create("seqr", this);
    driver = source_driver::type_id::create("driver", this);
    mon    = monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
