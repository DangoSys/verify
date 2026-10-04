interface axis_if #(
    int DATA_BITS = 32,
    int ID_BITS = 0,
    int DEST_BITS = 0,
    int USER_BITS = 0
) (
    input logic clock
);
  logic                   reset;
  logic                   tvalid;
  logic                   tready;
  logic [  DATA_BITS-1:0] tdata;
  logic [DATA_BITS/8-1:0] tkeep;
  logic                   tlast;

  logic [(ID_BITS > 0 ? ID_BITS : 1)-1:0] tid;
  logic [(DEST_BITS > 0 ? DEST_BITS : 1)-1:0] tdest;
  logic [(USER_BITS > 0 ? USER_BITS : 1)-1:0] tuser;
  if (ID_BITS == 0) assign tid = '0;
  if (DEST_BITS == 0) assign tdest = '0;
  if (USER_BITS == 0) assign tuser = '0;

  property payload_stable_during_stall;
    @(posedge clock) disable iff (reset) tvalid && !tready |=> tvalid && $stable(
        {tdata, tkeep, tlast, tid, tdest, tuser}
    );
  endproperty

  assert property (payload_stable_during_stall)
  else $fatal(1, "AXI-S payload changed while stalled");
  cover property (@(posedge clock) disable iff (reset) tvalid && !tready ##1 tvalid && tready);
endinterface
