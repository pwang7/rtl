module bcd_to_7seg (
   input clk,
   input reset,
   input [3:0] bcd,
   output [6:0] seven_seg_display
);
parameter TP = 1;
reg seg_a;
reg seg_b;
reg seg_c;
reg seg_d;
reg seg_e;
reg seg_f;
reg seg_g;

always @ (posedge clk or posedge reset)
    begin
    if (reset)
        begin
            seg_a <= #TP 1'b0;
            seg_b <= #TP 1'b0;
            seg_c <= #TP 1'b0;
            seg_d <= #TP 1'b0;
            seg_e <= #TP 1'b0;
            seg_f <= #TP 1'b0;
            seg_g <= #TP 1'b0;
        end
    else
        begin
            seg_a <= #TP ~(bcd == 4'h1 || bcd == 4'h4);
            seg_b <= #TP bcd < 4'h5 || bcd > 6;
            seg_c <= #TP bcd != 2;
            seg_d <= #TP bcd == 0 || bcd[3:1] == 3'b001 || bcd == 5 || bcd == 6 || bcd == 8;
            seg_e <= #TP bcd == 0 || bcd == 2 || bcd == 6 || bcd == 8;
            seg_f <= #TP bcd == 0 || bcd == 4 || bcd == 5 || bcd == 6 || bcd > 7;
            seg_g <= #TP (bcd > 1 && bcd < 7) || (bcd > 7);
        end
    end

    assign seven_seg_display = {seg_g, seg_f, seg_e, seg_d, seg_c, seg_b, seg_a};
endmodule
