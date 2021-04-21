`timescale 1ns / 10ps

module header_detect(
  input clk,
  input rst_n,
  input [7:0] din
);

reg [7:0] din_r0, din_r1;
reg [7:0] cnt0, cnt1;
wire add_cnt0, add_cnt1;
wire end_cnt0, end_cnt1;
wire flag_add;
  
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    din_r0 <= 0;
    din_r1 <= 1;
  end
  else begin
    din_r1 <= din_r0;
    din_r0 <= din;
  end
end

assign flag_add = (din_r1 ==8'h55 && din_r0 == 8'hd5) || (din_r1 ==8'hd5 && din_r0 == 8'h55);
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
       cnt0 <= 0;
  else if (add_cnt0) begin
    if(end_cnt0)
       cnt0 <= 0;
    else
       cnt0 <= cnt0 + 1;
  end
  else
    cnt0 <= 0;
end
assign add_cnt0 = flag_add;
assign end_cnt0 = add_cnt0 && cnt0 == 2-1;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
       cnt1 <= 0;
  else if (add_cnt1)  begin
    if(end_cnt1)
       cnt1 <= 0;
    else
       cnt1 <= cnt1 + 1;
  end
end
assign add_cnt1 = flag_add && end_cnt0;
assign end_cnt1 = add_cnt1 && cnt1 == 5-1;

`ifdef ILA_CFG_RX
ila_cfg_rx u_ila_cfg_rx(
    .clk(clk),
    .probe0(),
    .probe1(),
    .probe2(),
    .probe3()
);
`endif

endmodule

