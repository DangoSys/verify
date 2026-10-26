class access_sequence extends bus_sequence;
  `uvm_object_utils(access_sequence)
  ownership_model model;
  localparam int L = `INTERLOCK_LINE_BYTES;
  function new(string name = "access_sequence");
    super.new(name);
  endfunction
  task await_grant(int id);
    while (model.grants[id] != 1) tick();
  endtask
  task await_complete(int id);
    while (model.completions[id] != 1) tick();
  endtask
  task body();
    int high = (1 << `INTERLOCK_ID_BITS) - 1;
    longint unsigned last_line = (64'd1 << `INTERLOCK_ADDRESS_BITS) - L;
    joint_reset();
    query('h4000, 0, 0, 1);
    query('h4000, 0, 1);
    query('h4000, 1, 1);
    pins.cpu_query_bits = '0;
    `ILF(pins.cpu_query_bits, CPU_QUERY, VALID) = 1;
    `ILF(pins.cpu_query_bits, CPU_QUERY, PADDR) = 'h4000;
    `ILF(pins.cpu_query_bits, CPU_QUERY, SIZELOG2) = 3;
    reserve(high);

    query('h9000, 0, 0);
    pins.complete_ready = 0;
    info(high, 0, 0, 0, 0);
    tick(8);
    evidence::check(observed.complete_valid && model.grants[high] == 0,
                    "Nonmemory reservation did not complete directly");
    pins.complete_ready = 1;
    await_complete(high);
    // Fill every reservation slot with readers of the same line.
    pins.grant_ready = 0;
    for (int id = 0; id < `INTERLOCK_ENTRIES; id++) begin
      reserve(id);
      info(id, 1, 'h4000, L, 0);
    end
    query('h4000, 0, 1);
    query('h4000, 1, 0);
    query('h4000 + L, 1, 1);
    evidence::check(!observed.dispatch_ready, "Full reservation table remained ready");
    maintain();
    tick(5);
    evidence::check(observed.grant_valid, "Read grant disappeared during backpressure");
    pins.grant_ready = 1;
    repeat (`INTERLOCK_ENTRIES - 1) maintain();
    for (int id = 0; id < `INTERLOCK_ENTRIES; id++) await_grant(id);
    for (int id = `INTERLOCK_ENTRIES - 1; id >= 0; id--) begin
      finish_dma(id);
      await_complete(id);
    end
    query('h4000, 1, 1);
    // RAW: neither dependent DMA nor CPU may pass a writer's post-maintenance.
    reserve(0);
    info(0, 1, 'h6003, L - 3, 1);
    reserve(1);
    info(1, 1, 'h6000, L, 0);
    query('h6000, 0, 0);
    query('h6000 + L, 1, 1);
    maintain(0);
    await_grant(0);
    tick(8);
    evidence::check(model.grants[1] == 0, "RAW dependency passed a live writer");
    finish_dma(0);
    query('h6000, 0, 0);
    pins.complete_ready = 0;
    maintain(0);
    tick(8);
    evidence::check(model.grants[1] == 0 && observed.complete_valid,
                    "RAW dependency passed stalled completion");
    pins.complete_ready = 1;
    await_complete(0);
    maintain(1);
    await_grant(1);
    query('h6000, 0, 1);
    query('h6000, 1, 0);
    finish_dma(1);
    await_complete(1);
    // WAR and WAW are ordered, while another range can progress independently.
    reserve(0);
    info(0, 1, 'h7000, L, 0);
    reserve(1);
    info(1, 1, 'h7000, L, 1);
    maintain(0);
    await_grant(0);
    tick(5);
    evidence::check(model.grants[1] == 0, "WAR dependency bypassed a reader");
    finish_dma(0);
    await_complete(0);
    maintain(1);
    await_grant(1);
    reserve(0);
    info(0, 1, 'h7000, L, 1);
    tick(5);
    evidence::check(model.grants[0] == 0, "WAW dependency bypassed a writer");
    finish_dma(1);
    maintain(1);
    await_complete(1);
    maintain(0);
    await_grant(0);
    finish_dma(0);
    maintain(0);
    await_complete(0);
    reserve(0);
    reserve(1);
    info(1, 1, 'hA000, L, 0);
    query('hB000, 0, 0);
    evidence::check(!observed.maintenance_valid, "Known access passed older unknown reservation");
    info(0, 0, 0, 0, 0);
    await_complete(0);
    maintain(1);
    await_grant(1);
    finish_dma(1);
    await_complete(1);
    // All extent slots, including gaps, pre-maintenance and post-maintenance.
    reserve(0);
    for (int n = 0; n < `INTERLOCK_MAX_RANGES; n++) begin
      info(0, 1, 'h200000 + n * 2 * L, L, 1, n == `INTERLOCK_MAX_RANGES - 1);
      if (n != `INTERLOCK_MAX_RANGES - 1) query('h300000, 0, 0);
    end
    query('h200000 + L, 1, 1);
    query('h200000, 0, 0);
    repeat (`INTERLOCK_MAX_RANGES) maintain(0);
    await_grant(0);
    finish_dma(0);
    repeat (`INTERLOCK_MAX_RANGES) maintain(0);
    await_complete(0);
    query('h200000, 1, 1);
    // Cancel empty and partially described transactions, then reuse their IDs.
    reserve(0);
    query('h300000, 0, 0);
    cancel(0);
    query('h300000, 0, 1);
    reserve(0);
    if (`INTERLOCK_MAX_RANGES > 1) info(0, 1, 'h400000, L, 0, 0);
    cancel(0);
    query('h400000, 1, 1);
    reserve(0);
    info(0, 0, 0, 0, 0);
    await_complete(0);
    // The highest physical line and all legal CPU transfer widths.
    reserve(high);
    info(high, 1, last_line, L, 1);
    query(last_line, 0, 0);
    maintain(high);
    await_grant(high);
    finish_dma(high);
    maintain(high);
    await_complete(high);
    query(last_line, 0, 1);
    for (int size = 0; size <= 3; size++) query('h20000, 1, 1, 0, size);
    // Reset jointly cancels an active DMA and an unknown reservation.
    reserve(0);
    info(0, 1, 'hB000, L, 0);
    maintain(0);
    await_grant(0);
    reserve(1);
    query('hC000, 0, 0);
    joint_reset();
    query('hB000, 1, 1);
    reserve(0);
    info(0, 0, 0, 0, 0);
    await_complete(0);
    tick(2);
  endtask
endclass
