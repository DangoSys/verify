# Verify
Verification Framework for buckyball

## Environment

This repository uses Nix and the UVM version is 1.2. We default there is VCS in the local EDA environment.


Enter the environment:

```console
nix develop
```

The dev shell exports:

```text
UVM_HOME
UVM_VERSION
VCS_UVM_ARGS
```

It also provides the Rust toolchain used by Ball-local DPI reference models:

```text
cargo
rustc
rustfmt
clippy
```

`VCS_UVM_ARGS` expands to the UVM 1.2 compile inputs needed by VCS:

```text
+incdir+$UVM_HOME/src $UVM_HOME/src/uvm.sv $UVM_HOME/src/dpi/uvm_dpi.cc -CFLAGS -DVCS
```

## Common UVM

Reusable Ball-level UVM pieces live under `uvm/`:

```text
uvm/src/bb_uvm_pkg.sv
uvm/src/bb_blink_defs.svh
uvm/src/bb_blink_items.svh
```

Ball verify filelists should compile `bb_uvm_pkg.sv` before the Ball-specific
package. The common package currently provides Blink transaction items for Ball
commands, bank read/write requests, and command responses.
