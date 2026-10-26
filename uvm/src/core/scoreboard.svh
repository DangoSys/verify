`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class result_board #(type ITEM, bit TAGGED) extends uvm_scoreboard;
  `uvm_component_param_utils(result_board#(ITEM, TAGGED))
  uvm_analysis_imp_expected #(ITEM, result_board#(ITEM, TAGGED)) expected_export;
  uvm_analysis_imp_actual #(ITEM, result_board#(ITEM, TAGGED)) actual_export;
  ITEM expected[longint];
  ITEM actual[longint];
  longint next_expected = 0;
  longint next_actual = 0;
  longint unsigned checked = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export = new("actual_export", this);
  endfunction

  function void write_expected(ITEM value);
    ITEM saved;
    longint key = TAGGED ? value.get_transaction_id() : next_expected++;
    if (expected.exists(key)) `uvm_fatal("DUPLICATE_EXPECTED", $sformatf("key=%0d", key))
    if (!$cast(saved, value.clone())) `uvm_fatal("ITEM_TYPE", "Cannot clone expected transaction")
    expected[key] = saved;
    evidence::expected++;
    evidence::pending++;
    match_pending(key);
  endfunction

  function void write_actual(ITEM value);
    ITEM saved;
    longint key = TAGGED ? value.get_transaction_id() : next_actual++;
    if (actual.exists(key)) `uvm_fatal("DUPLICATE_ACTUAL", $sformatf("key=%0d", key))
    if (!$cast(saved, value.clone())) `uvm_fatal("ITEM_TYPE", "Cannot clone actual transaction")
    actual[key] = saved;
    evidence::received++;
    evidence::pending++;
    match_pending(key);
  endfunction

  function void match_pending(longint key);
    if (!expected.exists(key) || !actual.exists(key)) return;
    if (!actual[key].compare(expected[key]))
      `uvm_fatal("MISMATCH", $sformatf("key=%0d expected=%s actual=%s",
                                     key, expected[key].sprint(), actual[key].sprint()))
    expected.delete(key);
    actual.delete(key);
    checked++;
    evidence::comparisons++;
    evidence::pending -= 2;
  endfunction

  function int unsigned pending();
    return expected.num() + actual.num();
  endfunction

  function void cancel_pending();
    if (actual.num() != 0) `uvm_fatal("RESET_RESULT", "Reset cannot discard observed results")
    evidence::cancelled += expected.num();
    evidence::pending -= expected.num();
    expected.delete();
    if (!TAGGED) next_actual = next_expected;
  endfunction

  task wait_checked(longint unsigned count);
    wait (checked >= count);
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (pending() != 0)
      `uvm_fatal("UNMATCHED", $sformatf("expected=%0d actual=%0d", expected.num(), actual.num()))
  endfunction
endclass
