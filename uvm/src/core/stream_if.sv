interface stream_if #(
    int WIDTH = 1
) (
    input logic clock,
    reset
);
  logic valid, ready;
  logic [WIDTH-1:0] bits;
  clocking sample @(posedge clock);
    default input #1step;
    input valid, ready, bits;
  endclocking
  assert property (@(posedge clock) disable iff (reset) valid && !ready |=> valid && $stable(bits))
  else $fatal(1, "Stream payload changed under backpressure");
endinterface
