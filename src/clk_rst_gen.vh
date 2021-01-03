
reg clk;
reg rst_n;

localparam PERIOD = 10;
localparam RST_CYCLE = 2;

initial begin
    clk=0;
    rst_n = 0;
    repeat (RST_CYCLE) @(negedge clk);
    rst_n = 1;
end

//always #(PERIOD * 0.5)  clk = ~clk;
always begin
    clk = 'b1;
    #(PERIOD/2);
    clk = 'b0;
    #(PERIOD/2);
end

initial begin            
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars;
end
