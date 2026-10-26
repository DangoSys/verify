class invalid_sequence extends bus_sequence;
  `uvm_object_utils(invalid_sequence)
  function new(string name = "invalid_sequence");
    super.new(name);
  endfunction
  task body();
    string scenario;
    int id;
    if (!$value$plusargs("CASE=%s", scenario)) `uvm_fatal("CASE", "Missing assertion scenario")
    joint_reset();
    case (scenario)
      "cancel_info": begin
        reserve(7);
        pins.cancel_valid = 1;
        `ILF(pins.cancel_bits, CANCEL, ID) = 7;
        pins.access_info_valid = 1;
        `ILF(pins.access_info_bits, ACCESS_INFO, ID) = 7;
        `ILF(pins.access_info_bits, ACCESS_INFO, LAST) = 1;
      end
      "cancel_sealed": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 0);
        cancel(7);
      end
      "cancel_unknown": cancel(7);
      "capacity": begin
        reserve(7);
        repeat (`INTERLOCK_MAX_RANGES) info(7, 1, 'h4000, 64, 0, 0);
      end
      "cpu_alignment": begin
        `ILF(pins.cpu_query_bits, CPU_QUERY, VALID) = 1;
        `ILF(pins.cpu_query_bits, CPU_QUERY, SIZELOG2) = 3;
        `ILF(pins.cpu_query_bits, CPU_QUERY, PADDR) = 'h4001;
      end
      "cpu_size": begin
        `ILF(pins.cpu_query_bits, CPU_QUERY, VALID) = 1;
        `ILF(pins.cpu_query_bits, CPU_QUERY, SIZELOG2) = 4;
      end
      "direction": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 0, 0);
        info(7, 1, 'h5000, 64, 1);
      end
      "dma_failed": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 1);
        pins.grant_ready = 0;
        maintain(7);
        pins.grant_ready = 1;
        do tick(); while (!observed.grant_valid);
        finish_dma(7, 0);
      end
      "dma_ungranted": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 1);
        finish_dma(7);
      end
      "dma_unknown": finish_dma(7);
      "duplicate": begin
        reserve(7);
        reserve(7);
      end
      "empty_range": begin
        reserve(7);
        info(7, 1, 'h4000, 0, 0);
      end
      "info_duplicate": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 0);
        info(7, 1, 'h4000, 64, 0);
      end
      "info_unknown": info(7, 1, 'h4000, 64, 0);
      "maint_failed": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 1);
        maintenance_accept(id);
        maintenance_ack(7, 0);
      end
      "maint_tag": begin
        reserve(7);
        info(7, 1, 'h4000, 64, 1);
        maintenance_accept(id);
        maintenance_ack(8);
      end
      "maint_unknown": maintenance_ack(7);
      "no_memory_seal": begin
        reserve(7);
        info(7, 0, 0, 0, 0, 0);
      end
      "overflow_range": begin
        reserve(7);
        info(7, 1, (64'd1 << `INTERLOCK_ADDRESS_BITS) - 64, 65, 0);
      end
      default: `uvm_fatal("CASE", "Unknown assertion scenario")
    endcase
    tick(20);
    `uvm_fatal("EXPECTED_ASSERTION", "Illegal stimulus did not trigger the DUT assertion")
  endtask
endclass
