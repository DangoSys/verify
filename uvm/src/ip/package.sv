package ip_pkg;
  timeunit 1ns; timeprecision 1ps;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "scoreboard/in_order_scoreboard.svh"
  `include "scoreboard/keyed_scoreboard.svh"
  `include "model/reference_model.svh"
  `include "env/checked_env.svh"
  `include "test/ip_test.svh"
endpackage
