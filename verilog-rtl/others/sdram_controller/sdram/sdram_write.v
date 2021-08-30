module sdram_write (
    input sclk,
    input s_rst_n,
    input wr_en,
    output wr_req,
    output reg flag_wr_end,
    input ref_req,
    input wr_trig,
    output reg [3:0] wr_cmd,
    output reg [11:0] wr_addr,
    output [1:0] bank_addr,
    output reg [15:0] wr_data
);

localparam reg[4:0] S_IDLE = 5'b00001;
localparam reg[4:0] S_REQ = 5'b00010;
localparam reg[4:0] S_ACT = 5'b00100;
localparam reg[4:0] S_WR = 5'b01000;
localparam reg[4:0] S_PRE = 5'b10000;

localparam reg[3:0] CMD_NOP = 4'b0111;
localparam reg[3:0] CMD_PRE = 4'b0010;
localparam reg[3:0] CMD_AREF = 4'b0001;
localparam reg[3:0] CMD_ACT = 4'b0011;
localparam reg[3:0] CMD_WR = 4'b0100;

reg flag_wr;
reg [4:0] state;
reg flag_act_end;
reg flag_pre_end;
reg sd_row_end;
reg [1:0] burst_cnt, burst_cnt_t;
reg wr_data_end;

reg [3:0] act_cnt;
reg [3:0] break_cnt;
reg [6:0] col_cnt;
reg [11:0] row_addr;
wire [8:0] col_addr;

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        flag_wr <= 'b0;
    else if (wr_trig && !flag_wr)
        flag_wr <= 'b1;
    else if (wr_data_end)
        flag_wr <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        state <= S_IDLE;
    else case (state)
        S_IDLE:
            if (wr_trig)
                state <= S_REQ;
            else
                state <= S_IDLE;
        S_REQ:
            if (wr_en)
                state <= S_ACT;
            else
                state <= S_REQ;
        S_ACT:
            if (flag_act_end)
                state <= S_WR;
            else
                state <= S_ACT;
        S_WR:
            if (wr_data_end)
                state <= S_PRE;
            else if (ref_req && burst_cnt_t == 'd2 && flag_wr)
                state <= S_PRE;
            else if (sd_row_end && flag_wr)
                state <= S_PRE;
        S_PRE:
            if (ref_req && flag_wr)
                state <= S_REQ;
            else if (flag_pre_end && flag_wr)
                state <= S_ACT;
            else if (wr_data_end)
                state <= S_IDLE;
        default:
            state <= S_IDLE;
    endcase
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        flag_act_end <= 'b0;
    else if (act_cnt == 'd3)
        flag_act_end <= 'b1;
    else
        flag_act_end <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        act_cnt <= 'b0;
    else if (state == S_ACT)
        act_cnt <= act_cnt + 'b1;
    else
        act_cnt <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        burst_cnt <= 'b0;
    else if (state == S_WR)
        burst_cnt <= burst_cnt + 'b1;
    else
        burst_cnt <= 'b0;
end

always@(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        burst_cnt_t <= 'b0;
    else
        burst_cnt_t <= burst_cnt;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        flag_pre_end <= 'b0;
    else if (break_cnt == 'd3)
        flag_pre_end <= 'b1;
    else
        flag_pre_end <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        flag_wr_end <= 'b0;
    else if ((state == S_PRE && ref_req) // Refesh
            || (state == S_PRE && wr_data_end))
        flag_wr_end <= 'b1;
    else
        flag_wr_end <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        break_cnt <= 'b0;
    else if (state == S_PRE)
        break_cnt <= break_cnt + 'b1;
    else
        break_cnt <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        wr_data_end <= 'b0;
    else if (row_addr == 'd2 && col_addr == 'd511)
        wr_data_end <= 'b1;
    else
        wr_data_end <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        col_cnt <= 'b0;
    else if (burst_cnt_t == 'd3)
        col_cnt <= col_cnt + 'b1;
    else if (col_addr == 'd511)
        col_cnt <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        row_addr <= 'b0;
    else if (sd_row_end)
        row_addr <= row_addr + 'b1;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        sd_row_end <= 'b0;
    else if (col_addr == 'd509)
        sd_row_end <= sd_row_end + 'b1;
    else
        sd_row_end <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        wr_cmd <= CMD_NOP;
    else case (state)
        S_ACT:
            if (act_cnt == 'b0)
                wr_cmd <= CMD_ACT;
            else
                wr_cmd <= CMD_NOP;
        S_WR:
            if (burst_cnt == 'b0)
                wr_cmd <= CMD_WR;
            else
                wr_cmd <= CMD_NOP;
        S_PRE:
            if (break_cnt == 'b0)
                wr_cmd <= CMD_PRE;
            else
                wr_cmd <= CMD_NOP;
        default:
            wr_cmd <= CMD_NOP;
    endcase
end

always @(*) begin
    case (state)
        S_ACT:
            if (act_cnt == 'b0)
                wr_addr = row_addr;
        S_WR:
            wr_addr = {3'b000, col_addr}; // A10 = 0, no auto precharge
        S_PRE:
            if (break_cnt == 'b0)
                wr_addr = 12'b0100_0000_0000;
        default:
            wr_addr = 'b0;
    endcase
end

assign bank_addr = 'b0;
assign col_addr = {col_cnt, burst_cnt_t};
assign wr_req = state[1]; // state == S_REQ;

always @(*) begin
    case (burst_cnt_t)
        0: wr_data = 'd3;
        1: wr_data = 'd5;
        2: wr_data = 'd7;
        3: wr_data = 'd9;
        default: wr_data = 'd0;
    endcase
end

endmodule
