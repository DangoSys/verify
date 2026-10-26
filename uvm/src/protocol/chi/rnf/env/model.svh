class protocol_model extends uvm_subscriber #(sample_item);
  `uvm_component_utils(protocol_model)
  chandle reference;
  bit [511:0] memory[longint unsigned];
  longint unsigned wb_address[int unsigned], snoop_address;
  bit [511:0] snoop_data;
  bit [1:0] snoop_seen;
  bit [511:0] wb_data[int unsigned];
  bit [1:0] wb_seen[int unsigned];
  bit ack_pending[int unsigned];
  int home_allocations = 0, snoop_allocations = 0;
  int home_ids[$];
  int snoop_id;
  int fill_packets = 0, partial_goal = 0;
  bit hold_dat = 0, forbid_early_snoop = 0, expect_snoop_data = 0;
  bit [63:0] expected[$];
  bit expected_errors[$];
  bit [1:0] fail_read = 0;
  bit mixed_data_error = 0;
  rsp_t rx_rsp_queue[$];
  dat_t rx_dat_queue[$];
  int cycle = 0, submitted = 0, checked = 0, writebacks = 0, snoops = 0, peak = 0;
  bit hold_fill = 0, reverse_transactions = 0, hold_req = 0, hold_rsp = 0, hold_output_dat = 0;
  int cancelled_writebacks = 0, shared_writebacks = 0, cancelled_cpu = 0;
  bit rsp_active = 0, dat_active = 0;
  bit next_sc_success = 0, next_failed = 0;
  string scenario;
  pins_t sampled;
  pins_t idle;
  uvm_analysis_port #(result_item) expected_ap, actual_ap;
  uvm_analysis_port #(bit) reset_ap;
  covergroup behavior with function sample (int count, bit atomic, bit write);
    option.per_instance = 1;
    occupancy: coverpoint count {bins empty = {0}; bins single = {1}; bins full = {`CHI_BANKS};}
    atomic_operation: coverpoint atomic;
    write_request: coverpoint write;
  endgroup
  function new(string name, uvm_component parent);
    super.new(name, parent);
    behavior = new();
    expected_ap = new("expected_ap", this);
    actual_ap = new("actual_ap", this);
    reset_ap = new("reset_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!$value$plusargs("CASE=%s", scenario)) `uvm_fatal("CASE", "CHI scenario is required")
    idle = '0;
    reference = rnf_ref_create(44);
    home_ids.push_back(0);
    home_ids.push_back(4095);
    // Odd multiplication and Gray coding form a permutation of all 12-bit IDs.
    // This avoids correlating a cache bank or response kind with fixed ID bits.
    for (int i = 0; i < 4096; i++) begin
      int encoded = (i * 4051) & 4095;
      int id = encoded ^ (encoded >> 1);
      if (id != 0 && id != 4095) home_ids.push_back(id);
    end

  endfunction
  function int allocate_home_id();
    int id;
    if (home_allocations >= 4096) `uvm_fatal("HOME_ID", "Test exhausted the 12-bit Home ID pool")
    home_allocations++;
    return home_ids.pop_front();
  endfunction
  function void consume_req(req_t r);
    rsp_t response = '0;
    dat_t d = '0;
    if (r.src != 1 || r.tgt != 64 || r.txn >= 2 || r.size != 6 || r.addr[5:0] != 0 || !r.allow_retry)
      `uvm_fatal("REQ", "RN-F request outside declared no-retry Home contract")
    response.src = 64;
    response.tgt = 1;
    response.txn = r.txn;
    if (r.opcode == 'h26 || r.opcode == 'h07) begin
      if (!r.exp_comp_ack || !memory.exists(r.addr))
        `uvm_fatal("READ", "Uninitialized read or missing CompAck")
      d.src = 64;
      d.tgt = 1;
      d.home = 64;
      d.txn = r.txn;
      d.dbid = allocate_home_id();
      ack_pending[d.dbid] = 1;
      if (scenario == "bad_dbid_width") begin
        d.dbid = 'h1000;
      end
      // B9.1.3 permits any Resp for NDERR; both packets must retain it.
      d.opcode = 4;
      d.error = fail_read;
      d.resp = fail_read == 3 ? 7 : r.opcode == 'h07 ? 2 : 1;
      d.be = '1;
      // Return the upper 256b first; DataID units are 128b.
      d.data_id = 2;
      d.data = fail_read ? 0 : memory[r.addr][511:256];
      rx_dat_queue.push_back(d);
      d.data_id = 0;
      d.data = fail_read ? 0 : memory[r.addr][255:0];
      if (mixed_data_error) d.error = 0;  // first packet error must survive a clean final packet
      if (scenario == "bad_dbid") begin
        d.dbid = d.dbid ^ 16'h0001;
      end
      if (scenario == "bad_resp") begin
        d.resp = 2;
      end
      rx_dat_queue.push_back(d);
    end else if (r.opcode == 'h1b) begin
      response.dbid   = allocate_home_id();
      response.opcode = 5;
      rx_rsp_queue.push_back(response);
      wb_address[response.dbid] = r.addr;
      wb_seen[response.dbid] = 0;
    end else if (r.opcode == 'h0d) begin
      response.opcode = 4;
      rx_rsp_queue.push_back(response);
    end else `uvm_fatal("REQ", "Unexpected request opcode")
  endfunction
  function void consume_data(dat_t d);
    bit [511:0] golden;
    int index;
    if (d.tgt != 64 || d.src != 1 || !(d.data_id == 0 || d.data_id == 2))
      `uvm_fatal("DAT", "Unexpected RN-F data endpoint/DataID")
    index = d.data_id / 2;
    if (d.opcode == 2) begin
      if (d.resp == 0 && (d.be != 0 || d.data != 0))
        `uvm_fatal("WB_ZERO_DATA", "CopyBack_I must carry zero data and zero byte enables")
      if (!wb_address.exists(d.txn) || wb_seen[d.txn][index])
        `uvm_fatal("WB", "Unknown/duplicate writeback")
      wb_seen[d.txn][index] = 1;
      wb_data[d.txn][index*256+:256] = d.data;
      if (!(&d.be) && d.resp != 0) `uvm_fatal("WB", "Valid writeback has empty BE")
      if (&wb_seen[d.txn]) begin
        if (d.resp == 0) begin
          if (d.be != 0) `uvm_fatal("WB", "Cancelled writeback carries valid bytes")
          cancelled_writebacks++;
        end else begin
          if (rnf_ref_read(reference, wb_address[d.txn], golden) || wb_data[d.txn] !== golden)
            `uvm_fatal("WB", "Dirty writeback differs from independent reference")
          memory[wb_address[d.txn]] = wb_data[d.txn];
          if (d.resp == 1) shared_writebacks++;
        end
        writebacks++;
        wb_address.delete(d.txn);
        wb_data.delete(d.txn);
        wb_seen.delete(d.txn);
      end
    end else if (d.opcode == 1) begin
      if (forbid_early_snoop && fill_packets < partial_goal)
        `uvm_fatal("SNOOP_EARLY", "Same-line snoop responded before the final fill packet")
      if (d.txn != snoop_id || !(&d.be)) `uvm_fatal("SNOOP", "Unexpected snoop data")
      if (snoop_seen[index]) `uvm_fatal("SNOOP", "Duplicate snoop DataID")
      snoop_data[index*256+:256] = d.data;
      snoop_seen[index] = 1;
      if (&snoop_seen) begin
        if (rnf_ref_read(reference, snoop_address, golden) || snoop_data !== golden)
          `uvm_fatal("SNOOP", "Snoop differs from golden CPU data")
        memory[snoop_address] = snoop_data;
        snoops++;
      end
    end else `uvm_fatal("DAT", "Unexpected RN-F DAT opcode")
  endfunction
  function void write(sample_item t);
    pins_t s = t.sampled;
    sampled = s;
    behavior.sample(s.outstanding, s.access_valid && s.access_atomic != 0,
                    s.access_valid && s.access_write);

    if (s.reset) reset_ap.write(1);
    if (!s.reset) begin
      cycle++;
      if (s.outstanding > peak) peak = s.outstanding;
      if (s.rx_dat_valid && s.rx_dat_ready) fill_packets++;
      if (s.req_valid && s.req_ready) consume_req(req_t'(s.req));
      if (s.dat_valid && s.dat_ready) consume_data(dat_t'(s.dat));
      if (s.rsp_valid && s.rsp_ready) begin
        rsp_t r = rsp_t'(s.rsp);
        if (r.opcode != 2 && r.opcode != 1) `uvm_fatal("RSP", "Unexpected RN-F RSP opcode")
        if (r.src != 1 || r.tgt != 64) `uvm_fatal("RSP", "RN-F response endpoint mismatch")
        if (r.opcode == 2) begin
          if (!ack_pending.exists(r.txn))
            `uvm_fatal("ACK", "CompAck did not retain the independent Home DBID")
          ack_pending.delete(r.txn);
        end else begin
          if (forbid_early_snoop && fill_packets < partial_goal)
            `uvm_fatal("SNOOP_EARLY", "Same-line snoop responded before the final fill packet")
          if (expect_snoop_data)
            `uvm_fatal("SNOOP_DATA", "Cached RetToSrc snoop did not return data")
          if (r.txn != snoop_id)
            `uvm_fatal("SNOOP", "Dataless snoop response has wrong transaction")
          snoops++;
        end
      end
      if (s.access_valid && s.access_ready) begin
        bit [63:0] answer = rnf_ref_access(
            reference,
            s.access_addr,
            s.access_write,
            s.access_data,
            s.access_atomic,
            s.access_atomic_word,
            s.access_mask,
            next_sc_success,
            next_failed
        );
        result_item item = result_item::type_id::create("expected");
        expected.push_back(answer);
        expected_errors.push_back(next_failed);
        submitted++;
        item.data  = answer;
        item.error = next_failed;
        expected_ap.write(item);
      end
      if (s.result_valid && s.result_ready) begin
        bit [63:0] golden;
        bit error;
        if (!expected.size()) `uvm_fatal("RESULT", "Unexpected completion")
        golden = expected.pop_front();
        error  = expected_errors.pop_front();
        if (s.result_error != error || s.result_data !== golden)
          `uvm_fatal("RESULT", $sformatf(
                     "completion %0d got=%h expected=%h", checked, s.result_data, golden))
        checked++;
      end
      if (s.result_valid && s.result_ready) begin
        result_item item = result_item::type_id::create("actual");
        item.data  = s.result_data;
        item.error = s.result_error;
        actual_ap.write(item);
      end
      if (rsp_active && s.rx_rsp_ready) rsp_active = 0;
      if (dat_active && s.rx_dat_ready) dat_active = 0;
    end

  endfunction
  function void final_phase(uvm_phase phase);
    rnf_ref_destroy(reference);
    super.final_phase(phase);
  endfunction
endclass
