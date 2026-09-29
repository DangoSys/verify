class axis_item #(
    int DATA_BITS = 32
) extends uvm_sequence_item;
  rand logic [  DATA_BITS-1:0] data;
  rand logic [DATA_BITS/8-1:0] keep;
  rand logic                   last;

  `uvm_object_param_utils_begin(axis_item#(DATA_BITS))
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(keep, UVM_ALL_ON)
    `uvm_field_int(last, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "item");
    super.new(name);
  endfunction
endclass
