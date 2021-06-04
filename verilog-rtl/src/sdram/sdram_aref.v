module sdram_aref(
        //system signals
        input                    sclk            ,
        input                    reset           ,
        //comunicat with ARBIT
        input                    ref_en          ,
        output    reg            ref_req         ,
        output    wire           flag_ref_end    ,
        //others
        output    reg     [3:0]    aref_cmd      ,
        output    wire    [12:0]    sdram_addr   ,
        input                    flag_init_end    
);
 
//==============================================================================\
//*********************Define Parameter and Internal Signal ********************
//==============================================================================/
localparam        DELAY_78us        =        390        ;//理论上7.5us即可为了刷新完全，多花点时间
localparam        CMD_AREF        	=        4'b0001    ;
localparam        CMD_NOP           =        4'b0111    ;
localparam        CMD_PRE           =        4'b0010    ;
reg        [3:0]            cmd_cnt                    ;
reg        [8:0]            ref_cnt                    ;
reg                        flag_ref               		;//表示在刷新由top产生的使能信号激活，直到刷新结束才为0
 
//=============================================================================\
//********************** Main Code    ***************************************
//=============================================================================/
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                ref_cnt <= 9'd0;
        else if(ref_cnt >= DELAY_78us)
                ref_cnt <= 9'd0;
        else if(flag_init_end == 1'b1)
                ref_cnt <= ref_cnt +1'b1;
end
 
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                flag_ref <= 1'b0;
        else if(flag_ref_end == 1'b1)
                flag_ref <=    1'b0;
        else if(ref_en == 1'b1)
                flag_ref <= 1'b1;
end
 
always @(posedge sclk or negedge reset ) begin
        if(reset == 1'b0)
                cmd_cnt    <= 4'd0;
        else if(flag_ref == 1'b1)
                cmd_cnt <= cmd_cnt + 1'b1;
        else
                cmd_cnt <= 4'd0;
end 
 
 
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                aref_cmd <= CMD_NOP;
        else if(cmd_cnt == 2)
               aref_cmd <= CMD_AREF; //预充电 改为刷新时不需要预充电电
        else
			aref_cmd <= CMD_NOP;
end
//ref_req
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                ref_req <= 0;
		else if(ref_en == 1)		
				ref_req <= 0;
        else if(ref_cnt >= DELAY_78us)
				 ref_req <= 1;
end
 
assign  flag_ref_end = (cmd_cnt >= 4'd3) ? 1'b1 : 1'b0;
assign    sdram_addr    =    13'b0_0100_0000_0000;

endmodule
