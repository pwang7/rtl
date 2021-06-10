`timescale 1ns / 1ps

module mux_dff (
    input clk,
    input w, R, E, L,
    output reg Q
);

    wire temp1, temp2;

    assign temp1 = E ? w:Q; 
    assign temp2 = L ? R:temp1;
    //与上题类似，不做赘述

    always @ (posedge clk)
        begin
           Q <= temp2; 
        end

endmodule




/*
module top_module (
    input clk,
    input reset,
    input [31:0] in,
    output [31:0] out
);

    reg [31:0] in_r;
    always @ (posedge clk)
        begin
            in_r <= in;
        end
    
    always @ (posedge clk) begin
        if (reset) begin
            out <= '0;
        end
        else begin
            //if (in_r & ~in)
            //	out <= in_r ^ in; // WHY NOT BITWISE COMPARE?
            for (int i = 0; i < $bits(in); i = i + 1)
                if (in_r[i] && ~in[i])
                    out[i] <= 1'b1;
        end
    end
endmodule
*/


/*
module top_module (
    input clk,
    input reset,
    input [3:1] s,
    output fr3,
    output fr2,
    output fr1,
    output dfr
);
    parameter B1 = 0, B12 = 1, B23 = 2, A3 = 3;
    reg [1:0] state_c, state_n;
    wire b1_b12_start, b12_b1_start, b12_b23_start, b23_b12_start, b23_a3_start, a3_b23_start;

always @ (posedge clk) begin
    if (reset) begin
        state_c <= s[1];
    end
    else begin
        state_c <= state_n;
    end
end
always @ (*) begin
    (* full_case = 1, parallel_case = 1 *)
    case(state_c)
        B1: begin
            if (b1_b12_start) begin
                state_n = B12;
            end
            else begin
                state_n = state_c;
            end
        end
        B12: begin
            if (b12_b23_start) begin
                state_n = B23;
            end
            else if (b12_b1_start) begin
                state_n = B1;
            end
            else begin
                state_n = state_c;
            end
        end
        B23: begin
            if (b23_a3_start) begin
                state_n = A3;
            end
            else if (b23_b12_start) begin
                state_n = B12;
            end
            else begin
                state_n = state_c;
            end
        end
        A3: begin
            if (a3_b23_start) begin
                state_n = B23;
            end
            else begin
                state_n = state_c;
            end
        end
        default: begin
            state_n = B1;
        end
    endcase
end
    assign b1_b12_start = state_c == B1 && s[1];
    assign b12_b1_start = state_c == B12 && ~s[1];
    assign b12_b23_start = state_c == B12 && s[2];
    assign b23_b12_start = state_c == B23 && ~s[2];
    assign b23_a3_start = state_c == B23 && s[3];
    assign a3_b23_start = state_c == A3 && ~s[3];

    reg state_lower
    always @(posedge clk)begin
        if (reset || state < state_next)
            state_lower <= 1'b0;
        else if (state > state_next)
            state_lower <= 1'b1;
    end

    reg dfr_on;
    always @ (posedge clk) begin
        if (reset)
            dfr_on <= 0;
        //else if (a3_b23_start | b23_b12_start | b12_b1_start)
        else if (state_c > state_n)
            dfr_on <= 1;
        else if (state_c < state_n)
        //else if (b1_b12_start | b12_b23_start | b23_a3_start)
            dfr_on <= 0;
	end
	assign dfr = state_c == B1 || dfr_on;

always @ (posedge clk) begin
    if (reset) begin
        {fr1, fr2, fr3} <= 3'b111;
    end
    else case(state_n)
        B1: begin
            {fr1, fr2, fr3} <= 3'b111;
        end
        B12: begin
            {fr1, fr2, fr3} <= 3'b110;
        end
        B23: begin
            {fr1, fr2, fr3} <= 3'b100;
        end
        A3: begin
            {fr1, fr2, fr3} <= 3'b000;
        end
        default: ;
    endcase
end
endmodule

*/