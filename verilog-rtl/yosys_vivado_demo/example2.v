`default_nettype none

module example(
            input wire clk,
            output reg led);

        reg [24:0]     cnt = 25'b0;

        always @(posedge clk) begin
                cnt <= cnt + 1'b1;
                if (cnt == 25'b0) begin
                        led <= !led;
                end
                else begin
                        led <= led;
                end
        end

endmodule // top
