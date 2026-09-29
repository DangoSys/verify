package framework_test_pkg;
  import uvm_pkg::*;
  import ip_pkg::*;
  import axis_vip_pkg::*;
  `include "uvm_macros.svh"
  typedef axis_item#(64) item;

  class scoreboard_test extends ip_test;
    `uvm_component_utils(scoreboard_test)
    in_order_scoreboard #(item) scoreboard;
    function new(string name, uvm_component parent);
      super.new(name, parent);
      timeout = 100ns;
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      scoreboard = in_order_scoreboard#(item)::type_id::create("scoreboard", this);
    endfunction
    task execute();
      string scenario;
      item   value = item::type_id::create("value");
      if (!$value$plusargs("scenario=%s", scenario)) `uvm_fatal("CONFIG", "scenario required")
      value.data = 64'h12345678abcdef01;
      value.keep = '1;
      value.last = 1;
      case (scenario)
        "pair": begin
          scoreboard.expected_export.write(value);
          value.data = 0;
          #10ns;
          value.data = 64'h12345678abcdef01;
          scoreboard.actual_export.write(value);
          scoreboard.actual_export.write(value);
          #10ns;
          scoreboard.expected_export.write(value);
          scoreboard.wait_checked(2);
        end
        "missing", "timeout": begin
          scoreboard.expected_export.write(value);
          #10ns;
          if (scenario == "timeout") scoreboard.wait_checked(1);
        end
        "extra": scoreboard.actual_export.write(value);
        "mismatch": begin
          scoreboard.expected_export.write(value);
          value.data ^= 64'h8000000000000000;
          scoreboard.actual_export.write(value);
        end
        "unknown": begin
          scoreboard.expected_export.write(value);
          value.data[63] = 1'bx;
          scoreboard.actual_export.write(value);
        end
        "reset": begin
          scoreboard.expected_export.write(value);
          scoreboard.cancel_pending();
          scoreboard.expected_export.write(value);
          scoreboard.actual_export.write(value);
          scoreboard.wait_checked(1);
        end
        default: `uvm_fatal("CONFIG", "unknown scenario")
      endcase
    endtask
  endclass

  class wide_sequence extends uvm_sequence #(item);
    `uvm_object_utils(wide_sequence)
    in_order_scoreboard #(item) scoreboard;
    function new(string name = "wide_sequence");
      super.new(name);
    endfunction
    task body();
      item req;
      for (int i = 0; i < 17; i++) begin
        req = item::type_id::create("req");
        start_item(req);
        req.data = {$urandom(), $urandom()};
        req.keep = i;
        req.last = (i % 3 == 0);
        scoreboard.expected_export.write(req);
        finish_item(req);
      end
    endtask
  endclass

  class axis64_test extends ip_test;
    `uvm_component_utils(axis64_test)
    axis_source_agent #(64) source;
    axis_sink #(64) sink;
    in_order_scoreboard #(item) scoreboard;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      source = axis_source_agent#(64)::type_id::create("source", this);
      sink = axis_sink#(64)::type_id::create("sink", this);
      scoreboard = in_order_scoreboard#(item)::type_id::create("scoreboard", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      source.mon.ap.connect(scoreboard.actual_export);
    endfunction
    task execute();
      wide_sequence seq = wide_sequence::type_id::create("seq");
      seq.scoreboard = scoreboard;
      sink.stall_cycles = 0;
      seq.start(source.seqr);
      scoreboard.wait_checked(17);
      sink.stall_cycles = 5;
      seq.start(source.seqr);
      scoreboard.wait_checked(34);
      `uvm_info("AXIS64", "Checked 34 transfers with and without backpressure", UVM_LOW)
    endtask
  endclass
endpackage

module framework_tb;
  import uvm_pkg::*;
  import framework_test_pkg::*;
  logic clock = 0;
  always #5 clock = ~clock;
  axis_if #(64) stream (clock);
  initial begin
    stream.reset = 1;
    repeat (4) @(negedge clock);
    stream.reset = 0;
  end
  initial begin
    uvm_config_db#(virtual axis_if #(64))::set(null, "uvm_test_top.source.*", "vif", stream);
    uvm_config_db#(virtual axis_if #(64))::set(null, "uvm_test_top.sink", "vif", stream);
    run_test();
  end
endmodule
