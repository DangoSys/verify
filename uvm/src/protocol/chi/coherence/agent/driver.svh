class request_driver extends uvm_driver #(request_item);
  `uvm_component_utils(request_driver)
  virtual coherence_control_if control;
  virtual stream_if #(`COH_REQ_WIDTH) req;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual coherence_control_if)::get(
            this, "", "control", control
        ) || !uvm_config_db#(virtual stream_if #(`COH_REQ_WIDTH))::get(
            this, "", "req", req
        ))
      `uvm_fatal("VIF", "Coherence source interfaces are required")
  endfunction
  task run_phase(uvm_phase phase);
    request_item item;
    control.reset = 1;
    req.valid = 0;
    req.bits = '0;
    forever begin
      seq_item_port.get_next_item(item);
      @(negedge control.clock);
      req.valid = 0;
      if (item.reset_command) begin
        control.reset = 1;
        repeat (item.cycles) @(posedge control.clock);
        @(negedge control.clock);
        control.reset = 0;
        @(posedge control.clock);
      end else begin
        req.bits  = item.payload;
        req.valid = item.send;
        if (item.send) do @(posedge control.clock); while (!req.ready);
        else
          repeat (item.cycles) begin
            @(posedge control.clock);
            if (item.check_blocked)
              evidence::check(!req.ready, "Coherence accepted a colliding idle probe");
          end
      end
      @(negedge control.clock);
      req.valid = 0;
      seq_item_port.item_done();
    end
  endtask
endclass
