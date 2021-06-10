`timescale 1ns / 1ps

module conway_life #(
    parameter ROWS = 16,
    parameter COLS = 16
)(
    input clk,
    input load,
    input [(ROWS * COLS - 1):0] data,
    output reg [(ROWS * COLS - 1):0] q );

    reg [3:0] neighbor_sum [(ROWS * COLS - 1):0];
    reg [(ROWS * COLS - 1):0] q_n;
    
    always @ (*) begin: NEXT_STATE
        integer u_idx, d_idx, l_idx, r_idx;
        for(integer row_idx = 0; row_idx < ROWS; row_idx = row_idx + 1) begin
            for (integer col_idx = 0; col_idx < COLS; col_idx = col_idx + 1) begin
                d_idx = (row_idx < ROWS - 1) ? row_idx + 1 : 0;
                u_idx = (row_idx > 0) ? row_idx - 1 : ROWS - 1;
                r_idx = (col_idx < COLS - 1) ? col_idx + 1 : 0;
                l_idx = (col_idx > 0) ? col_idx - 1 : COLS - 1;

                neighbor_sum[row_idx * COLS + col_idx] =
                (q[u_idx * COLS + l_idx] + q[u_idx * COLS + col_idx] + q[u_idx * COLS + r_idx] +
                 q[row_idx * COLS + l_idx]              +            q[row_idx * COLS + r_idx] +
                 q[d_idx * COLS + l_idx] + q[d_idx * COLS + col_idx] + q[d_idx * COLS + r_idx]);

                if (neighbor_sum[row_idx * COLS + col_idx] < 2) q_n[row_idx * COLS + col_idx] = 0;
                else if (neighbor_sum[row_idx * COLS + col_idx] > 3) q_n[row_idx * COLS + col_idx] = 0;
                else if (neighbor_sum[row_idx * COLS + col_idx] == 3) q_n[row_idx * COLS + col_idx] = 1;
                else q_n[row_idx * COLS + col_idx] = q[row_idx * COLS + col_idx];
            end
        end
    end
    
    always @ (posedge clk) begin
        if (load) begin
            q <= data;
    	end
        else begin
            q <= q_n;
        end
    end
endmodule