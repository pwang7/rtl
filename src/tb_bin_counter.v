`timescale 1ns / 10ps

module tb_bin_counter();

// declaration
localparam T = 20;
reg clk, rst_n;
reg syn_clr, load, en, up;
reg [2:0] d;
wire max_tick, min_tick;
wire [2:0] q;

initial begin            
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars(0, tb_bin_counter); // tb module name
end

// uut instantiation
bin_counter #(.N(3)) u_bin_counter(
    .clk(clk),
    .rst_n(rst_n),
    .syn_clr(syn_clr),
    .load(load),
    .en(en),
    .up(up),
    .d(d),
    .max_tick(max_tick),
    .min_tick(min_tick),
    .q(q)
);

// clock
// 20ns clock running forever
always begin
    clk = 1'b1;
    #(T/2);
    clk = 1'b0;
    #(T/2);
end

// reset for the first half cycle
initial begin
    rst_n = 1'b0;
    #(T/2);
    rst_n = 1'b1;
end

// other stimulus
initial begin
    // initial input
    syn_clr = 1'b0;
    load = 1'b0;
    en = 1'b0;
    up = 1'b1; // count up
    d = 3'b000;
    @(posedge rst_n); // wait for reset to deassert
    @(negedge clk);
    // test load
    load = 1'b1;
    d = 3'b011;
    @(negedge clk);
    load = 1'b0;
    repeat(2) @(negedge clk);
    // test syn_clr
    syn_clr = 1'b1; // assert clear
    @(negedge clk);
    syn_clr = 1'b0;
    // test up counter and pause
    en = 1'b1; // count
    up = 1'b1;
    repeat(10) @(negedge clk);
    en = 1'b0; // pause
    repeat(2) @(negedge clk);
    en = 1'b1;
    repeat(2) @(negedge clk);
    // test down counter
    up = 1'b0;
    repeat(10) @(negedge clk);
    // wait statement
    // continue until q = 2
    wait(q == 2);
    @(negedge clk);
    up = 1'b1;
    // continue until min_tick becomes 1
    @(negedge clk);
    wait(min_tick);
    @(negedge clk);
    up = 1'b0;
    // absolute delay
    #(4*T); // wait for 80ns
    en = 1'b0; // pause
    #(4*T) // wait for 80ns
    // stop simulation
    // return to interactive simulation mode
    $stop;
end

endmodule