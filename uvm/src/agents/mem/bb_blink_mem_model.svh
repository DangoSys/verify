class bb_blink_mem_model #(int IN_BW = 1, int OUT_BW = 1) extends uvm_component;
  `uvm_component_param_utils(bb_blink_mem_model#(IN_BW, OUT_BW))

  typedef virtual bb_blink_if#(IN_BW, OUT_BW) vif_t;
  vif_t vif;

  localparam int RD_Q_DEPTH = 16;

  // bank -> group -> addr -> data (group_id is Blink routing metadata)
  bit [127:0] mem[int unsigned][int unsigned][int unsigned];
  bit have_stim;
  bit [127:0] rd_q[IN_BW][$];
  bit write_busy[OUT_BW];
  bit was_reset;
  bit rd_curr_valid[IN_BW];
  bit [127:0] rd_curr_data[IN_BW];
  bit [7:0] mmio_mem[8192];
  bit mmio_valid[8192];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bb_blink_if not found")
  endfunction

  function void load_word(int unsigned bank, int unsigned addr, bit [127:0] data);
    load_word_g(bank, 0, addr, data);
  endfunction

  function void load_word_g(int unsigned bank, int unsigned group, int unsigned addr,
                            bit [127:0] data);
    mem[bank][group][addr] = data;
  endfunction

  function void clear_mem();
    mem.delete();
    for (int i = 0; i < 8192; i++) mmio_valid[i] = 1'b0;
    have_stim = 1'b0;
  endfunction

  function void load_mmio_word(int unsigned addr, bit [31:0] data);
    for (int i = 0; i < 4; i++) begin
      mmio_mem[addr + i] = data[i*8 +: 8];
      mmio_valid[addr + i] = 1'b1;
    end
  endfunction

  function void arm();
    have_stim = 1'b1;
  endfunction

  task run_phase(uvm_phase phase);
    was_reset = 1'b0;
    forever begin
      @(posedge vif.clock);
      if (vif.reset) begin
        have_stim = 1'b0;
        for (int i = 0; i < IN_BW; i++) begin
          rd_q[i].delete();
          rd_curr_valid[i] = 1'b0;
          rd_curr_data[i] = '0;
        end
        for (int i = 0; i < OUT_BW; i++) write_busy[i] = 1'b0;
        if (!was_reset) begin
          for (int i = 0; i < IN_BW; i++) begin
            vif.bank_read_req_ready[i]  <= 1'b1;
            vif.bank_read_resp_data[i]  <= '0;
            if (IN_BW >= 2)
              vif.bank_read_resp_valid[i] = 1'b0;
            else
              vif.bank_read_resp_valid[i] <= 1'b0;
          end
          for (int i = 0; i < OUT_BW; i++) begin
            vif.bank_write_req_ready[i]  <= 1'b1;
            vif.bank_write_resp_valid[i] <= 1'b0;
            vif.bank_write_resp_ok[i]    <= 1'b1;
          end
          vif.cmd_resp_ready <= 1'b1;
          vif.sub_rob_req_ready <= 1'b1;
          for (int i = 0; i < 4; i++) begin
            vif.mmio_read_req_ready[i] <= 1'b1;
            vif.mmio_read_resp_valid[i] <= 1'b0;
            vif.mmio_read_resp_bits_data[i] <= '0;
            vif.mmio_write_req_ready[i] <= 1'b1;
          end
        end
        was_reset = 1'b1;
      end else begin
        was_reset = 1'b0;
        handle_read();
        handle_write();
        handle_mmio();
      end
    end
  endtask

  task handle_read();
    bit next_valid;
    bit [127:0] next_data;

    for (int i = 0; i < IN_BW; i++) begin
      if (IN_BW >= 2) begin
        if (rd_curr_valid[i] && vif.bank_read_resp_ready[i]) begin
          if (rd_q[i].size() == 0)
            `uvm_fatal("MEM", $sformatf("read port %0d: resp handshake with empty queue", i))
          void'(rd_q[i].pop_front());
        end
      end else if (vif.bank_read_resp_valid[i] && vif.bank_read_resp_ready[i]) begin
        if (rd_q[i].size() == 0)
          `uvm_fatal("MEM", $sformatf("read port %0d: resp handshake with empty queue", i))
        void'(rd_q[i].pop_front());
      end

      if (vif.bank_read_req_valid[i] && vif.bank_read_req_ready[i]) begin
        int unsigned bank;
        int unsigned group;
        int unsigned addr;
        bank = int'(vif.bank_read_bank_id[i]);
        group = int'(vif.bank_read_group_id[i]);
        addr = int'(vif.bank_read_req_addr[i]);
        if (!have_stim)
          `uvm_fatal("MEM", $sformatf("read port %0d: req before arm", i))
        if (!mem.exists(bank))
          `uvm_fatal("MEM", $sformatf("read port %0d: bank %0d not preloaded", i, bank))
        if (!mem[bank].exists(group))
          `uvm_fatal("MEM", $sformatf("read port %0d: group %0d not in bank %0d", i, group, bank))
        if (!mem[bank][group].exists(addr))
          `uvm_fatal("MEM", $sformatf("read port %0d: addr %0d not in bank %0d group %0d",
                                     i, addr, bank, group))
        if (rd_q[i].size() >= RD_Q_DEPTH)
          `uvm_fatal("MEM", $sformatf("read port %0d: queue overflow", i))
        rd_q[i].push_back(mem[bank][group][addr]);
      end

      next_valid = (rd_q[i].size() != 0);
      next_data = next_valid ? rd_q[i][0] : '0;

      if (IN_BW >= 2) begin
        // Blocking drive of 1-cycle registered resp. Multi-port NBA into
        vif.bank_read_resp_valid[i] = rd_curr_valid[i];
        vif.bank_read_resp_data[i] <= rd_curr_data[i];
        rd_curr_valid[i] = next_valid;
        rd_curr_data[i] = next_data;
      end else begin
        if (next_valid) begin
          vif.bank_read_resp_data[i]  <= next_data;
          vif.bank_read_resp_valid[i] <= 1'b1;
        end else begin
          vif.bank_read_resp_valid[i] <= 1'b0;
        end
      end

      vif.bank_read_req_ready[i] <= (rd_q[i].size() < RD_Q_DEPTH);
    end
  endtask

  task handle_write();
    for (int i = 0; i < OUT_BW; i++) begin
      if (write_busy[i] && vif.bank_write_resp_ready[i]) begin
        write_busy[i] = 1'b0;
        vif.bank_write_resp_valid[i] <= 1'b0;
      end

      if (!write_busy[i] &&
          vif.bank_write_req_valid[i] && vif.bank_write_req_ready[i]) begin
        vif.bank_write_resp_valid[i] <= 1'b1;
        vif.bank_write_resp_ok[i]    <= 1'b1;
        write_busy[i] = 1'b1;
      end

      vif.bank_write_req_ready[i] <= !write_busy[i];
    end
  endtask

  task handle_mmio();
    for (int i = 0; i < 4; i++) begin
      if (vif.mmio_read_resp_valid[i] && vif.mmio_read_resp_ready[i])
        vif.mmio_read_resp_valid[i] <= 1'b0;
      if (!vif.mmio_read_resp_valid[i] &&
          vif.mmio_read_req_valid[i] && vif.mmio_read_req_ready[i]) begin
        if (!mmio_valid[int'(vif.mmio_read_req_addr[i])])
          `uvm_fatal("MMIO", $sformatf("read of unwritten address %0d", vif.mmio_read_req_addr[i]))
        vif.mmio_read_resp_bits_data[i] <= mmio_mem[int'(vif.mmio_read_req_addr[i])];
        vif.mmio_read_resp_valid[i] <= 1'b1;
      end
      vif.mmio_read_req_ready[i] <= !vif.mmio_read_resp_valid[i];
      if (vif.mmio_write_req_valid[i] && vif.mmio_write_req_ready[i]) begin
        mmio_mem[int'(vif.mmio_write_req_addr[i])] = vif.mmio_write_req_data[i];
        mmio_valid[int'(vif.mmio_write_req_addr[i])] = 1'b1;
      end
      vif.mmio_write_req_ready[i] <= 1'b1;
    end
  endtask
endclass
