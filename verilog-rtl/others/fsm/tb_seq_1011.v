`timescale 1ns/1ns 
module tb_seq_1011();
reg  clk_i    ;   
reg  rst_n_i  ;   
reg [5:0]  seq_i    ;   
wire out_o    ;   
initial begin 
    clk_i = 0 ;
    forever begin
        #10 clk_i = ~clk_i ;
    end 
end 

initial begin 
rst_n_i = 0 ;
#43 rst_n_i = 1 ;
#1000;
    $finish;
end 

always @(posedge clk_i or negedge rst_n_i)begin
    if(!rst_n_i)    
        seq_i <= 6'b1_1011_0 ;
    else 
        seq_i <= {seq_i[4:0],seq_i[5]} ;
end 
initial begin 
    $fsdbDumpfile("seq_1011.fsdb");
    $fsdbDumpvars(0);
end 

detect_1011 detect_1011_inst(
        .clk_i       (clk_i       ),
        .rst_n_i     (rst_n_i     ),
        .seq_i       (seq_i[0]    ),
        .out_o       (out_o       ) 
        );

endmodule 
