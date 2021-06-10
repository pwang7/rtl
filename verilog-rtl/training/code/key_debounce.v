`timescale 1ns / 1ps

module key_debounce(
    input clk,
    input rst_n,

    input key_n,
    output deb_key_n
    );

parameter INTERVAL = 1_000_000;
parameter WIDTH = $clog2(INTERVAL + 1);

reg key_nr;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n==1'b0)
        key_nr <= 1;
    else 
        key_nr <= key_n;
end

wire key_pulse = key_nr & ~key_n;

reg key_pressed;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n==1'b0)
        key_pressed <= 0;
    else if (key_pulse)
        key_pressed <= 1;
    else if (end_cnt || key_n) begin
        key_pressed <= 0;
    end
end

reg[WIDTH-1:0] cnt;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        cnt <= 0;
    end
    else if (add_cnt) begin
        if (end_cnt)
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;
    end
    else begin
        cnt <= 0;
    end
end

assign add_cnt = key_pressed;
assign end_cnt = add_cnt && cnt == INTERVAL - 1;

reg key_stabled;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n==1'b0)
        key_stabled <= 0;
    else if (end_cnt)
        key_stabled <= 1;
    else if (key_n) begin
        key_stabled <= 0;
    end
end

assign deb_key_n = ~key_stabled;

endmodule
