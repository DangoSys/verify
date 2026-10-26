virtual class base_test extends uvm_test;
  string result_path;
  longint unsigned timeout_ns;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    uvm_report_server reports = uvm_report_server::get_server();
    reports.set_max_quit_count(1, 0);
    super.build_phase(phase);
    if (!$value$plusargs("RESULT=%s", result_path))
      `uvm_fatal("RESULT_PATH", "Missing +RESULT")
    if (!$value$plusargs("TIMEOUT_NS=%d", timeout_ns) || timeout_ns == 0)
      `uvm_fatal("TIMEOUT", "A positive +TIMEOUT_NS is required")
    uvm_root::get().set_timeout(timeout_ns * 1ns, 0);
  endfunction

  pure virtual task execute();

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    execute();
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server reports = uvm_report_server::get_server();
    int output_file;
    string status;
    super.report_phase(phase);
    if (evidence::comparisons + evidence::checks == 0)
      `uvm_fatal("NO_CHECKS", "Test performed no functional or protocol checks")
    if (evidence::pending != 0)
      `uvm_fatal("PENDING", $sformatf("Unmatched transactions: %0d", evidence::pending))
    status = reports.get_severity_count(UVM_ERROR) == 0 &&
             reports.get_severity_count(UVM_FATAL) == 0 ? "pass" : "fail";
    output_file = $fopen(result_path, "w");
    if (output_file == 0) `uvm_fatal("RESULT_PATH", "Cannot open result file")
    $fdisplay(output_file,
      "{\"status\":\"%s\",\"comparisons\":%0d,\"checks\":%0d,\"expected\":%0d,\"received\":%0d,\"cancelled\":%0d,\"pending\":%0d}",
      status, evidence::comparisons, evidence::checks, evidence::expected,
      evidence::received, evidence::cancelled, evidence::pending);
    $fclose(output_file);
    `uvm_info("RESULT", $sformatf("status=%s comparisons=%0d checks=%0d pending=%0d",
              status, evidence::comparisons, evidence::checks, evidence::pending), UVM_LOW)
  endfunction
endclass
