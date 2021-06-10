`timescale 1ns / 1ps

module rr_sched(
    input clk,
    input rst_n,
    input q0_rdy,
    input q1_rdy,
    input q2_rdy,
    output [2:0] sel
    );

// localparam CNT_MAX = 3;
// localparam NO_SEL = 0;

// reg [2:0] cnt;
// wire add_cnt, end_cnt;
// always @ (posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         cnt <= 0;
//     end
//     else if (add_cnt) begin
//         if (end_cnt)
//             cnt <= 0;
//         else
//             cnt <= cnt + 1'b1;
//     end
// end

// assign add_cnt = 1;
// assign end_cnt = add_cnt && cnt == 3 - 1;

// assign sel = add_cnt ? (cnt == 0 ? (q0_rdy ? 3'd1 : NO_SEL) : (cnt == 1 ? (q1_rdy ? 3'd2 : NO_SEL) : (q2_rdy ? 3'd3 : NO_SEL))) : NO_SEL;

localparam IDLE = 3'b000,
           S0 = 3'b001,
           S1 = 3'b010,
           S2 = 3'b100;

reg [2:0] state_c, state_n; 

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end
always @ (*) begin
    case(state_c)
        IDLE: begin
            if (idle_s0_start) begin
                state_n = S0;
            end
            else if (idle_s1_start) begin
                state_n = S1;
            end
            else if (idle_s2_start) begin
                state_n = S2;
            end
            else begin
                state_n = state_c;
            end
        end
        S0: begin
            if (s0_s1_start) begin
                state_n = S1;
            end
            else if (s0_s2_start) begin
                state_n = S2;
            end
            else if (s0_idle_start) begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
        end
        S1: begin
            if (s1_s2_start) begin
                state_n = S2;
            end
            else if (s1_s0_start) begin
                state_n = S0;
            end
            else if (s1_idle_start) begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
        end
        S2: begin
            if (s2_s0_start) begin
                state_n = S0;
            end
            else if (s2_s1_start) begin
                state_n = S1;
            end
            else if (s2_idle_start) begin
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

wire no_rdy = !q0_rdy && !q1_rdy && !q2_rdy;

assign idle_s0_start = state_c == IDLE && q0_rdy;
assign idle_s1_start = state_c == IDLE && q1_rdy;
assign idle_s2_start = state_c == IDLE && q2_rdy;
assign s0_s1_start   = state_c == S0   && q1_rdy;
assign s0_s2_start   = state_c == S0   && q2_rdy;
assign s0_idle_start = state_c == S0   && no_rdy;
assign s1_s2_start   = state_c == S1   && q2_rdy;
assign s1_s0_start   = state_c == S1   && q0_rdy;
assign s1_idle_start = state_c == S1   && no_rdy;
assign s2_s0_start   = state_c == S2   && q0_rdy;
assign s2_s1_start   = state_c == S2   && q1_rdy;
assign s2_idle_start = state_c == S2   && no_rdy;

reg [2:0] out;
always @ (*) begin
    case(state_c)
        IDLE: out = 3'b000;
        S0: out = 3'b001;
        S1: out = 3'b010;
        S2: out = 3'b100;
        default: ;
    endcase
end
// always @ (posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         out <= 3'b000;
//     else
//     case(state_c)
//         IDLE: out <= 3'b000;
//         S0: out <= 3'b001;
//         S1: out <= 3'b010;
//         S2: out <= 3'b100;
//         default: ;
//     endcase
// end

assign sel = out;

endmodule
