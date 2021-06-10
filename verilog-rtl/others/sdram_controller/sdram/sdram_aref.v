module sdram_aref (
    input sclk,
    input s_rst_n,
    input ref_en,
    input flag_init_end,
    output reg ref_req,
    output flag_ref_end,
    output reg[3:0] aref_cmd,
    output [11:0] sdram_addr
);
localparam DELAY_15US = 750;
localparam CMD_AREF = 4'b0001;
localparam CMD_NOP = 4'b0111;
localparam CMD_PRE = 4'b0010;

reg[3:0] cmd_cnt;
reg[9:0] ref_cnt;
reg flag_ref;
    
always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        ref_cnt <= 'd0;
    else if (ref_cnt >= DELAY_15US)
        ref_cnt <= 'd0;
    else if (flag_init_end)
        ref_cnt <= ref_cnt + 'b1;
end


always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        flag_ref <= 'b0;
    else if (flag_ref_end)
        flag_ref <= 'b0;
    else if (ref_en)
        flag_ref <= 'b1;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        cmd_cnt <= 'b0;
    else if (flag_ref)
        cmd_cnt <= cmd_cnt + 'b1;
    else
        cmd_cnt <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        aref_cmd <= CMD_NOP;
    else if (cmd_cnt == 'd2)
        aref_cmd <= CMD_AREF;
    else
        aref_cmd <= CMD_NOP;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        ref_req <= 'b0;
    else if (ref_en)
        ref_req <= 'b0;
    else if (ref_cnt >= DELAY_15US)
        ref_req <= 'b1;
end

assign flag_ref_end = (cmd_cnt > 'd3) ? 'b1 : 'b0;
assign sdram_addr = 12'b0100_0000_0000;

endmodule