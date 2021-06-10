module sdram_read (
    input sclk,
    input s_rst_n,
    input rd_en,
    output rd_req,
    output reg flag_rd_end,
    input ref_req,
    input rd_trig,
    output reg [3:0] rd_cmd,
    output reg [11:0] rd_addr,
    output [1:0] bank_addr
    //output reg [15:0] rd_data
);

localparam S_IDLE = 5'b00001;
localparam S_REQ = 5'b00010;
localparam S_ACT = 5'b00100;
localparam S_WR = 5'b01000;
localparam S_PRE = 5'b10000;

localparam CMD_NOP = 4'b0111;
localparam CMD_PRE = 4'b0010;
localparam CMD_AREF = 4'b0001;
localparam CMD_ACT = 4'b0011;
localparam CMD_RD = 4'b0101;

reg flag_wr;
reg [4:0] state;
reg flag_act_end;
reg flag_pre_end;
reg sd_row_end;
reg [1:0] burst_cnt, burst_cnt_t;
reg rd_data_end;

reg [3:0] act_cnt;
reg [3:0] break_cnt;
reg [6:0] col_cnt;
reg [11:0] row_addr;
wire [8:0] col_addr;

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        flag_wr <= 'b0;
    else if (rd_trig && !flag_wr)
        flag_wr <= 'b1;
    else if (rd_data_end)
        flag_wr <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        state <= S_IDLE;
    else case (state)
        S_IDLE:
            if (rd_trig)
                state <= S_REQ;
            else
                state <= S_IDLE;
        S_REQ:
            if (rd_en)
                state <= S_ACT;
            else
                state <= S_REQ;
        S_ACT:
            if (flag_act_end)
                state <= S_WR;
            else
                state <= S_ACT;
        S_WR:
            if (rd_data_end)
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
            else if (rd_data_end)
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

always@(posedge sclk or negedge s_rst_n)begin
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
        flag_rd_end <= 'b0;
    else if ((state == S_PRE && ref_req) // Refesh
            || (state == S_PRE && rd_data_end))
        flag_rd_end <= 'b1;
    else
        flag_rd_end <= 'b0;
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
        rd_data_end <= 'b0;
    else if (row_addr == 'd2 && col_addr == 'd511)
        rd_data_end <= 'b1;
    else
        rd_data_end <= 'b0;
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
        rd_cmd <= CMD_NOP;
    else case (state)
        S_ACT:
            if (act_cnt == 'b0)
                rd_cmd <= CMD_ACT;
            else
                rd_cmd <= CMD_NOP;
        S_WR:
            if (burst_cnt == 'b0)
                rd_cmd <= CMD_RD;
            else
                rd_cmd <= CMD_NOP;
        S_PRE:
            if (break_cnt == 'b0)
                rd_cmd <= CMD_PRE;
            else
                rd_cmd <= CMD_NOP;
        default:
            rd_cmd <= CMD_NOP;
    endcase
end

always @(*) begin
    case (state)
        S_ACT:
            if (act_cnt == 'b0)
                rd_addr = row_addr;
        S_WR:
            rd_addr = {3'b000, col_addr}; // A10 = 0, no auto precharge
        S_PRE:
            if (break_cnt == 'b0)
                rd_addr = 12'b0100_0000_0000;
        default:
            rd_addr = 'b0;
    endcase
end

assign bank_addr = 'b0;
assign col_addr = {col_cnt, burst_cnt_t};
assign rd_req = state == S_REQ;

// always @(*) begin
//     case (burst_cnt_t)
//         0: rd_data <= 'd3;
//         1: rd_data <= 'd5;
//         2: rd_data <= 'd7;
//         3: rd_data <= 'd9;
//     endcase
// end

endmodule