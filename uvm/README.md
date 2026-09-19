# Common UVM Pieces

This directory contains reusable SystemVerilog/UVM pieces.

Current scope:

- `src/ball/bb_uvm_pkg.sv`: Ball package entry
- `src/ball/bb_blink_defs.svh`: Blink protocol widths used by generated Ball wrappers
- `src/ball/bb_blink_items.svh`: common Blink command, bank read/write, and response
  transaction items for Ball verification
- `src/ip/package.sv`: port-agnostic IP verification components
- analysis implementation suffix declarations used by Ball scoreboards and
  agents

The common package intentionally does not define a DUT interface. Ball wrappers
can differ in port counts and optional sideband ports, so each Ball verify tree
keeps its own interface and monitors.

Typical filelist usage from `examples/balls/<ball>/verify`:

```text
+incdir+../../../../verify/uvm/src/ball
../../../../verify/uvm/src/ball/bb_uvm_pkg.sv
```
