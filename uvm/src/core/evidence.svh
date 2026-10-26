class evidence;
  static longint unsigned comparisons;
  static longint unsigned checks;
  static longint unsigned expected;
  static longint unsigned received;
  static longint unsigned cancelled;
  static longint unsigned pending;

  static function void check(logic condition, string message);
    if (condition !== 1'b1) `uvm_fatal("CHECK", message)
    checks++;
  endfunction
endclass
