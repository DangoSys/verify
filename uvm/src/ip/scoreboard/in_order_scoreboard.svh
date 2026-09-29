`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class in_order_scoreboard #(
    type ITEM = uvm_sequence_item
) extends uvm_scoreboard;
  `uvm_component_param_utils(in_order_scoreboard#(ITEM))

  uvm_analysis_imp_expected #(ITEM, in_order_scoreboard #(ITEM)) expected_export;
  uvm_analysis_imp_actual #(ITEM, in_order_scoreboard #(ITEM)) actual_export;
  ITEM expected_queue[$];
  ITEM actual_queue[$];
  int unsigned checked = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction

  function void write_expected(ITEM value);
    ITEM copy;
    if (!$cast(copy, value.clone())) `uvm_fatal("IP_ITEM", "expected clone has wrong type")
    expected_queue.push_back(copy);
    compare_pending();
  endfunction

  function void write_actual(ITEM value);
    ITEM copy;
    if (!$cast(copy, value.clone())) `uvm_fatal("IP_ITEM", "actual clone has wrong type")
    actual_queue.push_back(copy);
    compare_pending();
  endfunction

  function void compare_pending();
    ITEM expected;
    ITEM actual;
    while (expected_queue.size() != 0 && actual_queue.size() != 0) begin
      expected = expected_queue.pop_front();
      actual   = actual_queue.pop_front();
      if (!actual.compare(expected))
        `uvm_fatal("IP_SCOREBOARD", $sformatf(
                   "Expected %s, got %s", expected.sprint(), actual.sprint()))
      checked++;
    end
  endfunction

  function void cancel_pending();
    if (actual_queue.size() != 0)
      `uvm_fatal("IP_SCOREBOARD", "unexpected actual transactions at reset")
    expected_queue.delete();
  endfunction

  task wait_checked(int unsigned count);
    wait (checked >= count);
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_queue.size() != 0 || actual_queue.size() != 0)
      `uvm_error("IP_SCOREBOARD", $sformatf(
                 "Unmatched transactions: expected=%0d actual=%0d",
                 expected_queue.size(),
                 actual_queue.size()
                 ))
  endfunction
endclass
