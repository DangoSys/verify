class bus_sequence extends uvm_sequence #(cycle_item);
  `uvm_object_utils(bus_sequence)
  bus_signals pins = '0, observed;
  bit reset = 1;
  function new(string name = "bus_sequence");
    super.new(name);
  endfunction
  task tick(int cycles = 1);
    cycle_item req;
    repeat (cycles) begin
      req = cycle_item::type_id::create("cycle");
      start_item(req);
      req.pins  = pins;
      req.reset = reset;
      finish_item(req);
      observed = req.sampled;
    end
  endtask
  task joint_reset();
    pins  = '0;
    reset = 1;
    tick(4);
    reset = 0;
    pins.grant_ready = 1;
    pins.complete_ready = 1;
    tick();
  endtask
  task reserve(int id);
    pins.dispatch_bits = '0;
    `ILF(pins.dispatch_bits, DISPATCH, ID) = id;
    pins.dispatch_valid = 1;
    do tick(); while (!observed.dispatch_ready);
    pins.dispatch_valid = 0;
  endtask
  task info(int id, bit memory, longint unsigned base, bytes, bit write, bit last = 1);
    pins.access_info_bits = '0;
    `ILF(pins.access_info_bits, ACCESS_INFO, ID) = id;
    `ILF(pins.access_info_bits, ACCESS_INFO, HASMEMORY) = memory;
    `ILF(pins.access_info_bits, ACCESS_INFO, BASE) = base;
    `ILF(pins.access_info_bits, ACCESS_INFO, BYTES) = bytes;
    `ILF(pins.access_info_bits, ACCESS_INFO, WRITE) = write;
    `ILF(pins.access_info_bits, ACCESS_INFO, LAST) = last;
    pins.access_info_valid = 1;
    do tick(); while (!observed.access_info_ready);
    pins.access_info_valid = 0;
  endtask
  task cancel(int id);
    pins.cancel_bits = '0;
    `ILF(pins.cancel_bits, CANCEL, ID) = id;
    pins.cancel_valid = 1;
    do tick(); while (!observed.cancel_ready);
    pins.cancel_valid = 0;
  endtask
  task query(longint unsigned address, bit write, bit allow, bit older = 0, int size = 3);
    pins.cpu_query_bits = '0;
    `ILF(pins.cpu_query_bits, CPU_QUERY, VALID) = 1;
    `ILF(pins.cpu_query_bits, CPU_QUERY, PADDR) = address;
    `ILF(pins.cpu_query_bits, CPU_QUERY, WRITE) = write;
    `ILF(pins.cpu_query_bits, CPU_QUERY, OLDERDISPATCHPENDING) = older;
    `ILF(pins.cpu_query_bits, CPU_QUERY, SIZELOG2) = size;
    repeat (3) begin
      tick();
      evidence::check(observed.cpu_allow === allow, "Directed CPU permit mismatch");
    end
    pins.cpu_query_bits = '0;
  endtask
  task maintenance_accept(output int id);
    do tick(); while (!observed.maintenance_valid);
    id = `ILF(observed.maintenance_bits, MAINTENANCE, TAG);
    tick(3);
    pins.maintenance_ready = 1;
    do tick(); while (!observed.maintenance_valid);
    pins.maintenance_ready = 0;
  endtask
  task maintenance_ack(int id, bit ok = 1);
    pins.maintained_bits = '0;
    `ILF(pins.maintained_bits, MAINTAINED, TAG) = id;
    `ILF(pins.maintained_bits, MAINTAINED, OK) = ok;
    pins.maintained_valid = 1;
    do tick(); while (!observed.maintained_ready);
    pins.maintained_valid = 0;
  endtask
  task maintain(int expected_id = -1);
    int id;
    maintenance_accept(id);
    if (expected_id >= 0) evidence::check(id == expected_id, "Unexpected maintenance owner");
    tick(5);
    maintenance_ack(id);
  endtask
  task finish_dma(int id, bit ok = 1);
    pins.done_bits = '0;
    `ILF(pins.done_bits, DONE, TAG) = id;
    `ILF(pins.done_bits, DONE, OK) = ok;
    pins.done_valid = 1;
    do tick(); while (!observed.done_ready);
    pins.done_valid = 0;
  endtask
endclass
