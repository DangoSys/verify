package bb_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "bb_blink_defs.svh"
  `include "bb_blink_items.svh"

  `include "agents/cmd/bb_blink_cmd_driver.svh"
  `include "agents/cmd/bb_blink_cmd_monitor.svh"
  `include "agents/cmd/bb_blink_cmd_agent.svh"

  `include "agents/mem/bb_blink_mem_model.svh"
  `include "agents/mem/bb_blink_mem_monitor.svh"

  `include "agents/resp/bb_blink_resp_monitor.svh"

  `include "cov/bb_blink_cov.svh"

  `include "env/bb_blink_env.svh"
endpackage
