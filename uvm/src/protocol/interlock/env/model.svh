class ownership_model extends uvm_subscriber #(cycle_item);
  `uvm_component_utils(ownership_model)
  chandle model;
  int grants[int], completions[int];
  int reserved = 0, released = 0, cancelled = 0;
  uvm_analysis_port #(permit_item) expected_ap, actual_ap;
  covergroup activity with function sample (
      int live,
      bit allow,
      bit cpu_write,
      bit unknown,
      bit dispatched,
      bit was_cancelled,
      bit reset_live
  );
    option.per_instance = 1;
    occupancy: coverpoint live {
      bins empty = {0};
      bins partial = {[1 : `INTERLOCK_ENTRIES - 1]};
      bins full = {`INTERLOCK_ENTRIES};
    }
    permission: coverpoint allow;
    cpu_direction: coverpoint cpu_write;
    pending_dispatch: coverpoint unknown;
    reservation: coverpoint dispatched;
    cancellation: coverpoint was_cancelled;
    reset_cancellation: coverpoint reset_live;
    cpu_access: cross permission, cpu_direction;
  endgroup
  covergroup maintenance_kind with function sample (int op);
    option.per_instance = 1;
    operation: coverpoint op {bins clean = {0}; bins clean_invalidate = {1};}
  endgroup
  covergroup probes with function sample (bit differs);
    option.per_instance = 1;
    dispatch_probe_difference: coverpoint differs;
  endgroup
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
    actual_ap = new("actual_ap", this);
    probes = new();
    activity = new();
    maintenance_kind = new();
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    model = interlock_ref_create(`INTERLOCK_ENTRIES, `INTERLOCK_ADDRESS_BITS, `INTERLOCK_LINE_BYTES,
                                 `INTERLOCK_MAX_RANGES);
  endfunction
  function void write(cycle_item t);
    bus_signals s = t.sampled;
    int live = interlock_ref_live(model);
    int id;
    permit_item expected, actual;
    if (t.reset) begin
      activity.sample(live, 1, 0, 0, 0, 0, live != 0);
      cancelled += live;
      interlock_ref_reset(model);
      grants.delete();
      completions.delete();
      return;
    end
    if (`ILF(s.cpu_query_bits, CPU_QUERY, VALID)) begin
      expected = permit_item::type_id::create("expected");
      actual = permit_item::type_id::create("actual");
      expected.allow = interlock_ref_cpu_allow(
          model,
          `ILF(s.cpu_query_bits, CPU_QUERY, PADDR),
          1 <<
          `ILF(s.cpu_query_bits, CPU_QUERY, SIZELOG2),
          `ILF(s.cpu_query_bits, CPU_QUERY, WRITE),
          `ILF(s.cpu_query_bits, CPU_QUERY, OLDERDISPATCHPENDING),
          s.dispatch_valid && s.dispatch_ready
      );
      actual.allow = s.cpu_allow;
      expected_ap.write(expected);
      actual_ap.write(actual);
    end
    if (`ILF(s.cpu_query_bits, CPU_QUERY, VALID)) begin
      expected = permit_item::type_id::create("probe_expected");
      actual = permit_item::type_id::create("probe_actual");
      expected.probe = 1;
      actual.probe = 1;
      expected.allow = interlock_ref_cpu_allow(
          model,
          `ILF(s.cpu_query_bits, CPU_QUERY, PADDR),
          1 <<
          `ILF(s.cpu_query_bits, CPU_QUERY, SIZELOG2),
          `ILF(s.cpu_query_bits, CPU_QUERY, WRITE),
          `ILF(s.cpu_query_bits, CPU_QUERY, OLDERDISPATCHPENDING),
          0
      );
      actual.allow = s.cpu_probe_allow;
      expected_ap.write(expected);
      actual_ap.write(actual);
      probes.sample(s.cpu_allow != s.cpu_probe_allow);
    end else
      evidence::check(s.cpu_allow && s.cpu_probe_allow, "Inactive CPU query restricted permission");
    activity.sample(live, s.cpu_allow, `ILF(s.cpu_query_bits, CPU_QUERY, WRITE),
                    `ILF(s.cpu_query_bits, CPU_QUERY, OLDERDISPATCHPENDING),
                    s.dispatch_valid && s.dispatch_ready, s.cancel_valid && s.cancel_ready, 0);
    if (s.dispatch_valid && s.dispatch_ready) begin
      id = `ILF(s.dispatch_bits, DISPATCH, ID);
      interlock_ref_reserve(model, id);
      reserved++;
      grants[id] = 0;
      completions[id] = 0;
    end
    if (s.cancel_valid && s.cancel_ready) begin
      interlock_ref_cancel(model, `ILF(s.cancel_bits, CANCEL, ID));
      cancelled++;
    end
    if (s.access_info_valid && s.access_info_ready)
      interlock_ref_info(model, `ILF(s.access_info_bits, ACCESS_INFO, ID),
                         `ILF(s.access_info_bits, ACCESS_INFO, HASMEMORY),
                         `ILF(s.access_info_bits, ACCESS_INFO, BASE),
                         `ILF(s.access_info_bits, ACCESS_INFO, BYTES),
                         `ILF(s.access_info_bits, ACCESS_INFO, WRITE),
                         `ILF(s.access_info_bits, ACCESS_INFO, LAST));
    if (s.maintenance_valid && s.maintenance_ready) begin
      interlock_ref_maint_offer(model, `ILF(s.maintenance_bits, MAINTENANCE, TAG),
                                `ILF(s.maintenance_bits, MAINTENANCE, OP),
                                `ILF(s.maintenance_bits, MAINTENANCE, FIRSTLINE),
                                `ILF(s.maintenance_bits, MAINTENANCE, LASTLINE));
      maintenance_kind.sample(`ILF(s.maintenance_bits, MAINTENANCE, OP));
    end
    if (s.maintained_valid && s.maintained_ready) begin
      evidence::check(`ILF(s.maintained_bits, MAINTAINED, OK), "Cache ACK failed");
      interlock_ref_maint_ack(model, `ILF(s.maintained_bits, MAINTAINED, TAG));
    end
    if (s.grant_valid && s.grant_ready) begin
      id = `ILF(s.grant_bits, GRANT, TAG);
      interlock_ref_grant(model, id);
      grants[id]++;
    end
    if (s.done_valid && s.done_ready) begin
      evidence::check(`ILF(s.done_bits, DONE, OK), "DMA ACK failed");
      interlock_ref_dma_ack(model, `ILF(s.done_bits, DONE, TAG));
    end
    if (s.complete_valid && s.complete_ready) begin
      id = `ILF(s.complete_bits, COMPLETE, TAG);
      interlock_ref_complete(model, id);
      completions[id]++;
      released++;
    end
  endfunction
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    evidence::check(interlock_ref_live(model) == 0 && reserved == released + cancelled,
                    "Interlock left unmatched reservations");
  endfunction
  function void final_phase(uvm_phase phase);
    interlock_ref_destroy(model);
    super.final_phase(phase);
  endfunction
endclass
