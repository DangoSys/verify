`ifndef BB_IN_BW
`error "BB_IN_BW must be provided from chip.pb via +define+BB_IN_BW=<n>"
`endif
`ifndef BB_OUT_BW
`error "BB_OUT_BW must be provided from chip.pb via +define+BB_OUT_BW=<n>"
`endif
`ifndef BB_BANK_ID_W
`error "BB_BANK_ID_W must be provided from chip.pb via +define+BB_BANK_ID_W=<n>"
`endif
`ifndef BB_GROUP_COUNT_W
`error "BB_GROUP_COUNT_W must be provided from chip.pb via +define+BB_GROUP_COUNT_W=<n>"
`endif
`ifndef BB_GROUP_ID_W
`error "BB_GROUP_ID_W must be provided from chip.pb via +define+BB_GROUP_ID_W=<n>"
`endif
`ifndef BB_ROB_ID_W
`error "BB_ROB_ID_W must be provided from chip.pb via +define+BB_ROB_ID_W=<n>"
`endif

localparam int BB_BLINK_FUNCT_W = 7;
localparam int BB_BLINK_RS2_W = 64;
localparam int BB_BLINK_ITER_W = 34;
localparam int BB_BLINK_BANK_ID_W = `BB_BANK_ID_W;
localparam int BB_BLINK_GROUP_COUNT_W = `BB_GROUP_COUNT_W;
localparam int BB_BLINK_GROUP_ID_W = `BB_GROUP_ID_W;
localparam int BB_BLINK_ROB_ID_W = `BB_ROB_ID_W;
localparam int BB_BLINK_BANK_ADDR_W = 16;
localparam int BB_BLINK_BANK_DATA_W = 128;
localparam int BB_BLINK_BANK_MASK_W = 16;
