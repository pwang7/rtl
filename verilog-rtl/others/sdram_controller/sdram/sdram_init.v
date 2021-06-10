module sdram_init (
    input sclk,
    input s_rst_n,
    output reg [3:0] cmd_reg,
    output [11:0] sdram_addr,
    output flag_init_end
);
localparam  DELAY_200US = 10000; // 50MHz
localparam NOP = 4'b0111;
localparam PRE = 4'b0010;
localparam AREF = 4'b0001;
localparam MSET = 4'b0000;

reg [13:0] cnt_200us;
wire flag_200us;
reg [3:0] cnt_cmd;

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        cnt_200us <= 'd0;
    else if (!flag_200us)
        cnt_200us <= cnt_200us + 'b1;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        cnt_cmd <= 'd0;
    else if (flag_200us && !flag_init_end) begin
        cnt_cmd <= cnt_cmd + 'b1;
    end
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        cmd_reg <= NOP;
    else if (flag_200us)
        case (cnt_cmd)
            0: cmd_reg <= PRE;
            1: cmd_reg <= AREF;
            5: cmd_reg <= AREF;
            9: cmd_reg <= MSET;
            default: cmd_reg <= NOP;
        endcase
end

assign flag_init_end = (cnt_cmd >= 'd10) ? 'b1 : 'b0;
assign sdram_addr = (cmd_reg == MSET) ? 12'b0000_0011_0010 : 12'b0100_0000_0000;
assign flag_200us = (cnt_200us >= DELAY_200US) ? 'b1 : 'b0;

endmodule