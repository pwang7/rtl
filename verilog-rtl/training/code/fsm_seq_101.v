`timescale 1ns / 1ps

// The question is from:
// https://hdlbits.01xz.net/wiki/Exams/ece241_2013_q8
//
// FSM state transition graph:
// https://blog.csdn.net/Reborn_Lee/article/details/103453737
module answer_01xz(
	input clk,
	input aresetn,
	input x,
	output reg z
);

	// Give state names and assignments. I'm lazy, so I like to use decimal numbers.
	// It doesn't really matter what assignment is used, as long as they're unique.
	parameter S=0, S1=1, S10=2;
	reg[1:0] state, next;		// Make sure state and next are big enough to hold the state encodings.
	
	
	
	// Edge-triggered always block (DFFs) for state flip-flops. Asynchronous reset.			
	always@(posedge clk, negedge aresetn)
		if (!aresetn)
			state <= S;
		else
			state <= next;
			
	

    // Combinational always block for state transition logic. Given the current state and inputs,
    // what should be next state be?
    // Combinational always block: Use blocking assignments.    
	always@(*) begin
		case (state)
			S: next = x ? S1 : S;
			S1: next = x ? S1 : S10;
			S10: next = x ? S1 : S;
			default: next = S;
		endcase
	end
	
	
	
	// Combinational output logic. I used a combinational always block.
	// In a Mealy state machine, the output depends on the current state *and*
	// the inputs.
	always@(*) begin
		case (state)
			S: z = 0;
			S1: z = 0;
			S10: z = x;		// This is a Mealy state machine: The output can depend (combinational) on the input.
			default: z = 1'bX;
		endcase
	end
	
endmodule

// My solution
module fsm_seq_101_mealy (
    input clk,
    input aresetn,    // Asynchronous active-low reset
    input x,
    output z ); 

    parameter S1 = 3'b00, S2 = 3'b01, S3 = 3'b10;
    reg [1:0] state_c, state_n;
    always @ (posedge clk or negedge aresetn) begin
        if (!aresetn)
            state_c <= S1;
        else
            state_c <= state_n;
    end
    
    always @ (*) begin
        case (state_c)
            S1: state_n = x ? S2 : S1;
            S2: state_n = x ? S2 : S3;
            S3: state_n = x ? S2 : S1;
            default: state_n = S1;
        endcase
    end
    
    assign z = state_c == S3 && x == 1;
endmodule

module fsm_seq_101_moore (
    input clk,
    input aresetn,    // Asynchronous active-low reset
    input x,
    output z ); 

    parameter S1 = 0, S2 = 1, S3 = 2, S4 = 4;
    reg [2:0] state_c, state_n;
    always @ (posedge clk or negedge aresetn) begin
        if (!aresetn)
            state_c <= S1;
        else
            state_c <= state_n;
    end
    
    always @ (*) begin
        case (state_c)
            S1: state_n = x ? S2 : S1;
            S2: state_n = x ? S2 : S3;
            S3: state_n = x ? S4 : S1;
            S4: state_n = x ? S2 : S3;
            default: state_n = S1;
        endcase
    end
    reg z_r;
    always @ (posedge clk or negedge aresetn) begin
        if (!aresetn)
            z_r <= 0;
        else if (state_n == S4)
            z_r <= 1;
        else
            z_r <= 0;
    end
    assign z = z_r;
endmodule