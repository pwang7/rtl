`timescale 1ns / 1ps

module fsm_seq_10010_mealy(
    input clk,
    input rst_n,
    input x,
    output z
    );

    parameter S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5;

    reg [2:0] state, next;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S1;
        else
            state <= next;
    end

    always @ (*) begin
        case (state)
            S1: next = x ? S2 : S1;
            S2: next = x ? S2 : S3;
            S3: next = x ? S2 : S4;
            S4: next = x ? S5 : S1;
            S5: next = x ? S2 : S3;
            default: next = S1;
        endcase
    end

    assign z = state == S5 && x == 0;
endmodule

module fsm_seq_10010_moore(
    input clk,
    input rst_n,
    input x,
    output z
    );

    parameter S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4, S5 = 3'd5, S6 = 3'd6;

    reg [2:0] state, next;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S1;
        else
            state <= next;
    end

    always @ (*) begin
        case (state)
            S1: next = x ? S2 : S1;
            S2: next = x ? S2 : S3;
            S3: next = x ? S2 : S4;
            S4: next = x ? S5 : S1;
            S5: next = x ? S2 : S6;
            S6: next = x ? S2 : S4;
            default: next = S1;
        endcase
    end

    assign z = state == S6;
endmodule