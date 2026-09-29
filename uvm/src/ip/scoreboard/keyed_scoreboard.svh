class keyed_scoreboard #(
    type ITEM = uvm_sequence_item
) extends uvm_scoreboard;
  `uvm_component_param_utils(keyed_scoreboard#(ITEM))
  uvm_analysis_imp_expected #(ITEM, keyed_scoreboard #(ITEM)) expected_export;
  uvm_analysis_imp_actual #(ITEM, keyed_scoreboard #(ITEM)) actual_export;
  ITEM expected[int];
  ITEM actual[int];
  int unsigned checked = 0;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction
  function void write_expected(ITEM value);
    ITEM copy;
    int  key = value.get_transaction_id();
    if (expected.exists(key)) `uvm_fatal("IP_KEY", "duplicate expected transaction ID")
    if (!$cast(copy, value.clone())) `uvm_fatal("IP_ITEM", "expected clone has wrong type")
    expected[key] = copy;
    compare_pending(key);
  endfunction
  function void write_actual(ITEM value);
    ITEM copy;
    int  key = value.get_transaction_id();
    if (actual.exists(key)) `uvm_fatal("IP_KEY", "duplicate actual transaction ID")
    if (!$cast(copy, value.clone())) `uvm_fatal("IP_ITEM", "actual clone has wrong type")
    actual[key] = copy;
    compare_pending(key);
  endfunction
  function void compare_pending(int key);
    if (expected.exists(key) && actual.exists(key)) begin
      if (!actual[key].compare(expected[key]))
        `uvm_fatal("IP_SCOREBOARD", $sformatf(
                   "key=%0d expected %s got %s", key, expected[key].sprint(), actual[key].sprint()))
      expected.delete(key);
      actual.delete(key);
      checked++;
    end
  endfunction
  task wait_checked(int unsigned count);
    wait (checked >= count);
  endtask
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected.num() != 0 || actual.num() != 0)
      `uvm_error("IP_SCOREBOARD", $sformatf(
                 "Unmatched transactions: expected=%0d actual=%0d", expected.num(), actual.num()))
  endfunction
endclass
