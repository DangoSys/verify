`ifndef BB_IN_BW
`error "BB_IN_BW must be provided from chip.pb via +define+BB_IN_BW=<n>"
`endif
`ifndef BB_OUT_BW
`error "BB_OUT_BW must be provided from chip.pb via +define+BB_OUT_BW=<n>"
`endif

localparam int BB_BLINK_BID_W = 5;
localparam int BB_BLINK_FUNCT7_W = 7;
localparam int BB_BLINK_ITER_W = 34;
localparam int BB_BLINK_BANK_ID_W = 5;
localparam int BB_BLINK_GROUP_ID_W = 5;
localparam int BB_BLINK_ROB_ID_W = 4;
localparam int BB_BLINK_SUB_ROB_ID_W = 8;
localparam int BB_BLINK_BANK_ADDR_W = 10;
localparam int BB_BLINK_BANK_DATA_W = 128;
localparam int BB_BLINK_BANK_MASK_W = 16;
