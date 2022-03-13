module dpram #(parameter DEPTH = 16,
               parameter WIDTH = 8 )(
        input                       wclk        ,
        input                       wenc        ,
        input   [$clog2(DEPTH)-1:0] waddr       ,   
        input   [$clog2(DEPTH)-1:0] raddr       ,   
        input   [WIDTH-1:0]         wdata       ,
        input                       rclk        ,
        input                       renc        ,
        output reg [WIDTH-1:0]      rdata        
        );
reg [WIDTH-1:0] ram [0:DEPTH-1];

always @(posedge wclk)begin 
    if(wenc)
        ram[waddr] <= wdata;
end 

always @(posedge rclk)begin 
    if(renc)
        rdata <= ram[raddr] ;
end 

endmodule 
