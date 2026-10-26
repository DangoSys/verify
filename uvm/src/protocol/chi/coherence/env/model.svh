class system_model extends uvm_subscriber #(snapshot);
  `uvm_component_utils(system_model)
  chandle reference;
  req_t requests[int];
  logic [511:0] assembled[int];
  bit [`COH_BEATS-1:0] received[int];
  int data_dbid[int];
  logic [2:0] data_permission[int];
  logic [1:0] data_error[int];
  int expected_order[$];
  bit expected_error[int];
  private_line_t cpus[`COH_AGENTS][longint unsigned];
  bit [511:0] memory[longint unsigned];
  bit dirty_addresses[longint unsigned];
  int clean_shared_requests[longint unsigned];
  rsp_t rsp_queue[$], ack_queue[$];
  dat_t dat_queue[$];
  mem_t mem_queue[$];
  bit [`COH_MSHRS-1:0] hold_ack = 0;
  bit vary_idle_payload = 0;
  bit idle_payload_one = 0;
  bit hold_memory = 0, reverse_memory = 0, saw_reorder = 0;
  int memory_writes = 0, memory_reads = 0, peak = 0;
  int snoops = 0;
  bit hold_rsp = 0, hold_snp = 0, hold_mem_req = 0;
  bit hold_copyback = 0;
  bit fault_enabled = 0, write_fault_enabled = 0;
  longint unsigned fault_addr;

  uvm_analysis_port #(completion) expected_ap, actual_ap;
  uvm_analysis_port #(bit) reset_ap;
  covergroup operations with function sample (int opcode, int node, bit error);
    option.per_instance = 1;
    operation: coverpoint opcode {
      bins supported[] = {`COH_READ_SHARED, `COH_READ_NSD, `COH_READ_UNIQUE,
      `COH_MAKE_UNIQUE, `COH_EVICT, `COH_WRITEBACK, `COH_CLEAN_SHARED, `COH_CLEAN_INVALID, `COH_MAKE_INVALID};
    }
    requester: coverpoint node {bins agents[] = {[1 : `COH_AGENTS]};}
    response_error: coverpoint error;
  endgroup
  covergroup occupancy with function sample (int count);
    option.per_instance = 1;
    outstanding: coverpoint count {
      bins empty = {0}; bins partial = {[1 : `COH_MSHRS - 1]}; bins full = {`COH_MSHRS};
    }
  endgroup
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
    actual_ap = new("actual_ap", this);
    reset_ap = new("reset_ap", this);
    operations = new();
    occupancy = new();
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    reference = coherence_ref_create();
  endfunction
  function void cpu_write(int node, longint unsigned addr, bit [511:0] value);
    if (!cpus[node-1].exists(addr) || !cpus[node-1][addr].valid || !cpus[node-1][addr].unique_owner)
      `uvm_fatal("CPU", "write without unique permission")
    cpus[node-1][addr].data  = value;
    cpus[node-1][addr].dirty = 1;
    coherence_ref_write(reference, addr, value);
    dirty_addresses[addr] = 1;
  endfunction
  function void finish(completion item);
    int key = (item.node << 12) | item.txn;
    int position = -1;
    item.set_transaction_id(key);
    foreach (expected_order[i]) if (expected_order[i] == key) position = i;
    if (position < 0) `uvm_fatal("ORDER", "unexpected completion")
    if (position != 0) saw_reorder = 1;
    expected_order.delete(position);
    actual_ap.write(item);
    if (requests[key][`CF(REQ, OPCODE)] == `COH_CLEAN_SHARED) begin
      longint unsigned address = requests[key][`CF(REQ, ADDR)];
      clean_shared_requests[address]--;
      if (clean_shared_requests[address] == 0) clean_shared_requests.delete(address);
    end
    requests.delete(key);
  endfunction

  function void write(snapshot s);
    if (s.reset) begin
      if (dirty_addresses.num() != 0) `uvm_fatal("RESET", "Reset before dirty data reached memory")
      reset_ap.write(1);
      rsp_queue.delete();
      ack_queue.delete();
      dat_queue.delete();
      mem_queue.delete();
      requests.delete();
      expected_order.delete();
      assembled.delete();
      received.delete();
      data_dbid.delete();
      data_permission.delete();
      data_error.delete();
      clean_shared_requests.delete();
      foreach (cpus[i]) cpus[i].delete();
    end else begin
      occupancy.sample(s.outstanding);
      if (s.outstanding > peak) peak = s.outstanding;
      if (s.req_valid && s.req_ready) begin
        completion item = completion::type_id::create("expected");
        int node = s.req_bits[`CF(REQ, SRCID)];
        int txn = s.req_bits[`CF(REQ, TXNID)];
        int key = (node << 12) | txn;
        int opcode = s.req_bits[`CF(REQ, OPCODE)];
        longint unsigned addr = s.req_bits[`CF(REQ, ADDR)];
        bit [511:0] value;
        requests[key] = s.req_bits;
        if (opcode == `COH_CLEAN_SHARED) begin
          if (!clean_shared_requests.exists(addr)) clean_shared_requests[addr] = 0;
          clean_shared_requests[addr]++;
        end
        expected_order.push_back(key);
        item.node = node;
        item.txn = txn;
        item.is_data=opcode==`COH_READ_SHARED || opcode==`COH_READ_NSD || opcode==`COH_READ_UNIQUE;
        item.opcode=item.is_data ? `COH_COMP_DATA : (opcode==`COH_WRITEBACK ? `COH_COMP_DBID : `COH_COMP);
        item.error = expected_error.exists(key) && expected_error[key] ? 3 : 0;
        item.permission=item.error==0 ? (opcode==`COH_MAKE_UNIQUE ? 2 : (item.is_data ? (opcode==`COH_READ_UNIQUE ? 2 : 1) : 0)) : 0;
        if (item.is_data && !item.error) begin
          coherence_ref_read(reference, addr, value);
          item.data = value;
        end
        operations.sample(opcode, node, item.error != 0);
        item.set_transaction_id(key);
        expected_ap.write(item);
        if (opcode == `COH_EVICT && cpus[node-1].exists(addr)) begin
          if (cpus[node-1][addr].valid && cpus[node-1][addr].dirty)
            `uvm_fatal("CPU", "dirty line sent as Evict")
          cpus[node-1][addr].valid = 0;
        end
      end
      if (s.snp_valid && s.snp_ready) begin
        int node = s.snp_bits[`CF(SNP, TARGET)];
        int txn = s.snp_bits[`CF(SNP, TXNID)];
        int opcode = s.snp_bits[`CF(SNP, OPCODE)];
        longint unsigned addr = longint'(s.snp_bits[`CF(SNP, ADDR)]) << 3;
        private_line_t line;
        bit invalidate = opcode == `COH_SNP_UNIQUE || opcode == `COH_SNP_INVALID || opcode == `COH_SNP_MAKE_INVALID;
        bit discard = opcode == `COH_SNP_MAKE_INVALID;
        if (node < 1 || node > `COH_AGENTS || s.snp_bits[`CF(SNP, SRCID)] != `COH_HOME)
          `uvm_fatal("SNOOP", "invalid destination/source")
        snoops++;
        line = cpus[node-1].exists(addr) ? cpus[node-1][addr] : '0;
        if ((opcode == `COH_SNP_INVALID || opcode == `COH_SNP_CLEAN_SHARED || discard) && s.snp_bits[
            `CF(SNP, RETTOSRC)
            ] !== 0)
          `uvm_fatal("SNOOP", "Maintenance snoop must clear RetToSrc")
        if (line.valid && !discard && (line.dirty || (!line.unique_owner && s.snp_bits[
            `CF(SNP, RETTOSRC)
            ]))) begin
          for (int b = 0; b < `COH_BEATS; b++) begin
            dat_t packet = '0;
            packet[`CF(DAT, TGTID)] = `COH_HOME;
            packet[`CF(DAT, SRCID)] = node;
            packet[`CF(DAT, TXNID)] = txn;
            packet[`CF(DAT, OPCODE)] = `COH_SNP_DATA;
            packet[`CF(DAT, RESP)] = (invalidate ? 0 : 1) | (line.dirty ? 4 : 0);
            packet[`CF(DAT, DATAID)] = b * (`COH_DATA_BITS / 128);
            packet[`CF(DAT, BE)] = '1;
            packet[`CF(DAT, DATA)] = line.data[b*`COH_DATA_BITS+:`COH_DATA_BITS];
            dat_queue.push_back(packet);
          end
        end else begin
          rsp_t packet = '0;
          packet[`CF(RSP, TGTID)]  = `COH_HOME;
          packet[`CF(RSP, SRCID)]  = node;
          packet[`CF(RSP, TXNID)]  = txn;
          packet[`CF(RSP, OPCODE)] = `COH_SNP_RESP;
          packet[`CF(RSP, RESP)]   = line.valid && !invalidate ? 1 : 0;
          rsp_queue.push_back(packet);
        end
        if (line.valid) begin
          line.valid = !invalidate;
          line.unique_owner = 0;
          line.dirty = 0;
          cpus[node-1][addr] = line;
        end
      end
      if (s.tx_rsp_valid && s.tx_rsp_ready) begin
        completion item = completion::type_id::create("rsp");
        int node = s.tx_rsp_bits[`CF(TXRSP, TGTID)];
        int txn = s.tx_rsp_bits[`CF(TXRSP, TXNID)];
        int key = (node << 12) | txn;
        int dbid = s.tx_rsp_bits[`CF(TXRSP, DBID)];
        if (!requests.exists(
                key
            ) || s.tx_rsp_bits[
            `CF(TXRSP, SRCID)
            ] != `COH_HOME || dbid >= `COH_MSHRS)
          `uvm_fatal("RSP", "unexpected response routing")
        item.node = node;
        item.txn = txn;
        item.opcode = s.tx_rsp_bits[`CF(TXRSP, OPCODE)];
        item.error = s.tx_rsp_bits[`CF(TXRSP, RESPERR)];
        item.permission = s.tx_rsp_bits[`CF(TXRSP, RESP)];
        if (item.opcode == `COH_COMP && requests[key][`CF(REQ, OPCODE)] == `COH_MAKE_UNIQUE) begin
          rsp_t ack = '0;
          longint unsigned addr = requests[key][`CF(REQ, ADDR)];
          if (!item.error) begin
            if (!cpus[node-1].exists(addr) || !cpus[node-1][addr].valid)
              `uvm_fatal("UPGRADE", "MakeUnique revoked the requesting agent's retained line")
            cpus[node-1][addr].unique_owner = 1;
          end
          ack[`CF(RSP, TGTID)]  = `COH_HOME;
          ack[`CF(RSP, SRCID)]  = node;
          ack[`CF(RSP, TXNID)]  = dbid;
          ack[`CF(RSP, OPCODE)] = `COH_COMP_ACK;
          ack_queue.push_back(ack);
        end
        if (item.opcode == `COH_COMP_DBID) begin
          longint unsigned addr = requests[key][`CF(REQ, ADDR)];
          private_line_t   line = cpus[node-1].exists(addr) ? cpus[node-1][addr] : '0;
          for (int b = 0; b < `COH_BEATS; b++) begin
            dat_t packet = '0;
            packet[`CF(DAT, TGTID)] = `COH_HOME;
            packet[`CF(DAT, SRCID)] = node;
            packet[`CF(DAT, TXNID)] = dbid;
            packet[`CF(DAT, OPCODE)] = `COH_COPYBACK_DATA;
            packet[
            `CF(DAT, RESP)
            ] = line.valid ? (line.unique_owner ? 2 : 1) | (line.dirty ? 4 : 0) : 0;
            packet[`CF(DAT, DATAID)] = b * (`COH_DATA_BITS / 128);
            packet[`CF(DAT, BE)] = line.valid ? '1 : '0;
            packet[`CF(DAT, DATA)] = line.data[b*`COH_DATA_BITS+:`COH_DATA_BITS];
            dat_queue.push_back(packet);
          end
          if (line.valid) begin
            line.valid = 0;
            cpus[node-1][addr] = line;
          end
        end
        finish(item);
      end
      if (s.tx_dat_valid && s.tx_dat_ready) begin
        int node = s.tx_dat_bits[`CF(TXDAT, TGTID)];
        int txn = s.tx_dat_bits[`CF(TXDAT, TXNID)];
        int key = (node << 12) | txn;
        int b = s.tx_dat_bits[`CF(TXDAT, DATAID)] / (`COH_DATA_BITS / 128);
        int dbid = s.tx_dat_bits[`CF(TXDAT, DBID)];
        if (!requests.exists(
                key
            ) || s.tx_dat_bits[
            `CF(TXDAT, SRCID)
            ] != `COH_HOME || s.tx_dat_bits[
            `CF(TXDAT, HOMENID)
            ] != `COH_HOME || dbid >= `COH_MSHRS || b >= `COH_BEATS)
          `uvm_fatal("DATA", "unexpected response routing")
        if (!received.exists(key)) begin
          received[key] = '0;
          assembled[key] = '0;
          data_dbid[key] = dbid;
          data_permission[key] = s.tx_dat_bits[`CF(TXDAT, RESP)];
          data_error[key] = s.tx_dat_bits[`CF(TXDAT, RESPERR)];
        end
        if (s.tx_dat_bits[
            `CF(TXDAT, OPCODE)
            ] !== `COH_COMP_DATA || s.tx_dat_bits[
            `CF(TXDAT, DATAID)
            ] % (`COH_DATA_BITS / 128) != 0 || s.tx_dat_bits[
            `CF(TXDAT, RESP)
            ] !== data_permission[key] || s.tx_dat_bits[
            `CF(TXDAT, RESPERR)
            ] !== data_error[key] || s.tx_dat_bits[
            `CF(TXDAT, BE)
            ] !== (data_error[key] != 0 ? `COH_TXDAT_BE_WIDTH'(0) : {`COH_TXDAT_BE_WIDTH{1'b1}}))
          `uvm_fatal("DATA", "inconsistent completion data header")
        if (received[key][b] || dbid != data_dbid[key])
          `uvm_fatal("DATA", "duplicate beat or inconsistent DBID")
        assembled[key][b*`COH_DATA_BITS+:`COH_DATA_BITS] = s.tx_dat_bits[`CF(TXDAT, DATA)];
        received[key][b] = 1;
        if (&received[key]) begin
          completion item = completion::type_id::create("data");
          rsp_t ack = '0;
          longint unsigned addr = requests[key][`CF(REQ, ADDR)];
          item.node = node;
          item.txn = txn;
          item.is_data = 1;
          item.opcode = s.tx_dat_bits[`CF(TXDAT, OPCODE)];
          item.error = s.tx_dat_bits[`CF(TXDAT, RESPERR)];
          item.permission = s.tx_dat_bits[`CF(TXDAT, RESP)];
          item.data = assembled[key];
          if (!item.error)
            cpus[node-1][addr] = '{
                valid: 1,
                unique_owner: (item.permission == 2),
                dirty: 0,
                data: item.data
            };
          ack[`CF(RSP, TGTID)]  = `COH_HOME;
          ack[`CF(RSP, SRCID)]  = node;
          ack[`CF(RSP, TXNID)]  = dbid;
          ack[`CF(RSP, OPCODE)] = `COH_COMP_ACK;
          ack_queue.push_back(ack);
          finish(item);
          received.delete(key);
          assembled.delete(key);
          data_dbid.delete(key);
          data_permission.delete(key);
          data_error.delete(key);
        end
      end
      if (s.mem_req_valid && s.mem_req_ready) begin
        mem_t packet = '0;
        longint unsigned addr = s.mem_req_bits[`CF(MEMREQ, ADDR)];
        bit [511:0] value;
        packet[`CF(MEMRESP, ID)] = s.mem_req_bits[`CF(MEMREQ, ID)];
        if (s.mem_req_bits[`CF(MEMREQ, WRITE)]) begin
          coherence_ref_read(reference, addr, value);
          if (s.mem_req_bits[
              `CF(MEMREQ, DATA)
              ] !== value || s.mem_req_bits[
              `CF(MEMREQ, MASK)
              ] !== '1)
            `uvm_fatal("MEMORY", "dirty victim writeback lost data")
          foreach (cpus[i])
          if (cpus[i].exists(
                  addr
              ) && cpus[i][addr].valid && (!clean_shared_requests.exists(
                  addr
              ) || cpus[i][addr].dirty || cpus[i][addr].unique_owner ||
                  cpus[i][addr].data !== value))
            `uvm_fatal("INCLUSION",
                       "DDR clean completed while a private copy was dirty, unique or inconsistent")
          if (write_fault_enabled && addr == fault_addr) begin
            packet[`CF(MEMRESP, ERROR)] = 1;
          end else begin
            memory[addr] = value;
            dirty_addresses.delete(addr);
          end
          memory_writes++;
        end else begin
          if (memory.exists(addr)) value = memory[addr];
          else coherence_ref_initial(addr, value);
          packet[`CF(MEMRESP, DATA)]  = value;
          packet[`CF(MEMRESP, ERROR)] = fault_enabled && addr == fault_addr;
          memory_reads++;
        end
        mem_queue.push_back(packet);
      end
    end
  endfunction
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    evidence::check(requests.num() == 0 && received.num() == 0 && expected_order.size() == 0,
                    "Coherence transactions remain unmatched");
  endfunction
  function void final_phase(uvm_phase phase);
    coherence_ref_destroy(reference);
    super.final_phase(phase);
  endfunction
endclass
