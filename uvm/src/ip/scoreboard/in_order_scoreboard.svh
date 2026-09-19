class in_order_scoreboard #(type ITEM = uvm_sequence_item) extends uvm_scoreboard;
  `uvm_component_param_utils(in_order_scoreboard#(ITEM))

  uvm_analysis_export #(ITEM) expected_export;
  uvm_analysis_export #(ITEM) actual_export;
  uvm_tlm_analysis_fifo #(ITEM) expected_fifo;
  uvm_tlm_analysis_fifo #(ITEM) actual_fifo;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
    expected_fifo   = new("expected_fifo", this);
    actual_fifo     = new("actual_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    expected_export.connect(expected_fifo.analysis_export);
    actual_export.connect(actual_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    ITEM expected;
    ITEM actual;
    forever begin
      expected_fifo.get(expected);
      actual_fifo.get(actual);
      if (!actual.compare(expected)) begin
        `uvm_error("IP_SCOREBOARD", $sformatf("Expected %s, got %s", expected.sprint(), actual.sprint()))
      end
    end
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_fifo.used() != 0 || actual_fifo.used() != 0) begin
      `uvm_error("IP_SCOREBOARD", $sformatf(
        "Unmatched transactions: expected=%0d actual=%0d",
        expected_fifo.used(), actual_fifo.used()
      ))
    end
  endfunction
endclass
