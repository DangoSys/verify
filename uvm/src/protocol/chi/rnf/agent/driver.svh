class source_driver #(
    int PORT = 0
) extends uvm_driver #(packet_item);
  `uvm_component_param_utils(source_driver#(PORT))
  virtual chi_rnf_if vif;
  protocol_model state;
  packet_item pending;
  bit driven = 0;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual chi_rnf_if)::get(this, "", "vif", vif))
      `uvm_fatal("VIF", "CHI source interface is required")
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(negedge vif.clock);
      if (pending == null) seq_item_port.try_next_item(pending);
      driven = 0;
      if (PORT == 0) begin
        access_t a;
        if (pending != null) begin
          a = access_t'(pending.payload);
          state.next_sc_success = pending.sc_success;
          state.next_failed = pending.failed;
        end else
          a = '{
              address: state.idle.access_addr,
              write: state.idle.access_write,
              data: state.idle.access_data,
              mask: state.idle.access_mask,
              atomic: state.idle.access_atomic,
              word: state.idle.access_atomic_word
          };
        vif.access_addr = a.address;
        vif.access_write = a.write;
        vif.access_data = a.data;
        vif.access_mask = a.mask;
        vif.access_atomic = a.atomic;
        vif.access_atomic_word = a.word;
        vif.access_valid = pending != null;
        driven = pending != null;
      end else begin
        vif.snp = pending != null ? pending.payload : state.idle.snp;
        vif.snp_valid = pending != null;
        driven = pending != null;
      end
      @(posedge vif.clock);
      if (!vif.reset && driven && (PORT == 0 ? vif.access_ready : vif.snp_ready)) begin
        #1;
        seq_item_port.item_done();
        pending = null;
      end
    end
  endtask
endclass
