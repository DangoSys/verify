`include "clock_if.sv"

package verification_pkg;
  timeunit 1ns; timeprecision 1ps;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  `include "evidence.svh"
  `include "scoreboard.svh"
  `include "model.svh"
  `include "environment.svh"
  `include "reset.svh"
  `include "test.svh"
endpackage
