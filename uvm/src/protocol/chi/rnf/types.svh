`include "profile.svh"
package observed_types;
  typedef struct packed {
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
  } pins_t;
endpackage
