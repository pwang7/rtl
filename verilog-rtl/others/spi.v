// SPI两个信号SCLK和MOSI，100MHz输入时钟，SCLK是1MHz，MOSI依次输出一个字节的8个bit

module SPI (
    input clk, // 50MHz
    input rst_n,
    input start,
    input [2:0] channel,
    // ADC128S022
    output reg SCLK, // 2.5MHz
    output reg DIN,
    output reg CS_N,
    input DOUT,

    output reg done,
    output reg [11:0] data
);

reg en;
reg [2:0] r_channel;
reg [4:0] cnt;
reg cnt_flag;
reg [5:0] SCLK_CNT;
reg [11:0] r_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        r_channel <= 'b0;
    else if (start)
        r_channel <= channel;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        en <= 'b0;
    else if (start)
        en <= 'b1;
    else if (done)
        en <= 'b0;    
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= 'b0;
    else if (en) begin
        if (cnt == 'd10)
            cnt <= 'd0;
        else
            cnt <= cnt + 'b1;
    end
    else
        cnt <= 'd0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_flag <= 'b0;
    else if (cnt == 'd10)
        cnt_flag <= 'b1;
    else
        cnt_flag <= 'b0;
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SCLK_CNT <= 'd0;
    else if (en) begin
        if (SCLK_CNT == 'd33)
            SCLK_CNT <= 'd0;
        else if (cnt_flag)
            SCLK_CNT <= SCLK_CNT + 'b1;
    end
    else
        SCLK_CNT <= 'b0;
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        SCLK <= 'b1;
        CS_N <= 'b1;
        DIN <= 'b1;
    end
    else if (en) begin
        case (SCLK_CNT)
            'd0: begin
                CS_N <= 'b0;
            end
            'd1: begin
                SCLK <= 'b0;
                DIN <= 'b0;
            end
            'd2: begin
                SCLK <= 'b1;
            end
            'd3: begin
                SCLK <= 'b0;
            end
            'd4: begin
                SCLK <= 'b1;
            end
            'd5: begin
                SCLK <= 'b0;
                DIN <= r_channel[2];
            end
            'd6: begin
                SCLK <= 'b1;
            end
            'd7: begin
                SCLK <= 'b0;
                DIN <= r_channel[1];
            end
            'd8: begin
                SCLK <= 'b1;
            end
            'd9: begin
                SCLK <= 'b0;
                DIN <= r_channel[0];
            end
            'd10, 'd12, 'd14, 'd16, 'd18, 'd20, 'd22, 'd24, 'd26, 'd28, 'd30, 'd32: begin
                SCLK <= 'b1;
                r_data <= {r_data[10:0], DOUT};
            end
            'd11, 'd13, 'd15, 'd17, 'd19, 'd21, 'd23, 'd25, 'd27, 'd29, 'd31: begin
                SCLK <= 'b0;
            end
            'd33: begin
                CS_N <= 'b1;
            end
        endcase
    end
    else begin
        SCLK <= 'b1;
        CS_N <= 'b1;
        DIN <= 'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        done <= 'b0;
    else if (SCLK_CNT == 'd33)
        done <= 'b1;
    else
        done <= 'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data <= 'd0;
    else if (SCLK_CNT == 'd33)
        data <= r_data;
    else
        data <= 'd0;
end

endmodule

/*
wire add_cnt0, end_cnt0;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt0 <= 0;
    end
    else if (add_cnt0) begin
        if (end_cnt0)
            cnt0 <= 0;
        else
            cnt0 <= cnt0 + 1'b1;
    end
end
assign add_cnt0 = flag_add;
assign end_cnt0 = add_cnt0 && cnt0 == 100 - 1;

wire add_cnt1, end_cnt1;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt1 <= 0;
    end
    else if (add_cnt1) begin
        if (end_cnt1)
            cnt1 <= 0;
        else
            cnt1 <= cnt1 + 1'b1;
    end
end
assign add_cnt1 = end_cnt0;
assign end_cnt1 = add_cnt1 && cnt1 == 8 - 1;

wire flag
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flag <= 0;
    end
    else if (en) begin
        flag <= 1;
    end
    else if (end_cnt1) begin
        flag <= 0;
    end
end

wire sclk;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk <= 0;
    end
    else if (add_cnt0 && cnt0 == 50 -1) begin
        sclk <= 1;
    end
    else if (end_cnt0) begin
        sclk <= 0;
    end
end

wire mosi;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mosi <= 0;
    end
    else if (add_cnt1 && add_cnt0 && cnt0 == 1-1) begin
        mosi <= din[7 - cnt1];
    end
end
*/