package interlock_pkg;
  import uvm_pkg::*;
  import verification_pkg::*;
  import interlock_types::*;
  `include "uvm_macros.svh"
  import "DPI-C" function chandle interlock_ref_create(
    input int unsigned entries,
    address_bits,
    line_bytes,
    max_ranges
  );
  import "DPI-C" function void interlock_ref_destroy(input chandle model);
  import "DPI-C" function void interlock_ref_reset(input chandle model);
  import "DPI-C" function int unsigned interlock_ref_live(input chandle model);
  import "DPI-C" function void interlock_ref_reserve(
    input chandle model,
    input int unsigned id
  );
  import "DPI-C" function void interlock_ref_info(
    input chandle model,
    input int unsigned id,
    input byte unsigned has_mem,
    input longint unsigned base,
    bytes,
    input byte unsigned write,
    last
  );
  import "DPI-C" function byte unsigned interlock_ref_cpu_allow(
    input chandle model,
    input longint unsigned addr,
    input int unsigned bytes,
    input byte unsigned write,
    older_pending,
    reserve_now
  );
  import "DPI-C" function void interlock_ref_maint_offer(
    input chandle model,
    input int unsigned id,
    op,
    input longint unsigned first_line,
    last_line
  );
  import "DPI-C" function void interlock_ref_maint_ack(
    input chandle model,
    input int unsigned id
  );
  import "DPI-C" function void interlock_ref_grant(
    input chandle model,
    input int unsigned id
  );
  import "DPI-C" function void interlock_ref_dma_ack(
    input chandle model,
    input int unsigned id
  );
  import "DPI-C" function void interlock_ref_complete(
    input chandle model,
    input int unsigned id
  );
  import "DPI-C" function void interlock_ref_cancel(
    input chandle model,
    input int unsigned id
  );
  `include "agent/item.svh"
  `include "agent/driver.svh"
  `include "agent/monitor.svh"
  `include "agent/agent.svh"
  `include "env/model.svh"
  `include "env/env.svh"
  `include "seq/base.svh"
  `include "seq/sequence.svh"
  `include "seq/invalid.svh"
  `include "tests/test.svh"
  `include "tests/invalid.svh"
endpackage
