`include "parameters.svh"
`define ILF(B, K, F) B[`INTERLOCK_``K``_``F``_OFFSET +: `INTERLOCK_``K``_``F``_WIDTH]
package interlock_types;
  typedef struct packed {
    logic [`INTERLOCK_DISPATCH_WIDTH-1:0] dispatch_bits;
    logic dispatch_valid, dispatch_ready;
    logic [`INTERLOCK_CANCEL_WIDTH-1:0] cancel_bits;
    logic cancel_valid, cancel_ready;
    logic [`INTERLOCK_ACCESS_INFO_WIDTH-1:0] access_info_bits;
    logic access_info_valid, access_info_ready;
    logic [`INTERLOCK_MAINTENANCE_WIDTH-1:0] maintenance_bits;
    logic maintenance_valid, maintenance_ready;
    logic [`INTERLOCK_MAINTAINED_WIDTH-1:0] maintained_bits;
    logic maintained_valid, maintained_ready;
    logic [`INTERLOCK_GRANT_WIDTH-1:0] grant_bits;
    logic grant_valid, grant_ready;
    logic [`INTERLOCK_DONE_WIDTH-1:0] done_bits;
    logic done_valid, done_ready;
    logic [`INTERLOCK_COMPLETE_WIDTH-1:0] complete_bits;
    logic complete_valid, complete_ready;
    logic [`INTERLOCK_CPU_QUERY_WIDTH-1:0] cpu_query_bits;
    logic cpu_allow, cpu_probe_allow;
  } bus_signals;
endpackage
