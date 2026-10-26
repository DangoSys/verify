class endpoint_driver extends uvm_component;
  `uvm_component_utils(endpoint_driver)
  virtual coherence_control_if control;
  virtual stream_if #(`COH_REQ_WIDTH) req;
  virtual stream_if #(`COH_RSP_WIDTH) rx_rsp;
  virtual stream_if #(`COH_DAT_WIDTH) rx_dat;
  virtual stream_if #(`COH_TXRSP_WIDTH) tx_rsp;
  virtual stream_if #(`COH_TXDAT_WIDTH) tx_dat;
  virtual stream_if #(`COH_SNP_CHANNEL_WIDTH) snp;
  virtual stream_if #(`COH_MEMREQ_WIDTH) mem_req;
  virtual stream_if #(`COH_MEMRESP_WIDTH) mem_resp;
  system_model model;
  bit rsp_active = 0, dat_active = 0, mem_active = 0;
  rsp_t rsp_packet = '0;
  dat_t dat_packet = '0;
  mem_t mem_packet = '0;
  int cycle = 0;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual coherence_control_if)::get(
            this, "", "control", control
        ) || !uvm_config_db#(virtual stream_if #(`COH_REQ_WIDTH))::get(
            this, "", "req", req
        ) || !uvm_config_db#(virtual stream_if #(`COH_RSP_WIDTH))::get(
            this, "", "rx_rsp", rx_rsp
        ) || !uvm_config_db#(virtual stream_if #(`COH_DAT_WIDTH))::get(
            this, "", "rx_dat", rx_dat
        ) || !uvm_config_db#(virtual stream_if #(`COH_TXRSP_WIDTH))::get(
            this, "", "tx_rsp", tx_rsp
        ) || !uvm_config_db#(virtual stream_if #(`COH_TXDAT_WIDTH))::get(
            this, "", "tx_dat", tx_dat
        ) || !uvm_config_db#(virtual stream_if #(`COH_SNP_CHANNEL_WIDTH))::get(
            this, "", "snp", snp
        ) || !uvm_config_db#(virtual stream_if #(`COH_MEMREQ_WIDTH))::get(
            this, "", "mem_req", mem_req
        ) || !uvm_config_db#(virtual stream_if #(`COH_MEMRESP_WIDTH))::get(
            this, "", "mem_resp", mem_resp
        ))
      `uvm_fatal("VIF", "Coherence interfaces missing")
  endfunction
  task run_phase(uvm_phase phase);
    rx_rsp.valid = 0;
    rx_rsp.bits = 0;
    rx_dat.valid = 0;
    rx_dat.bits = 0;
    mem_resp.valid = 0;
    mem_resp.bits = 0;
    tx_rsp.ready = 0;
    tx_dat.ready = 0;
    snp.ready = 0;
    mem_req.ready = 0;
    forever begin
      @(posedge control.clock);
      if (control.reset) begin
        rsp_active = 0;
        dat_active = 0;
        mem_active = 0;
      end else begin
        if (rsp_active && rx_rsp.ready) rsp_active = 0;
        if (dat_active && rx_dat.ready) dat_active = 0;
        if (mem_active && mem_resp.ready) mem_active = 0;
      end
      @(negedge control.clock);
      if (control.reset) begin
        rx_rsp.valid = 0;
        rx_dat.valid = 0;
        mem_resp.valid = 0;
        tx_rsp.ready = 0;
        tx_dat.ready = 0;
        snp.ready = 0;
        mem_req.ready = 0;
      end else begin
        cycle++;
        tx_rsp.ready = !model.hold_rsp && (cycle % 8) >= 4;
        tx_dat.ready = (cycle % 8) >= 4;
        snp.ready = !model.hold_snp && (cycle % 8) >= 4;
        mem_req.ready = !model.hold_mem_req && (cycle % 8) >= 4;
        if (!rsp_active) begin
          if (model.rsp_queue.size() != 0) begin
            rsp_packet = model.rsp_queue.pop_front();
            rsp_active = 1;
          end else begin
            int chosen = -1;
            foreach (model.ack_queue[j])
            if (chosen < 0 && !model.hold_ack[model.ack_queue[j][`CF(RSP, TXNID)]]) chosen = j;
            if (chosen >= 0) begin
              rsp_packet = model.ack_queue[chosen];
              model.ack_queue.delete(chosen);
              rsp_active = 1;
            end
          end
        end
        if (!dat_active && model.dat_queue.size() != 0 && (!model.hold_copyback || model.dat_queue[0][
            `CF(DAT, OPCODE)
            ] != `COH_COPYBACK_DATA)) begin
          dat_packet = model.dat_queue.pop_front();
          dat_active = 1;
        end
        if (!mem_active && !model.hold_memory && model.mem_queue.size() != 0) begin
          mem_packet = model.reverse_memory ? model.mem_queue.pop_back() : model.mem_queue.pop_front();
          mem_active = 1;
        end
        rx_rsp.valid = rsp_active;
        rx_rsp.bits = rsp_active || !model.vary_idle_payload ? rsp_packet : {`COH_RSP_WIDTH{model.idle_payload_one}};
        rx_dat.valid = dat_active;
        rx_dat.bits = dat_active || !model.vary_idle_payload ? dat_packet : {`COH_DAT_WIDTH{model.idle_payload_one}};
        mem_resp.valid = mem_active;
        mem_resp.bits = mem_active || !model.vary_idle_payload ? mem_packet : {`COH_MEMRESP_WIDTH{model.idle_payload_one}};
      end
    end
  endtask
endclass
