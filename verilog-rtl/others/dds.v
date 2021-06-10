module dds_wave (
    input clk,
    input rst_n,
    input [15:0] din_add,
    input din_vld,
    input cfg_mode,
    input dout_rdy,
    output reg dout_vld,
    output reg [7:0] dout
);

parameter C_W = 16;

reg [7:0] sin_data;
reg [C_W-1:0] addr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr <= 0;
    end
    else if (din_vld) begin
        addr <= addr + din_add;
    end
end

always @(*) begin
    case (addr[C_W-1 -:7])
        0: sin_data = 8'h7F;
        1: sin_data = 8'h85;
        2: sin_data = 8'h8C;
        3: sin_data = 8'h92;
        4: sin_data = 8'h98;
        5: sin_data = 8'h9E;
        6: sin_data = 8'hA4;
        7: sin_data = 8'hAA;
        8: sin_data = 8'hB0;
        9: sin_data = 8'hB6;
        10: sin_data = 8'hBC;
        11: sin_data = 8'hC1;
        12: sin_data = 8'hC6;
        13: sin_data = 8'hCB;
        14: sin_data = 8'hD0;
        15: sin_data = 8'hD5;
        16: sin_data = 8'hDA;
        17: sin_data = 8'hDE;
        18: sin_data = 8'hE2;
        19: sin_data = 8'hE6;
        20: sin_data = 8'hEA;
        21: sin_data = 8'hED;
        22: sin_data = 8'hF0;
        23: sin_data = 8'hF3;
        24: sin_data = 8'hF5;
        25: sin_data = 8'hF7;
        26: sin_data = 8'hF9;
        27: sin_data = 8'hFB;
        28: sin_data = 8'hFC;
        29: sin_data = 8'hFD;
        30: sin_data = 8'hFE;
        31: sin_data = 8'hFE;
        32: sin_data = 8'hFE;
        33: sin_data = 8'hFE;
        34: sin_data = 8'hFE;
        35: sin_data = 8'hFD;
        36: sin_data = 8'hFC;
        37: sin_data = 8'hFA;
        38: sin_data = 8'hF8;
        39: sin_data = 8'hF6;
        40: sin_data = 8'hF4;
        41: sin_data = 8'hF1;
        42: sin_data = 8'hEF;
        43: sin_data = 8'hEB;
        44: sin_data = 8'hE8;
        45: sin_data = 8'hE4;
        46: sin_data = 8'hE0;
        47: sin_data = 8'hDC;
        48: sin_data = 8'hD8;
        49: sin_data = 8'hD3;
        50: sin_data = 8'hCE;
        51: sin_data = 8'hC9;
        52: sin_data = 8'hC4;
        53: sin_data = 8'hBE;
        54: sin_data = 8'hB9;
        55: sin_data = 8'hB3;
        56: sin_data = 8'hAD;
        57: sin_data = 8'hA7;
        58: sin_data = 8'hA1;
        59: sin_data = 8'h9B;
        60: sin_data = 8'h95;
        61: sin_data = 8'h8F;
        62: sin_data = 8'h89;
        63: sin_data = 8'h82;
        64: sin_data = 8'h7D;
        65: sin_data = 8'h77;
        66: sin_data = 8'h70;
        67: sin_data = 8'h6A;
        68: sin_data = 8'h64;
        69: sin_data = 8'h5E;
        70: sin_data = 8'h58;
        71: sin_data = 8'h52;
        72: sin_data = 8'h4C;
        73: sin_data = 8'h46;
        74: sin_data = 8'h41;
        75: sin_data = 8'h3C;
        76: sin_data = 8'h36;
        77: sin_data = 8'h31;
        78: sin_data = 8'h2C;
        79: sin_data = 8'h28;
        80: sin_data = 8'h23;
        81: sin_data = 8'h1F;
        82: sin_data = 8'h1B;
        83: sin_data = 8'h17;
        84: sin_data = 8'h14;
        85: sin_data = 8'h11;
        86: sin_data = 8'hE;
        87: sin_data = 8'hB;
        88: sin_data = 8'h9;
        89: sin_data = 8'h7;
        90: sin_data = 8'h5;
        91: sin_data = 8'h3;
        92: sin_data = 8'h2;
        93: sin_data = 8'h2;
        94: sin_data = 8'h1;
        95: sin_data = 8'h1;
        96: sin_data = 8'h1;
        97: sin_data = 8'h1;
        98: sin_data = 8'h2;
        99: sin_data = 8'h3;
        100: sin_data = 8'h4;
        101: sin_data = 8'h6;
        102: sin_data = 8'h7;
        103: sin_data = 8'hA;
        104: sin_data = 8'hC;
        105: sin_data = 8'hF;
        106: sin_data = 8'h12;
        107: sin_data = 8'h15;
        108: sin_data = 8'h19;
        109: sin_data = 8'h1D;
        110: sin_data = 8'h21;
        111: sin_data = 8'h25;
        112: sin_data = 8'h2A;
        113: sin_data = 8'h2E;
        114: sin_data = 8'h33;
        115: sin_data = 8'h3B;
        116: sin_data = 8'h3E;
        117: sin_data = 8'h43;
        118: sin_data = 8'h49;
        119: sin_data = 8'h4E;
        120: sin_data = 8'h54;
        121: sin_data = 8'h5A;
        122: sin_data = 8'h60;
        123: sin_data = 8'h67;
        124: sin_data = 8'h6D;
        125: sin_data = 8'h73;
        126: sin_data = 8'h79;
        127: sin_data = 8'h7F;
        default: sin_data = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
    end
    else if (cfg_mode == 0) begin
        dout <= sin_data;
    end
    else if (cfg_mode == 1) begin
        dout <= addr[C_W-1 -:8];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_vld <= 0;
    end
    else begin
        dout_vld <= dout_rdy;
    end
end
endmodule

module dds_ctrl (
    input clk,
    input rst_n,
    input cfg_en,
    input [15:0] cfg_time,
    input [15:0] cfg_repeat0,
    input [15:0] cfg_repeat1,
    input [15:0] cfg_repeat2,
    input [15:0] cfg_add0,
    input [15:0] cfg_add1,
    input [15:0] cfg_add2,
    output reg [15:0] dout
);

reg [15:0] cnt0;
wire add_cnt0;
wire end_cnt0;
reg [15:0] cnt1;
reg [15:0] x;
reg [15:0] y;
wire add_cnt1;
wire end_cnt1;
reg [7:0] cnt2;
wire add_cnt2;
wire end_cnt2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt0 <= 0;
    end
    else if (add_cnt0) begin
        if (end_cnt0)
            cnt0 <= 0;
        else
            cnt0 <= cnt0 + 1;
    end
end

assign add_cnt0 = cfg_en;
assign end_cnt0 = add_cnt0 && cnt0 == cfg_time - 1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt1 <= 0;
    end
    else if (add_cnt1) begin
        if (end_cnt1)
            cnt1 <= 0;
        else
            cnt1 <= cnt1 + 1;
    end
end

assign add_cnt1 = end_cnt0;
assign end_cnt1 = add_cnt1 && cnt1 == x - 1;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt2 <= 0;
    end
    else if (add_cnt2) begin
        if (end_cnt2)
            cnt2 <= 0;
        else
            cnt2 <= cnt2 + 1;
    end
end

assign add_cnt2 = end_cnt1;
assign end_cnt2 = add_cnt2 && cnt2 == 3 - 1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
    end
    else if (cfg_en) begin
        dout <= y;
    end
    else begin
        dout <=0;
    end
end

always @(*) begin
    if (cnt2 == 0) begin
        x = cfg_repeat0;
        y = cfg_add0;
    end
    else if (cnt2 == 1) begin
        x = cfg_repeat1;
        y = cfg_add1;
    end
    else begin
        x = cfg_repeat2;
        y = cfg_add2;
    end
end

endmodule

module dds_top (
    input clk,
    input rst_n
);

wire [15:0] ctrl_dout;
wire [7:0] wave_dout;
wire wave_dout_vld;
wire if_din_rdy;

dds_ctrl u_dds_ctrl(
    .clk         (clk         ),
    .rst_n       (rst_n       ),
    .cfg_en      (1      ),
    .cfg_time    (50_000    ),
    .cfg_repeat0 (3 ),
    .cfg_repeat1 (3 ),
    .cfg_repeat2 (3 ),
    .cfg_add0    (128    ),
    .cfg_add1    (128    ),
    .cfg_add2    (128    ),
    .dout        (ctrl_dout        )
);

dds_wave u_dds_wave(
    .clk      (clk      ),
    .rst_n    (rst_n    ),
    .din_add  (ctrl_dout  ),
    .din_vld  (1  ),
    .cfg_mode (1 ),
    .dout_rdy (if_din_rdy ),
    .dout_vld (wave_dout_vld ),
    .dout     (wave_dout     )
);

    
endmodule