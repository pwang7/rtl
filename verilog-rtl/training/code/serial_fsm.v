`timescale 1ns / 1ps


module serial_fsm2(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output [7:0] out_byte,
    output done
); 
    
    localparam idle = 0;
    localparam start = 1;
    localparam data = 2;
    localparam stop =3;
    localparam error = 4;
    
    reg[2:0] state, next_state;
    reg[3:0] cnt;
    reg done_r;
    reg[7:0] out;
    
//transition
    always@(*)begin
        case(state)
            idle:next_state=in?idle:start;
            start:next_state=data;
            data:next_state=(cnt==8)?(in?stop:error):data;
            stop:next_state=in?idle:start;
            error:next_state=in?idle:error;
        endcase
    end
    
//state
    always@(posedge clk)begin
        if(reset)
            state <= idle;
        else
            state <= next_state;
    end
    
//out
    always@(posedge clk)begin
        if(reset)
            out<=0;
        else
            case(next_state)
                start:out<=0;
                data:out<={in,out[7:1]}; //移位寄存器
            endcase
    end
    
//cnt
    always@(posedge clk)begin
        if(reset)
            cnt<=0;
        else
            case(next_state)
                start:cnt<=0;
                data:cnt<=cnt+1;
                default:cnt<=cnt;
            endcase
    end
    
//done_r
    always@(posedge clk)
        case(next_state)
            stop:done_r <= 1;
            default:done_r <= 0;
        endcase
    
    assign done = done_r;
    assign out_byte = out;
    
endmodule

module serial_fsm(
    input clk,
    input in,
    input reset,    // Synchronous reset
    output [7:0] out_byte,
    output done
); //

    // Use FSM from Fsm_serial

    // New: Datapath to latch input bits.
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3, ERROR = 4;
    reg [2:0] state_c, state_n;
    reg done_r;
    
    always @ (posedge clk) begin
        if (reset)
            state_c <= IDLE;
        else
        	state_c <= state_n;
    end

    reg [3:0] cnt;
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
    assign add_cnt = state_c == DATA;
    assign end_cnt = add_cnt && cnt == 8 - 1;

    always @ (*) begin
        case (state_c)
        	IDLE: state_n = in ? IDLE : START;
            START: state_n = DATA;
            DATA: state_n = end_cnt ? (in ? STOP : ERROR) : DATA;
            STOP: state_n = in ? IDLE : START;
            ERROR: state_n = in ? IDLE : ERROR;
            default: ;
        endcase
    end

    always @ (posedge clk) begin
        if (reset)
            done_r <= 0;
        else if (state_n == STOP)
        	done_r <= 1;
        else
            done_r <= 0;
    end
    assign done = done_r;
    
    reg [7:0] out_byte_r;
    always @ (posedge clk) begin
        if (reset) begin
            out_byte_r <= 0;
        end
        else if (state_n == DATA) begin
            out_byte_r <= {in, out_byte_r[7:1]};
        end
    end
    
    assign out_byte = out_byte_r;
endmodule