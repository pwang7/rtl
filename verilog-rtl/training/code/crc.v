`timescale 1ns / 1ps

// CRC10: x^10 + x^9 + x^5 + x^4 + x + 1
module crc(
    input clk,
    input rst_n,

    input en,
    input [31:0] din,
    output [9:0] dout
    );

reg [9:0] crc_reg;
reg crc_fb;
integer i;

// always @ (posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         crc_reg <= 0;
//         crc_fb <= 0;
//     end
//     else if (en)
//         for (i = 0; i < 31; i = i + 1) begin
//             crc_fb = crc_reg[9];
//             crc_reg[9] = crc_reg[8] ^ crc_fb;
//             crc_reg[8] = crc_reg[7];
//             crc_reg[7] = crc_reg[6];
//             crc_reg[6] = crc_reg[5];
//             crc_reg[5] = crc_reg[4] ^ crc_fb;
//             crc_reg[4] = crc_reg[3] ^ crc_fb;
//             crc_reg[3] = crc_reg[2];
//             crc_reg[2] = crc_reg[1];
//             crc_reg[1] = crc_reg[0] ^ crc_fb;
//             crc_reg[0] = din[i] ^ crc_fb;
//         end
// end

assign dout = crc_reg;
/*
reg[9:0] crc_tmp;
reg init;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_reg <= 0;
        init <= 0;
    end
    else if (en)
        crc_reg <= crc_tmp;
end

always @ (*) begin
    if (en) begin
        if (!init) begin
            init = 1;
            crc_tmp = 0;
            crc_fb = 0;
        end
        for (i = 0; i < 31; i = i + 1) begin
            crc_fb = crc_tmp[9];
            crc_tmp[9] = crc_tmp[8] ^ crc_fb;
            crc_tmp[8] = crc_tmp[7];
            crc_tmp[7] = crc_tmp[6];
            crc_tmp[6] = crc_tmp[5];
            crc_tmp[5] = crc_tmp[4] ^ crc_fb;
            crc_tmp[4] = crc_tmp[3] ^ crc_fb;
            crc_tmp[3] = crc_tmp[2];
            crc_tmp[2] = crc_tmp[1];
            crc_tmp[1] = crc_tmp[0] ^ crc_fb;
            crc_tmp[0] = din[i] ^ crc_fb;
        end
    end
    else
        init = 0;
end
*/

parameter IDLE = 1'd0, COMPUTE = 1'd1;
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
    (* full_case = 1, parallel_case = 1 *)
    case(state_c)
        IDLE: begin
            if (i2c_start) begin
                state_n = COMPUTE;
            end
            else begin
                state_n = state_c;
            end
        end
        COMPUTE: begin
            if (c2i_start) begin
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
assign i2c_start = state_c == IDLE && en;
assign c2i_start = state_c == COMPUTE && !en;

always @ (*) begin
    case(state_c)
        IDLE: begin
            crc_reg = 0;
            crc_fb = 0;
        end
        COMPUTE:
            for (i = 0; i < 31; i = i + 1) begin
                crc_fb = crc_reg[9];
                crc_reg[9] = crc_reg[8] ^ crc_fb;
                crc_reg[8] = crc_reg[7];
                crc_reg[7] = crc_reg[6];
                crc_reg[6] = crc_reg[5];
                crc_reg[5] = crc_reg[4] ^ crc_fb;
                crc_reg[4] = crc_reg[3] ^ crc_fb;
                crc_reg[3] = crc_reg[2];
                crc_reg[2] = crc_reg[1];
                crc_reg[1] = crc_reg[0] ^ crc_fb;
                crc_reg[0] = din[i] ^ crc_fb;
            end
        default: ;
    endcase
end

endmodule
