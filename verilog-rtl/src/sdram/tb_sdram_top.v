`timescale 1ns/1ns

module tb_sdram_top;

reg sclk;
reg s_rst_n;

wire sdram_clk;
wire sdram_cke;
wire sdram_cs_n;
wire sdram_cas_n;
wire sdram_ras_n;
wire sdram_we_n;
wire [1:0] sdram_bank;
wire [11:0] sdram_addr;
wire [1:0] sdram_dqm;
wire [15:0] sdram_dq;

reg wr_trig;
reg rd_trig;
initial begin
    wr_trig <= 0;
    rd_trig <= 0;
    #205000 // After init
    wr_trig <= 1;
    #20
    wr_trig <= 0;
    #126500
    rd_trig <= 1;
    #20
    rd_trig <= 0;
    #100
    $finish;
end

initial begin
    sclk = 1;
    s_rst_n <= 0;
    #100
    s_rst_n <= 1;
end
    
always #10 sclk = ~sclk;

sdram_top u_sdram_top(
    .sclk        (sclk        ),
    .reset       (s_rst_n     ),
    .sdram_clk   (sdram_clk   ),
    .sdram_cke   (sdram_cke   ),
    .sdram_cs_n  (sdram_cs_n  ),
    .sdram_cas_n (sdram_cas_n ),
    .sdram_ras_n (sdram_ras_n ),
    .sdram_we_n  (sdram_we_n  ),
    .sdram_bank  (sdram_bank  ),
    .sdram_addr  (sdram_addr  ),
    .sdram_dqm   (sdram_dqm   ),
    .sdram_dq    (sdram_dq    ),
    .wr_trig     (wr_trig     ),
    .rd_trig     (rd_trig     )
);

sdram_model_plus u_sdram_model_plus(
    .Dq      (sdram_dq),
    .Addr    (sdram_addr),
    .Ba      (sdram_bank),
    .Clk     (sdram_clk),
    .Cke     (sdram_cke),
    .Cs_n    (sdram_cs_n),
    .Ras_n   (sdram_ras_n),
    .Cas_n   (sdram_cas_n),
    .We_n    (sdram_we_n),
    .Dqm     (sdram_dqm),
    .Debug   (1'b1)
);

defparam u_sdram_model_plus.addr_bits = 12;             // 地址位宽
defparam u_sdram_model_plus.data_bits = 16;             // 数据位宽
defparam u_sdram_model_plus.col_bits  = 9;              // col地址位宽A0-A8
defparam u_sdram_model_plus.mem_sizes = 2*1024*1024-1;  // 2M

initial begin            
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars;
end

endmodule
