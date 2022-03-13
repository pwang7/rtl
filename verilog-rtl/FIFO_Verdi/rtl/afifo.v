module afifo #( parameter DEPTH = 16,
                parameter WIDTH = 8)(
        input                   wclk_i      ,
        input                   wrst_n_i    ,
        input                   wen_i       ,
        input   [WIDTH-1:0]     wdata_i     ,
        output                  wfull_o     ,
        input                   rclk_i      ,
        input                   rrst_n_i    ,
        input                   ren_i       ,
        output  [WIDTH-1:0]     rdata_o     ,
        output                  rempty_o          
        );
parameter ADDR_WID = $clog2(DEPTH) ;//address width 
//=============================write logic================================\
reg [ADDR_WID:0]  waddr;//write address register ,the MSB is for judge Write FULL or Read EMPTY
reg [ADDR_WID:0]  raddr_sync ;//read address from read clock domain,has been decoded
wire wen_ram ;//enable to write ram

always @(posedge wclk_i or negedge wrst_n_i)begin//write address  point
    if(!wrst_n_i)
        waddr <= 'd0;
    else if(wen_ram) 
        waddr <= waddr + 1'b1 ;
end 
assign wen_ram = wen_i & ~wfull_o;//no full and is enable to write  

assign wfull_o = (waddr[ADDR_WID]^raddr_sync[ADDR_WID])&&(waddr[ADDR_WID-1:0]==raddr_sync[ADDR_WID-1:0]);

//=============================write logic================================/


//=============================read logic================================\
reg [ADDR_WID:0]  raddr;//read address register ,the MSB is for judge Write FULL or Read EMPTY
reg [ADDR_WID:0]  waddr_sync ;//write address from write clock domain,has been decoded
wire ren_ram ;//enable to read ram

always @(posedge rclk_i or negedge rrst_n_i)begin//read address  point
    if(!rrst_n_i)
        raddr <= 'd0;
    else if(ren_ram) 
        raddr <= raddr + 1'b1 ;
end 
assign ren_ram = ren_i & ~rempty_o;//no empty and is enable to read  

assign rempty_o = (raddr[ADDR_WID:0]==waddr_sync[ADDR_WID:0]);

//=============================read  logic================================/

//============address cross clock domain ===============================\
//write to read 
reg [ADDR_WID:0] gray_waddr,gray_buf1_w2r,gray_buf2_w2r ;
always @(posedge wclk_i or negedge wrst_n_i)begin //binary 2 gray for waddr 
    if(~wrst_n_i)
        gray_waddr <= 'd0 ;
    else 
        gray_waddr <= waddr ^ (waddr >> 1'b1);
end 

always @(posedge rclk_i or negedge rrst_n_i)begin 
    if(~rrst_n_i) begin 
        gray_buf1_w2r <= 'd0;
        gray_buf2_w2r <= 'd0;
    end
    else begin 
        gray_buf1_w2r <= gray_waddr ;
        gray_buf2_w2r <= gray_buf1_w2r ;
    end 
end 
 
always @(posedge rclk_i or negedge rrst_n_i)begin:W2R//gray to binary 
    integer i ;
    if(~rrst_n_i)
        waddr_sync <= 'd0 ;
    else begin 
        for(i=0;i<=WIDTH;i=i+1)
            waddr_sync[i] <= ^(gray_buf2_w2r>>i);
    end 
end 

//read to write 
reg [ADDR_WID:0] gray_raddr,gray_buf1_r2w,gray_buf2_r2w ;
always @(posedge rclk_i or negedge rrst_n_i)begin //binary 2 gray for raddr 
    if(~rrst_n_i)
        gray_raddr <= 'd0 ;
    else 
        gray_raddr <= raddr ^ (raddr >> 1'b1);
end 

always @(posedge wclk_i or negedge wrst_n_i)begin 
    if(~wrst_n_i) begin 
        gray_buf1_r2w <= 'd0;
        gray_buf2_r2w <= 'd0;
    end
    else begin 
        gray_buf1_r2w <= gray_raddr ;
        gray_buf2_r2w <= gray_buf1_r2w ;
    end 
end 
    
always @(posedge wclk_i or negedge wrst_n_i)begin:R2W//gray to binary 
    integer i ;
    if(~wrst_n_i)
        raddr_sync <= 'd0 ;
    else begin 
        for(i=0;i<=WIDTH;i=i+1)
            raddr_sync[i] <= ^(gray_buf2_r2w>>i);
    end 
end 
//============address cross clock domain ===============================/

//inst for dpram
dpram #(    .DEPTH(DEPTH),
            .WIDTH(WIDTH) )
dpram_inst0(
        .wclk        (wclk_i            ),
        .wenc        (wen_ram           ),
        .waddr       (waddr[ADDR_WID-1:0]             ),   
        .raddr       (raddr[ADDR_WID-1:0]             ),   
        .wdata       (wdata_i           ),
        .rclk        (rclk_i            ),
        .renc        (ren_ram           ),
        .rdata       (rdata_o           ) 
        );


endmodule 
