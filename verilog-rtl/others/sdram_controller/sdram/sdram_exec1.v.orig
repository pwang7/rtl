module sdram_init_aref #(
    parameter DATA_W = 16,
    parameter IADD_W = 22,
    parameter OADD_W = 12
) (
    input clk,
    input rst_n,
    output reg cke,
    output cs,
    output ras,
    output cas,
    output we,
    output reg [1:0] dqm,
    output reg [OADD_W-1:0]  addr,
    output reg [1:0] bank,
    // output reg [DATA_W-1:0] data_w,
    // input [DATA_W-1:0] data_r,
    inout [DATA_W-1:0] dq,
    output reg data_w_en
);

localparam INIT_NOP = 0;
localparam INIT_CHARGE = 1;
localparam INIT_REF0 = 2;
localparam INIT_REF1 = 3;
localparam INIT_MODE = 4;
localparam ST_IDLE = 5;
localparam ST_REF = 6;
localparam TIME_120US = 12000;
localparam TIME_TRP = 3;
localparam TIME_TRC = 7;
localparam TIME_TMRD = 2;
localparam TIME_1562 = 1562; // 100Mhz
localparam NOP_CD = 4'b0111;
localparam CHARGE_CD = 4'b0010;
localparam REF_CD = 4'b0001;
localparam MODE_CD = 4'b0000;
localparam MODE_VALUE = 12'b00_0_00_011_0_111;


reg [3:0] command;
reg [3:0] state_c, state_n;
wire init_charge_start;
wire init_ref0_start;
wire init_ref1_start;
wire init_mode_start;
wire st_idle_start;
wire st_ref_start;
reg [13:0] cnt0;
reg [10:0] cnt1;

assign {cs, ras, cas, we} = command;
assign wr_ack = wr_active_start;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dq <= 16'hZZZZ;
    else if (wr_write_start || (state_c == WR_WRITE && cnt0 != 0))
        dq <= wdata;
    else
        dq <= 16'hZZZZ;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state_c <= INIT_NOP;
    else
        state_c <= state_n;
end

always @(*) begin
    case (state_c)
        INIT_NOP: begin
            if (init_charge_start)
                state_n = INIT_CHARGE;
            else
                state_n = state_c;
        end
        INIT_CHARGE: begin
            if (init_ref0_start)
                state_n = INIT_REF0;
            else
                state_n = state_c;
        end
        INIT_REF0: begin
            if (init_ref1_start)
                state_n = INIT_REF1;
            else
                state_n = state_c;
        end
        INIT_REF1: begin
            if (init_mode_start)
                state_n = INIT_MODE;
            else
                state_n = state_c;
        end
        INIT_MODE: begin
            if (st_idle_start)
                state_n = ST_IDLE;
            else
                state_n = state_c;
        end
        ST_IDLE: begin
            if (st_ref_start)
                state_n = ST_IDLE;
            else if (wr_active_start)
                state_n = WR_ACTIVE;
            else
                state_n = state_c;
        end
        ST_REF: begin
            if (st_idle_start)
                state_n = ST_IDLE;
            else
                state_n = state_c;
        end
        WR_ACTIVE: begin
            if (wr_write_start)
                state_n = WR_WRITE;
            else
                state_n = state_c; 
        end
        WR_WRITE: begin
            if (wr_charge_start)
                state_n = WR_CHARGE;
            else
                state_n = state_c;
        end
        WR_CHARGE: begin
            if (st_idle_start)
                state_n = ST_IDLE;
            else
                state_n = state_c;
        end
        default: begin
            state_n = INIT_NOP;
        end
    endcase
end

assign init_charge_start = state_c  == INIT_NOP    && cnt0 == 0;
assign init_ref0_start   = state_c  == INIT_CHARGE && cnt0 == 0;
assign init_ref1_start   = state_c  == INIT_REF0   && cnt0 == 0;
assign init_mode_start   = state_c  == INIT_REF1   && cnt0 == 0;
assign st_idle_start     = (state_c == INIT_MODE   && cnt0 == 0)
                         || (state_c == ST_REF     && cnt0 == 0)
                         || (state_c == WR_CHARGE  && cnt0 = 0);
assign st_ref_start      = state_c  == ST_IDLE     && cnt1 == 0;
assign wr_active_start   = state_c == ST_IDLE      && !st_ref_start && cnt0 == 0;
assign wr_write_start    = start_c == WR_ACTIVE    && cnt0 == 0;
assign wr_charge_start   = state_c == WR_WRITE     && cnt0 == 0;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt0 <= TIME_120US - 1;
    else if (init_charge_start)
        cnt0 <= TIME_TRP - 1;
    else if (init_ref0_start || init_ref1_start)
        cnt0 <= TIME_TRP - 1;
    else if (init_mode_start)
        cnt0 <= TIME_TMRD - 1;
    else if (st_ref_start)
        cnt0 <= TIME_TRC - 1;
    else if (wr_active_start)
        cnt0 <= TIME_TRCD - 1;
    else if (wr_write_start)
        cnt0 <= 256 - 1;
    else if (wr_charge_start)
        cnt0 <= TIME_TRP - 1;
    else if (cnt0 != 0)
        cnt0 <= cnt0 - 1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt1 <= TIME_1562 - 1;
    else if (state_c == ST_IDLE || state_c == ST_REF
            || state_c == WR_ACTIVE || state_c == WR_WRITE || state_c == WR_CHARGE) begin
        if (cnt1 == 0) begin
            if (st_ref_start)
                cnt1 <= TIME_1562 - 1;
            else
                cnt1 <= 0;
        end
        else
            cnt1 <= cnt1 - 1;
    end
    else
        cnt1 <= TIME_1562 - 1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cke <= 'b1;
    else
        cke <= 'b1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        command <= NOP_CD;
    else if (init_charge_start || wr_charge_start)
        command <= CHARGE_CD;
    else if (init_ref0_start || init_ref1_start)
        command <= REF_CD;
    else if (init_mode_start)
        command <= MODE_CD;
    else if (wr_active_start)
        command <= ACTIVE_CD;
    else if (wr_write_start)
        command <= WRITE_CD;
    else
        command <= NOP_CD;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dqm <= 2'b11;
    else if (state_c == INIT_NOP || state_c == INIT_CHARGE || state_c == INIT_REF0 || state_c == INIT_REF1 || state_c == INIT_MODE)
        dqm <= 2'b11;
    else
        dqm <= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        addr <= 'b0;
    else if (init_mode_start)
        addr <= MODE_VALUE;
    else if (init_charge_start || wr_charge_start)
        addr <= (12'b1 << 10); // A10 = 1
    else if (wr_active_start)
        addr <= waddr[19:8];
    else if (wr_write_start)
        addr <= {4'b0, waddr[7:0]};
    else
        addr <= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        waddr_ff0 <= 'b0;
    else if (wr_active_start)
        waddr_ff0 <= waddr;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bank <= 'b0;
    else if (wr_active_start)
        bank <= waddr[21:20];
    else if (wr_write_start)
        bank <= waddr_ff0[21:20];
    else
        bank <= 2'b00;
end

endmodule