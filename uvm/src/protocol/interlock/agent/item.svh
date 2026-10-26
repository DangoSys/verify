class cycle_item extends uvm_sequence_item;
  `uvm_object_utils(cycle_item)
  bus_signals pins, sampled;
  bit reset;
  function new(string name = "cycle_item");
    super.new(name);
  endfunction
endclass

class permit_item extends uvm_sequence_item;
  `uvm_object_utils_begin(permit_item)
    `uvm_field_int(allow, UVM_ALL_ON)
    `uvm_field_int(probe, UVM_ALL_ON)
  `uvm_object_utils_end
  logic allow;
  bit   probe  = 0;
  function new(string name = "permit_item");
    super.new(name);
  endfunction
endclass
