virtual class reference_model #(
    type REQUEST  = uvm_sequence_item,
    type RESPONSE = REQUEST
) extends uvm_subscriber #(REQUEST);
  uvm_analysis_port #(RESPONSE) expected_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
  endfunction

  pure virtual function void write(REQUEST t);
endclass
