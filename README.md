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
uvm/src/bb_blink_if.sv
uvm/src/agents/cmd/bb_blink_cmd_driver.svh
uvm/src/agents/cmd/bb_blink_cmd_monitor.svh
uvm/src/agents/cmd/bb_blink_cmd_agent.svh
uvm/src/agents/mem/bb_blink_mem_model.svh
uvm/src/agents/mem/bb_blink_mem_monitor.svh
uvm/src/agents/resp/bb_blink_resp_monitor.svh
uvm/src/cov/bb_blink_cov.svh
uvm/src/env/bb_blink_env.svh
```

Ball verify filelists should compile `bb_blink_if.sv` and `bb_uvm_pkg.sv` before the
Ball-specific package. Ball filelists use `@UVM@` and `@RTL@` placeholders for the
common UVM tree and the Ball RTL build output, respectively. The common package provides Blink transaction items, the
command agent, the bank read/write memory model and monitors, the command response
monitor, the protocol coverage collector, and the `bb_blink_env` base environment.

### +incdir notes

When compiling `bb_uvm_pkg.sv`, the following `+incdir+` entries are required so
that the nested `agents/...` includes resolve:

```text
+incdir+uvm/src
+incdir+uvm/src/agents/cmd
+incdir+uvm/src/agents/mem
+incdir+uvm/src/agents/resp
+incdir+uvm/src/cov
+incdir+uvm/src/env
```

`bb_uvm_pkg.sv` includes files in dependency order:

```text
defs -> items -> cmd driver -> cmd monitor -> cmd agent
      -> mem model -> mem monitor -> resp monitor -> cov -> env
```

## Ownership: framework vs ball

- **Framework-owned** (`uvm/src/`): everything shipped in this repo. The Blink
  transaction items, the `bb_blink_if` interface, the command agent (driver +
  monitor + agent), the bank read/write memory model and monitors, the response
  monitor, the protocol coverage collector (`bb_blink_cov`), and the base
  `bb_blink_env`. These are shared by every Ball and must not be edited by a
  Ball-local testbench.
- **Ball-owned** (Ball verify tree, e.g. `examples/balls/<ball>/verify/` in the
  Buckyball monorepo): the Ball-specific
  package, sequences, the Ball scoreboard, the Ball env subclass that extends
  `bb_blink_env` and adds the scoreboard + analysis connections, the test, and
  the filelist. A Ball extends `bb_blink_env#(IN,OUT)` and wires its scoreboard
  into the agent/monitor analysis ports exposed by the base env.

The base `bb_blink_env` constructs only the protocol-level pieces (cmd agent,
mem model, read/write/resp monitors, cov) and connects monitor APs to the
coverage collector. It deliberately leaves scoreboard construction and any
end-to-end checking to the Ball subclass.
