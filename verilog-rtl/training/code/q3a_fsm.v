`timescale 1ns / 1ps

module q3a_fsm2(
    input clk,
    input reset,   // Synchronous reset
    input s,
    input w,
    output z
);

    parameter A = 0, B0 = 1, B1 = 2, B2 = 3;
    reg [1:0] state_c, state_n;
    reg [1:0] sum_r;
    always @ (posedge clk) begin
        if (reset)
            state_c <= 0;
        else
            state_c <= state_n;
    end
    always @ (*) begin
        case (state_c)
            A: state_n = s ? B0 : A;
            B0: state_n = B1;
            B1: state_n = B2;
            B2: state_n = B0;
            default: state_n = A;
        endcase
    end
    always @ (posedge clk) begin
        if (reset)
            sum_r <= 0;
        case (state_c)
            B0: sum_r <= w;
            B1: sum_r <= sum_r + w;
            B2: sum_r <= sum_r + w;
            default: sum_r <= 0;
        endcase
    end
    assign z = (state_c == B0) && (sum_r == 2);

endmodule


module q3a_fsm(
    input clk,
    input reset,   // Synchronous reset
    input s,
    input w,
    output z
);

    parameter A = 0, B = 1;
    reg state_c, state_n;
    always @ (posedge clk) begin
        if (reset)
            state_c <= A;
        else
            state_c <= state_n;
    end

    always @ (*) begin
        case (state_c)
            A: state_n = s ? B : A;
            B: state_n = B;
            default: state_n = A;
        endcase
    end

    reg [1:0] cnt;
    wire add_cnt, end_cnt;
    always @ (posedge clk) begin
        if (reset) begin
            cnt <= 0;
        end
        else if (add_cnt) begin
            if (end_cnt)
                cnt <= 0;
            else
                cnt <= cnt + 1'b1;
        end
    end
    assign add_cnt = state_c == B;
    assign end_cnt = add_cnt && cnt == 3 - 1;
    
    reg [1:0] sum;
    always @ (posedge clk) begin
        if (reset) begin
            sum <= 0;
        end
        else
            if (add_cnt & cnt == 1 - 1) begin
                sum <= w;
            end
            else begin
                sum <= sum + w;
            end
    end
    
    assign z = (add_cnt && cnt == 1 - 1) && sum == 2;
endmodule

