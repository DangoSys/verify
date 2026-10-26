class scenario_sequence extends uvm_sequence;
  `uvm_object_utils(scenario_sequence)
  env test_env;
  protocol_model state;
  virtual chi_rnf_if vif;
  string scenario;
  function new(string name = "scenario_sequence");
    super.new(name);
  endfunction
  task packet(int port, logic [`CHI_DAT_BITS-1:0] payload, bit sc_success = 0, bit failed = 0);
    packet_sequence seq = packet_sequence::type_id::create("packet");
    seq.item = packet_item::type_id::create("item");
    seq.item.payload = payload;
    seq.item.sc_success = sc_success;
    seq.item.failed = failed;
    seq.start(test_env.bus.seqr[port]);
  endtask
  task issue(longint unsigned address, bit write = 0, bit [63:0] value = 0, int atomic = 0,
             bit [7:0] mask = '1, bit sc_success = 0, bit expect_error = 0, bit atomic_word = 0);
    access_t a;
    a = '{
        address: address,
        write: write,
        data: value,
        mask: mask,
        atomic: atomic,
        word: atomic_word
    };
    packet(0, a, sc_success, expect_error);
  endtask
  task settle();
    wait (state.checked + state.cancelled_cpu == state.submitted);
    while (state.ack_pending.num() != 0 || state.wb_address.num() != 0) @(negedge vif.clock);
    repeat (4) @(negedge vif.clock);
  endtask
  task access (longint unsigned address, bit write = 0, bit [63:0] value = 0, int atomic = 0,
               bit [7:0] mask = '1, bit sc_success = 0, bit expect_error = 0, bit atomic_word = 0);
    issue(address, write, value, atomic, mask, sc_success, expect_error, atomic_word);
    settle();
  endtask
  task snoop_line(longint unsigned address, int opcode, bit ret_source = 0);
    snp_t s = '0;
    int   before_count = state.snoops;
    state.expect_snoop_data = ret_source;
    state.snoop_id = state.snoop_allocations % 2 ? state.snoop_allocations / 2 : 4095 - state.snoop_allocations / 2;
    state.snoop_allocations++;
    s.src = 64;
    s.txn = state.snoop_id;
    s.addr = address >> 3;
    s.opcode = opcode;
    s.do_not_go_sd = 1;
    s.ret_to_src = ret_source;
    state.snoop_address = address;
    state.snoop_seen = 0;
    packet(1, s);
    wait (state.snoops > before_count);
    repeat (4) @(negedge vif.clock);
  endtask
  task partial_fill_snoop(longint unsigned target, longint unsigned probe, bit reverse);
    int before_packets = state.fill_packets;
    int before_snoops = state.snoops;
    state.reverse_transactions = reverse;
    issue(target);
    wait (state.fill_packets == before_packets + 1);
    state.hold_dat = 1;
    state.partial_goal = before_packets + 2;
    state.forbid_early_snoop = target == probe;
    fork
      snoop_line(probe, 4, 1);
      begin
        repeat (20) @(negedge vif.clock);
        if (target != probe && state.snoops == before_snoops)
          `uvm_fatal("SNOOP_INDEPENDENT",
                     "Different-line snoop waited for an unrelated final fill packet")
        state.hold_dat = 0;
      end
    join
    state.forbid_early_snoop   = 0;
    state.reverse_transactions = 0;
    settle();
  endtask
  task reset_pending_reads();
    bit [511:0] line;
    state.hold_fill = 1;
    issue(1024);
    issue(1088);
    wait (state.ack_pending.num() == 2);
    if (state.sampled.outstanding != 2 || state.expected.size() != 2)
      `uvm_fatal("RESET_PENDING", "Reset did not start with two pending reads")
    state.cancelled_cpu += state.expected.size();
    state.expected.delete();
    state.expected_errors.delete();
    state.ack_pending.delete();
    state.rx_dat_queue.delete();
    state.rx_rsp_queue.delete();
    state.rsp_active = 0;
    state.dat_active = 0;
    state.hold_fill  = 0;
    fork
      test_env.reset.pulse(4);
      begin
        wait (vif.reset);
        issue(2048);
      end
    join
    settle();
  endtask
  task idle_metadata();
    // Invalid payload is unconstrained; changing it must not create a transaction.
    for (int bank = 0; bank < 2; bank++) begin
      for (int field = 0; field < 6; field++) begin
        rsp_t r = '0;
        dat_t d = '0;
        snp_t probe = '0;
        r.src = 64;
        r.tgt = 1;
        r.txn = bank;
        d.opcode = 4;
        d.src = 64;
        d.tgt = 1;
        d.txn = bank;
        d.home = 64;
        probe.src = 64;
        probe.opcode = 4;
        case (field)
          0: begin
            r.tgt = 0;
            d.opcode = 0;
            probe.src = 0;
          end
          1: begin
            r.src = 0;
            d.src = 0;
            probe.pas = 1;
          end
          2: begin
            r.txn = bank ^ 1;
            d.tgt = 0;
            probe.fwd_nid = 1;
          end
          3: begin
            r.error = 3;
            d.home = 0;
            probe.fwd_txn = 1;
          end
          4: begin
            r.txn = 4095;
            d.txn = 4095;
            probe.opcode = 0;
          end
          5: begin
            d.data_id = 3;
            d.dbid = 16'hf000;
          end
        endcase
        @(negedge vif.clock);
        state.idle.rx_rsp = r;
        state.idle.rx_dat = d;
        state.idle.snp = probe;
        state.idle.access_addr = bank * 64 + 1;
        state.idle.access_atomic = 15;
        state.idle.access_atomic_word = 0;
        state.idle.access_write = 1;
        state.idle.access_mask = 0;
        repeat (2) @(negedge vif.clock);
      end
    end
    for (int bit_index = 0; bit_index < $bits(dat_t); bit_index++) begin
      @(negedge vif.clock);
      state.idle.rx_rsp = rsp_t'(rsp_t'(1) << bit_index);
      state.idle.rx_dat = dat_t'(dat_t'(1) << bit_index);
      state.idle.snp = snp_t'(snp_t'(1) << bit_index);
      state.idle.access_addr = 44'(1) << bit_index;
      state.idle.access_data = 64'(1) << bit_index;
      state.idle.access_mask = 8'(1) << bit_index;
      state.idle.access_atomic = 4'(1) << bit_index;
      state.idle.access_atomic_word = bit_index % 2;
      state.idle.access_write = bit_index % 2;
      repeat (2) @(negedge vif.clock);
      if (state.sampled.req_valid || state.sampled.rsp_valid || state.sampled.dat_valid || state.sampled.result_valid || state.sampled.outstanding)
        `uvm_fatal("IDLE_PAYLOAD", "Invalid walking-bit payload created CPU or CHI work")
    end
    if (state.sampled.req_valid || state.sampled.rsp_valid || state.sampled.dat_valid || state.sampled.result_valid || state.sampled.outstanding)
      `uvm_fatal("IDLE_PAYLOAD", "Invalid payload created CPU or CHI work")
    state.idle.rx_rsp = '0;
    state.idle.rx_dat = '0;
    state.idle.snp = '0;
    state.idle.access_addr = 0;
    state.idle.access_atomic = 0;
    state.idle.access_atomic_word = 0;
    state.idle.access_write = 0;
    state.idle.access_mask = '1;
  endtask
  task body();


    state.idle.access_atomic_word = 0;







    for (int i = 0; i < 256; i++) begin
      bit [511:0] initial_line;
      for (int j = 0; j < 8; j++)
      initial_line[j*64 +: 64] = (i%2 ? 64'h0f0f0f0f0f0f0f0f : 64'hf0f0f0f0f0f0f0f0) ^ 64'(i*8+j);
      state.memory[i*64] = initial_line;
      if (rnf_ref_write(state.reference, i * 64, initial_line, '1))
        `uvm_fatal("MODEL", "Initialization failed")
    end
    repeat (4) @(negedge vif.clock);
    test_env.reset.pulse(4);
    idle_metadata();
    state.hold_fill = 1;
    issue(0);
    issue(64);
    repeat (10) @(negedge vif.clock);
    if (state.sampled.outstanding != 2)
      `uvm_fatal("PARALLEL", "Both cache banks did not remain in flight")
    state.reverse_transactions = 1;
    state.hold_fill = 0;
    settle();
    state.reverse_transactions = 0;
    for (int line_index = 2; line_index < 8; line_index++) begin
      access (line_index * 64);
    end
    reset_pending_reads();
    for (int word = 1; word < 8; word++) begin
      access (word * 8);
      access (word * 8, 1, 64'h55aa55aa55aa55aa ^ 64'(word), 0, 8'hff >> word);
    end
    access (0, 1, 'h1122334455667788, 0, 'h0f);
    snoop_line(0, 4);  // downgrade dirty to shared
    access (0);
    access (0, 1, 'h8877665544332211);
    access (512);  // conflicting dirty victim
    access (0);
    for (int bank = 0; bank < 2; bank++) begin
      for (int op = 1; op <= 9; op++) begin
        // Exercise the independent hit and fill AMO datapaths with both comparisons.
        access (bank * 64, 1, 0);
        access (bank * 64, 0, 3, op);
        access (bank * 64, 0, 64'hfffffffffffffffe, op);
        snoop_line(bank * 64, 4);
        access (bank * 64, 0, 3, op);
        snoop_line(bank * 64, 4);
        access (bank * 64, 0, 64'hfffffffffffffffe, op);
        if (op >= 6) begin
          for (int refill = 0; refill < 2; refill++) begin
            access (bank * 64, 1, '1);
            if (refill) snoop_line(bank * 64, 4);
            access (bank * 64, 0, 0, op);
            access (bank * 64, 1, 0);
            if (refill) snoop_line(bank * 64, 4);
            access (bank * 64, 0, '1, op);
          end
        end
      end
      access (bank * 64, 0, 0, 10);
      access (bank * 64, 0, 99, 11, '1, 1);  // successful SC hit
      snoop_line(bank * 64, 4);
      access (bank * 64, 0, 0, 10);
      access (bank * 64, 0, 101, 11, '1, 1);  // successful SC fill
      access (bank * 64, 0, 0, 12);
    end
    // AMO.W uses an independent u32/i32 reference and must preserve the other lane.
    for (int bank = 0; bank < 2; bank++) begin
      for (int lane = 0; lane < 2; lane++) begin
        longint unsigned address = bank * 64 + lane * 4;
        bit [31:0] lhs_values[4] = '{32'hffffffff, 32'h80000000, 32'h7fffffff, 32'h0};
        bit [31:0] rhs_values[4] = '{32'h1, 32'h7fffffff, 32'h80000000, 32'hffffffff};
        for (int op = 1; op <= 9; op++) begin
          for (int boundary = 0; boundary < 4; boundary++) begin
            bit [63:0] initial_value = 64'h5aa55aa5a55aa55a;
            initial_value[lane*32+:32] = lhs_values[boundary];
            access (bank * 64, 1, initial_value);
            if (boundary % 2) snoop_line(bank * 64, 4);  // exercise refill permission upgrade
            // High operand bits are intentionally unrelated to the 32-bit operation.
            access (address, 0, {32'hdeadbeef, rhs_values[boundary]}, op, '1, 0, 0, 1);
            access (bank * 64);  // independently check both lane update and neighbor preservation
          end
        end
        access (address, 0, 0, 10, '1, 0, 0, 1);
        access (address, 0, 64'habcdef0180000001, 11, '1, 1, 0, 1);
        access (bank * 64);
        snoop_line(bank * 64, 4);
        access (address, 0, 0, 10, '1, 0, 0, 1);
        access (address, 0, 64'hffffffffffffffff, 11, '1, 1, 0, 1);
        access (bank * 64);
        access (address, 0, 0, 10, '1, 0, 0, 1);
        snoop_line(bank * 64, 7);
        access (address, 0, 99, 11, '1, 0, 0, 1);
        access (address, 0, 0, 10, '1, 0, 0, 1);
        access (bank * 64 + (1 - lane) * 4, 0, 77, 11, '1, 0, 0, 1);
        access (address, 0, 88, 11, '1, 0, 0, 1);  // failed other-lane SC consumes LR
        access (address, 0, 0, 10, '1, 0, 0, 1);
        access ((1 - bank) * 64, 0, 77, 11, '1, 0, 0, 1);
        access (address, 0, 88, 11, '1, 0, 0, 1);  // failed other-bank SC consumes LR
        access (address, 0, 0, 10, '1, 0, 0, 1);
        access ((1 - bank) * 64, 0, 0, 10);  // later LR.D replaces LR.W across banks
        access (address, 0, 88, 11, '1, 0, 0, 1);
      end
      access (bank * 64, 0, 0, 10, '1, 0, 0, 1);
      access (bank * 64, 0, 88, 11);  // same address, mismatched reservation width
      access (bank * 64, 0, 0, 10);
      access (bank * 64, 0, 88, 11, '1, 0, 0, 1);
      access (bank * 64, 0, 0, 10, '1, 0, 0, 1);
      snoop_line((1 - bank) * 64, 7);  // unrelated bank invalidation preserves reservation
      access (bank * 64, 0, 99, 11, '1, 1, 0, 1);
      access (bank * 64);
    end
    // Every word position uses both lane selectors in the hit and refill merge datapaths.
    for (int bank = 0; bank < 2; bank++) begin
      for (int word_index = 0; word_index < 8; word_index++) begin
        longint unsigned word_address = bank * 64 + word_index * 8;
        access (word_address, 1, 64'h800000007fffffff);
        for (int lane = 0; lane < 2; lane++) begin
          access (word_address + lane * 4, 0, 64'hdeadbeef00000001, 2, '1, 0, 0, 1);
          access (word_address);
          snoop_line(bank * 64, 4);
          access (word_address + lane * 4, 0, 64'hdeadbeefffffffff, 2, '1, 0, 0, 1);
          access (word_address);
        end
      end
    end
    access (576);  // dirty eviction through the second bank
    access (64);
    access (64, 0, 0, 10);
    access (64, 0, 99, 11, '1, 1);
    access (64, 0, 0, 10);
    snoop_line(64, 7);  // invalidate consumes LR
    access (64, 0, 123, 11);
    access (0, 0, 0, 10);
    access (64, 0, 123, 11);  // SC to other bank fails and consumes reservation
    access (0, 0, 123, 11);
    access (0, 0, 0, 12);
    snoop_line(448, 4);  // clean cached Shared line: dataless response
    snoop_line(1536, 9);  // absent line: dataless Invalid response
    state.fail_read = 2;
    access (768, 0, 0, 0, '1, 0, 1);
    state.fail_read = 0;
    access (768);  // errored fill must not leave a valid cache line
    access (512);  // write back the bank0 AMO/SC result before reset invalidates L1
    // Coordinated, quiescent reset invalidates L1; backing contents persist.
    @(negedge vif.clock);
    test_env.reset.pulse(4);
    issue(0);
    access (64);
    // Every legal high address bit must reach the tag compare and eviction path.
    for (int bit_index = 9; bit_index < 44; bit_index++) begin
      for (int cache_index = 0; cache_index < 8; cache_index++) begin
        longint unsigned high = (64'(1) << bit_index) | (64'(cache_index) << 6);
        bit [511:0] high_line = {8{(bit_index % 2 ? 64'h0123456789abcdef : ~64'h0123456789abcdef) ^ high}};
        state.memory[high] = high_line;
        if (rnf_ref_write(state.reference, high, high_line, '1))
          `uvm_fatal("MODEL", "High-tag init failed")
        access (high, 0, 0, 10);  // full-address LR reservation in each bank
        snoop_line(high, 4, 1);  // all entry indices and high Snoop addresses, full clean data
        access (high + 56, 1,
                (bit_index % 2 ? 64'h0123456789abcdef : ~64'h0123456789abcdef) ^ high);
        access (high + 8, 1,
                (bit_index % 2 ? ~64'h0123456789abcdef : 64'h0123456789abcdef) ^ high);  // hit-write R3 read port
        access (high);  // R0 hit-read port must observe the complementary full line
        access (cache_index * 64);  // dirty high-tag copyback retains the full address
      end
    end
    for (int bank = 0; bank < 2; bank++) begin
      access (bank * 64, 1, 64'h1234567890abcdef);
      state.hold_req = 1;
      issue(512 + bank * 64);
      begin
        req_t pending_request;
        do begin
          @(negedge vif.clock);
          pending_request = req_t'(state.sampled.req);
        end while (!state.sampled.req_valid || pending_request.opcode != 'h1b);
      end
      snoop_line(bank * 64, 7);  // revoke dirty victim while its WriteBackFull is queued
      begin
        bit [511:0] replacement = {8{64'hfedcba9876543210}};
        state.memory[bank*64] = replacement;
        if (rnf_ref_write(state.reference, bank * 64, replacement, '1))
          `uvm_fatal("MODEL", "Remote write failed")
      end
      state.hold_req = 0;
      settle();
      access (bank * 64);  // cancelled copyback must not overwrite the newer line
    end
    if (state.cancelled_writebacks == 0)
      `uvm_fatal("CANCEL", "Queued writeback cancellation did not execute")
    state.fail_read = 2;
    access (832, 0, 0, 0, '1, 0, 1);  // second bank error path
    state.fail_read = 0;
    access (832);
    access (448, 0, 0, 10);
    snoop_line(448, 4, 1);  // clean RetToSrc data must preserve LR reservation
    access (448, 0, 44, 11, '1, 1);
    for (int bank = 0; bank < 2; bank++) begin
      access (bank * 64, 1, 64'h0123456789abcdef);
      state.hold_req = 1;
      issue(512 + bank * 64);
      begin
        req_t pending_request;
        do begin
          @(negedge vif.clock);
          pending_request = req_t'(state.sampled.req);
        end while (!state.sampled.req_valid || pending_request.opcode != 'h1b);
      end
      snoop_line(bank * 64, 4);  // queued dirty victim is downgraded to Shared before copyback
      state.hold_req = 0;
      settle();
      access (bank * 64);
      for (int entry = 0; entry < 4; entry++) begin
        longint unsigned address = entry * 128 + bank * 64;
        access (address);
        snoop_line(address, 4);
        access (address, 0, 0, 10);
        state.hold_req = 1;
        issue(address, 0, 64'habcdef,
              11);  // initially valid LR, SC must fail after the intervening snoop
        begin
          req_t pending_request;
          do begin
            @(negedge vif.clock);
            pending_request = req_t'(state.sampled.req);
          end while (!state.sampled.req_valid || pending_request.opcode != 'h07);
        end
        snoop_line(address, 7);
        state.hold_req = 0;
        settle();
        access (address);  // failed SC fill acquired UC but must not modify the word
        access (address, 1, 64'h123456789abcdef0);  // clean UC hit becomes dirty
      end
    end
    for (int order = 0; order < 2; order++) begin
      access (0, 1, 64'h55aa55aa55aa55aa);
      access (64, 1, 64'haa55aa55aa55aa55);
      state.hold_output_dat = 1;
      issue(3072 + order * 64);
      issue(3136 - order * 64);  // both bank arrival orders
      repeat (60) @(negedge vif.clock);
      state.hold_output_dat = 0;
      settle();
    end
    // Fill both output request and response queues under sustained legal backpressure.
    state.hold_req = 1;
    state.hold_rsp = 1;
    issue(2560);
    issue(2624);
    repeat (30) @(negedge vif.clock);
    state.hold_req = 0;
    repeat (60) @(negedge vif.clock);
    fork
      snoop_line(16000, 9);  // third response meets two queued CompAcks
      begin
        repeat (20) @(negedge vif.clock);
        state.hold_rsp = 0;
      end
    join
    settle();
    for (int bank = 0; bank < 2; bank++) begin
      for (int entry = 0; entry < 4; entry++) begin
        longint unsigned address = entry * 128 + bank * 64;
        snoop_line(address, 7);
        snoop_line(address, 4);  // absent Shared snoop at each directory entry
        state.fail_read = entry % 2 ? 3 : 2;
        state.mixed_data_error = entry == 2;
        access (address, 0, 0, entry % 2 ? 0 : 10, '1, 0, 1);
        state.fail_read = 0;
        state.mixed_data_error = 0;
        access (((entry + 1) % 4) * 128 + bank * 64);  // a hit clears the previous response error
        access (address);
        access (address, 0, 0, 10);
        access (address);  // ordinary hit must retain LR
        access (address, 0, 11, 11, '1, 1);
      end
    end
    for (int bank = 0; bank < 2; bank++) begin
      access (bank * 64, 0, 0, 10);
      snoop_line(128 + bank * 64, 7);  // unrelated-line invalidation must preserve LR
      access (bank * 64, 0, 77, 11, '1, 1);
      access (bank * 64, 0, 0, 0, 0);  // a normal read does not consume byte enables
      fork
        issue(bank * 64);
        begin
          repeat (2) @(posedge vif.clock);
          snoop_line(256 + bank * 64, 4);  // snoop overlaps lookup and temporarily stops it
        end
      join
      settle();
    end
    access (128);  // independent-line probe must be resident after invalidation scenarios
    partial_fill_snoop(1024, 1024, 0);
    partial_fill_snoop(1536, 1536, 1);  // opposite DataID arrival order
    partial_fill_snoop(2048, 128, 0);  // same bank, independent cache line
    for (int bank = 0; bank < 2; bank++) begin
      access (bank * 64 + 56, 1, '1);
      access (bank * 64, 1, '1);  // full-width hit merge input includes the high word
      access (bank * 64 + 56, 1, 0);
      access (bank * 64, 1, 0);
      for (int word = 0; word < 8; word++) begin
        access (bank * 64 + word * 8, 0, 0, 10);
        access (bank * 64 + word * 8, 1, '1, 0, 8'hfe);
        access (bank * 64 + word * 8, 1, 0, 0, 8'h00);
        access (bank * 64 + word * 8);
      end
      access (bank * 64, 0, 0, 10);  // release high word-offset reservation bits
    end
    begin
      longint unsigned a = 24576;
      bit [511:0] fresh = '0;
      int before_alloc;
      state.memory[a] = fresh;
      if (rnf_ref_write(state.reference, a, fresh, '1))
        `uvm_fatal("MODEL", "CMO fixture initialization failed")
      access (a, 1, 64'h1122334455667788);
      snoop_line(a, 8);  // SnpCleanShared: pass dirty data, retain a clean shared copy.
      before_alloc = state.home_allocations;
      access (a);
      if (state.home_allocations != before_alloc)
        `uvm_fatal("CLEAN_SHARED", "SnpCleanShared invalidated a resident clean copy")
      access (a, 1, 64'hdeadbeef01234567);
      fresh[63:0] = 64'hcafebabe87654321;
      state.memory[a] = fresh;
      if (rnf_ref_write(state.reference, a, fresh, '1))
        `uvm_fatal("GOLDEN", "DMA test write was outside physical memory")
      snoop_line(a, 10);  // SnpMakeInvalid must not return stale dirty data.
      if (state.memory[a] !== fresh)
        `uvm_fatal("MAKE_INVALID", "Stale dirty data overwrote newer DMA memory")
      before_alloc = state.home_allocations;
      access (a);
      if (state.home_allocations != before_alloc + 1)
        `uvm_fatal("INVALID_REFILL", "SnpMakeInvalid did not invalidate the resident line")
      snoop_line(a, 8);  // Clean shared copy: dataless retained response.
      snoop_line(a, 10);
      snoop_line(a, 10);  // Absent line: dataless invalid response.
      `uvm_info("CMO", "SnpCleanShared retention and SnpMakeInvalid dirty discard checked", UVM_LOW)
    end
    if (state.shared_writebacks == 0)
      `uvm_fatal("SHARED_WB", "Downgraded victim did not return Shared copyback")
    if (state.peak < 2 || state.writebacks == 0 || state.snoops < 2 || state.expected.size())
      `uvm_fatal("COVERAGE", "Required parallel, dirty eviction or snoop case not exercised")
    `uvm_info(
        "RNF",
        $sformatf(
            "Checked %0d CPU completions, peak=%0d writebacks=%0d snoops=%0d cancelled=%0d shared=%0d reset_cancelled=%0d",
            state.checked, state.peak, state.writebacks, state.snoops, state.cancelled_writebacks,
            state.shared_writebacks, state.cancelled_cpu), UVM_LOW)

  endtask
endclass
