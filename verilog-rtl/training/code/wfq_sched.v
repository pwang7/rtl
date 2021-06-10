`timescale 1ns / 1ps

module wfq_sched #(
    parameter QUEUE_WEIGHT_WIDTH = 7,
    parameter QUEUE_NUM_WIDTH = 2,
    parameter QUEUE_NUM = 2**QUEUE_NUM_WIDTH
)(
    input clk,
    input rst_n,

    input [QUEUE_NUM*QUEUE_WEIGHT_WIDTH-1:0] wfq_weight,
    input [QUEUE_NUM-1:0] wfq_rdy,
    input wfq_sch_en,

    output wfq_winner_vld,
    output [QUEUE_NUM_WIDTH-1:0] wfq_winner
    );

localparam IDLE = 1'b0,
           SELECT = 1'b1;

reg [QUEUE_WEIGHT_WIDTH-1:0] tmp_weight [0:QUEUE_NUM_WIDTH-1];
reg state_c, state_n;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_c<= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

always @ (*) begin
    case(state_c)
        IDLE: begin
            if (i2s_start) begin
                state_n = SELECT;
            end
            else begin
                state_n = state_c;
            end
        end
        SELECT: begin
            if (s2i_start) begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
        end
        default: begin
            state_n = IDLE;
        end
    endcase
end


assign i2s_start = state_c == IDLE && wfq_sch_en;
assign s2i_start = state_c == SELECT && !wfq_sch_en;

reg [QUEUE_NUM_WIDTH-1:0] min_weight_idx, pre_min_idx, q_idx;
reg init_min_idx;
// Select the queue with minimum weight and update its weight
always @ (*) begin
    case(state_c)
        IDLE: begin
            for (q_idx = 0; q_idx < QUEUE_NUM; q_idx = q_idx + 1) begin
                tmp_weight[q_idx] = wfq_weight[((q_idx + 1) * QUEUE_NUM_WIDTH - 1) -:QUEUE_NUM_WIDTH];
            end
        end
        SELECT: begin
            init_min_idx = 0;
            min_weight_idx = 0;
            if (wfq_rdy) begin
                // Select the queue with minimum weight, excluding the non-ready ones and previous chosen one
                for (q_idx = 0; q_idx < QUEUE_NUM; q_idx = q_idx + 1) begin
                    if (wfq_rdy[q_idx] && q_idx != pre_min_idx) begin
                        if (!init_min_idx) begin
                            min_weight_idx = q_idx;
                            init_min_idx = 1;
                        end
                        else if (tmp_weight[q_idx] < tmp_weight[min_weight_idx])
                            min_weight_idx = q_idx;
                    end
                end

                // Update the weight of all ready queues
                for (q_idx = 0; q_idx < QUEUE_NUM; q_idx = q_idx + 1) begin
                    if (wfq_rdy[q_idx] && q_idx != min_weight_idx) begin
                        tmp_weight[q_idx] = tmp_weight[q_idx] - tmp_weight[min_weight_idx];
                    end
                end

                // Update the weight of the minimum weight queue
                tmp_weight[min_weight_idx] = wfq_weight[((min_weight_idx + 1) * QUEUE_NUM_WIDTH - 1) -:QUEUE_NUM_WIDTH];
            end
        end
        default: ;
    endcase
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pre_min_idx <= 0;
    end
    else
        pre_min_idx <= min_weight_idx;
end

assign wfq_winner = min_weight_idx;
assign wfq_winner_vld = wfq_sch_en && wfq_rdy;

endmodule
