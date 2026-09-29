interface axis_if #(
    int DATA_BITS = 32
) (
    input logic clock
);
  logic                   reset;
  logic                   tvalid;
  logic                   tready;
  logic [  DATA_BITS-1:0] tdata;
  logic [DATA_BITS/8-1:0] tkeep;
  logic                   tlast;

  property payload_stable_during_stall;
    @(posedge clock) disable iff (reset) tvalid && !tready |=> tvalid && $stable(
        {tdata, tkeep, tlast}
    );
  endproperty

  assert property (payload_stable_during_stall)
  else $fatal(1, "AXI-S payload changed while stalled");
  cover property (@(posedge clock) disable iff (reset) tvalid && !tready ##1 tvalid && tready);
endinterface
