`timescale 1ns/1ns 
module tb_afifo();
parameter DEPTH = 256;
parameter WIDTH = 16;

reg wclk_i , wrst_n_i , rclk_i,rrst_n_i ;
reg wen_i,ren_i ;
reg [WIDTH-1:0] wdata_i ;
wire [WIDTH-1:0] rdata_o ;
wire wfull_o,rempty_o;
//=====================clock and reset=====================\
initial begin 
    wclk_i = 0 ;
    forever begin 
        #5 wclk_i  =~wclk_i ;//100MHz  
    end 

end 

initial begin 
    rclk_i = 0 ;
    forever begin 
        #10 rclk_i  =~rclk_i ;//50MHz  
    end 

end 

initial begin 
wrst_n_i = 0;  
rrst_n_i = 0;
#33 rrst_n_i =1 ;
#41 wrst_n_i = 1 ;
end 
//dump fsdb 
initial begin 
    $fsdbDumpfile("fifo.fsdb");
    $fsdbDumpvars(0);
end 

//==========================================================/
parameter  WID   = 3'b001 ;
parameter  WR    = 3'b010 ;
parameter  WST   = 3'b100 ;

parameter  RID   = 3'b001 ;
parameter  RD    = 3'b010 ;
parameter  RST   = 3'b100 ;

reg [2:0] wcs,rcs;

always @(posedge wclk_i or negedge wrst_n_i)begin 
    if(wrst_n_i==1'b0)begin 
        wen_i <=1'b0 ;
        wcs   <= WID;
        wdata_i <= 0;
    end 
    else begin 
        case(wcs)
            WID:begin 
                if(wfull_o == 1'b0)
                    wcs <= WR;
                wdata_i <= 0;
                wen_i   <= 0;
            end 
            WR:begin 
                wdata_i <= wdata_i + 1;
                wen_i   <= 1;
                if(wfull_o == 1'b1)begin 
                    wcs <= WST;
                    wen_i <= 0 ;
                end 
            end 
            WST:begin 
                wdata_i <= 0;
                wen_i   <= 0;
            end 
        endcase 

    end 

end 

always @(posedge rclk_i or negedge rrst_n_i)begin 
    if(rrst_n_i==1'b0)begin 
        ren_i <=1'b0 ;
        rcs   <= RID;
    end 
    else begin 
        case(rcs)
            RID:begin 
                if(wfull_o == 1'b1)
                    rcs <= RD;
                ren_i   <= 0;
            end 
            RD:begin 
                ren_i   <= 1;
                if(rempty_o== 1'b1)begin
                    rcs <= RST;
                    ren_i <= 0;
                end 
            end 
            RST:begin 
                ren_i   <= 0;
            end 
        endcase 

    end 

end 

always @(posedge rclk_i) begin 
    if(wcs[2]&&rcs[2])
        $finish;
end 

afifo #( .DEPTH(DEPTH),
         .WIDTH(WIDTH))
afifo_inst0(
        .wclk_i      (wclk_i      ),
        .wrst_n_i    (wrst_n_i    ),
        .wen_i       (wen_i       ),
        .wdata_i     (wdata_i     ),
        .wfull_o     (wfull_o     ),
        .rclk_i      (rclk_i      ),
        .rrst_n_i    (rrst_n_i    ),
        .ren_i       (ren_i       ),
        .rdata_o     (rdata_o     ),
        .rempty_o    (rempty_o    )      
        );

endmodule 
