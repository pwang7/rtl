module tb_sdram_exec1;

parameter CYCLE  = 10;
parameter DATA_W = 16;
parameter IADD_W = 22;
parameter OADD_W = 12;

reg clk;
reg rst_n;
wire cke;
wire cs;
wire ras;
wire cas;
wire we;
wire [1:0] dqm;
wire [OADD_W-1:0]  addr;
wire [1:0] bank;
wire [DATA_W-1:0] dq;

reg data_w_en;

sdram_init_aref 
#(
    .DATA_W      (DATA_W      ),
    .IADD_W      (IADD_W      ),
    .OADD_W      (OADD_W      )
)
u_sdram_init_aref(
    .clk       (clk       ),
    .rst_n     (rst_n     ),
    .cke       (cke       ),
    .cs        (cs        ),
    .ras       (ras       ),
    .cas       (cas       ),
    .we        (we        ),
    .dqm       (dqm       ),
    .addr      (addr      ),
    .bank      (bank      ),
    .dq        (dq        ),
    .data_w_en (data_w_en )
);

initial begin
    clk = 0;
    forever begin
        #(CYCLE/2) clk = ~clk;
    end
end

initial begin
    rst_n = 'b0;
    #(10*CYCLE) rst_n = 'b1;
end


endmodule