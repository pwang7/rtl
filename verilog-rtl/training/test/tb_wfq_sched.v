`timescale 1ns / 1ps

module tb_wfq_sched();

localparam QUEUE_WEIGHT_WIDTH = 7,
           QUEUE_NUM_WIDTH = 2,
           QUEUE_NUM = 2**QUEUE_NUM_WIDTH;

reg clk;
reg rst_n;
reg [QUEUE_NUM*QUEUE_WEIGHT_WIDTH-1:0] wfq_weight;
reg [QUEUE_NUM-1:0] wfq_rdy;
reg wfq_sch_en;
wire wfq_winner_vld;
wire [QUEUE_NUM_WIDTH-1:0] wfq_winner;
integer idx;

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 1;
    wfq_sch_en = 0;
    wfq_rdy = {QUEUE_NUM{1'b1}};
    for (idx = 0; idx < QUEUE_NUM; idx = idx + 1) begin
        wfq_weight[((idx + 1) * QUEUE_NUM_WIDTH - 1) -:QUEUE_NUM_WIDTH] = idx + 1;
    end

    #15 rst_n = 1;
    @(posedge clk);
    wfq_sch_en = 1;
end

wfq_sched u_wfq_sched(
    .clk(clk),
    .rst_n(rst_n),
    .wfq_weight(wfq_weight),
    .wfq_rdy(wfq_rdy),
    .wfq_sch_en(wfq_sch_en),
    .wfq_winner_vld(wfq_winner_vld),
    .wfq_winner(wfq_winner)
    );
endmodule
