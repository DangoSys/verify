interface interlock_if (
    input logic clock
);
  import interlock_types::*;
  logic reset = 1;
  bus_signals signals;
  assert property (@(posedge clock) disable iff (reset)
    signals.dispatch_valid && !signals.dispatch_ready |=> signals.dispatch_valid && $stable(
      signals.dispatch_bits
  ))
  else $fatal(1, "Interlock dispatch changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.cancel_valid && !signals.cancel_ready |=> signals.cancel_valid && $stable(
      signals.cancel_bits
  ))
  else $fatal(1, "Interlock cancel changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.access_info_valid && !signals.access_info_ready |=> signals.access_info_valid && $stable(
      signals.access_info_bits
  ))
  else $fatal(1, "Interlock access_info changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.maintenance_valid && !signals.maintenance_ready |=> signals.maintenance_valid && $stable(
      signals.maintenance_bits
  ))
  else $fatal(1, "Interlock maintenance changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.maintained_valid && !signals.maintained_ready |=> signals.maintained_valid && $stable(
      signals.maintained_bits
  ))
  else $fatal(1, "Interlock maintained changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.grant_valid && !signals.grant_ready |=> signals.grant_valid && $stable(
      signals.grant_bits
  ))
  else $fatal(1, "Interlock grant changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.done_valid && !signals.done_ready |=> signals.done_valid && $stable(
      signals.done_bits
  ))
  else $fatal(1, "Interlock done changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    signals.complete_valid && !signals.complete_ready |=> signals.complete_valid && $stable(
      signals.complete_bits
  ))
  else $fatal(1, "Interlock complete changed under backpressure");
endinterface
