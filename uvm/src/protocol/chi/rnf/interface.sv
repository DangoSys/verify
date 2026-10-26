`include "parameters.svh"
interface chi_rnf_if (
    input logic clock
);
  logic reset;
  logic access_valid, access_ready, access_write;
  logic [43:0] access_addr;
  logic [63:0] access_data;
  logic [7:0] access_mask;
  logic [3:0] access_atomic;
  logic access_atomic_word;
  logic result_valid, result_ready, result_error;
  logic [63:0] result_data;
  logic req_valid, req_ready, rsp_valid, rsp_ready, dat_valid, dat_ready;
  logic rx_rsp_valid, rx_rsp_ready, rx_dat_valid, rx_dat_ready, snp_valid, snp_ready;
  logic [136:0] req;
  logic [70:0] rsp, rx_rsp;
  logic [388:0] dat, rx_dat;
  logic [93:0] snp;
  logic [31:0] outstanding;
  assert property (@(posedge clock) disable iff (reset)
    access_valid && !access_ready |=> access_valid && $stable(
      {access_addr, access_write, access_data, access_mask, access_atomic, access_atomic_word}
  ))
  else $fatal(1, "CHI channel changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    req_valid && !req_ready |=> req_valid && $stable(
      req
  ))
  else $fatal(1, "CHI channel changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    rsp_valid && !rsp_ready |=> rsp_valid && $stable(
      rsp
  ))
  else $fatal(1, "CHI channel changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    dat_valid && !dat_ready |=> dat_valid && $stable(
      dat
  ))
  else $fatal(1, "CHI channel changed under backpressure");
  assert property (@(posedge clock) disable iff (reset)
    result_valid && !result_ready |=> result_valid && $stable(
      {result_error, result_data}
  ))
  else $fatal(1, "CHI channel changed under backpressure");
endinterface
