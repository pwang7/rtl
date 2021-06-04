module sdram_init(
		//system singles
		input				sclk			,
		input				reset			,
		//others	
		output	reg	[3:0]	cmd_reg			,//输出
		output	wire[12:0]	sdram_addr		,
		output	wire 		flag_init_end	
 
);
//===============================================================
//*************Define parameter and Internal Singles*************
//===============================================================
 
localparam		DELAY_200US		=	  10000	;
//SDRAM Command
localparam		NOP				=	 4'b0111;
localparam		PRE				=	 4'b0010;
localparam		AREF			=	 4'b0001;
localparam		MSET			=	 4'b0000;
				reg	[13:0]	cnt_200us			;
				wire		flag_200us			;
				reg	[3:0]	cnt_cmd				;
//===============================================================
//****************    Main Code    ***********
//===============================================================				
//cnt_200us
always@(posedge sclk or negedge reset)begin
		if(!reset)
			cnt_200us	<=	'd0;
		else if(flag_200us == 1'b0)
			cnt_200us	<=	cnt_200us +	1'b1;
end
//cnt_cmd
always@(posedge sclk or negedge reset)begin
		if(!reset)
			cnt_cmd	<=	1'd0;
		else if(flag_200us == 1'b1 && flag_init_end == 1'b0)
			cnt_cmd	<=	cnt_cmd +	1'b1;
end
//cmd_reg
always@(posedge sclk or negedge reset)begin
		if(!reset)
			cmd_reg	<=	NOP;		
		else if(flag_200us == 1'b1)
			case(cnt_cmd)
				0:		cmd_reg	<=	PRE;
				1:		cmd_reg	<=	AREF;
				5:		cmd_reg	<=	AREF;
				9:		cmd_reg	<=	MSET;	
				default:cmd_reg	<=	NOP;
			endcase			
end
//sdram_addr
 
assign  flag_init_end	=	(cnt_cmd > 10)? 1'b1 : 1'b0;
assign	sdram_addr		=	(cmd_reg == MSET)?	13'b0_0000_00011_0010 : 13'b0_0100_0000_0000;//代表4突发 3潜伏。。。	
assign	flag_200us		=	(cnt_200us >= DELAY_200US)?	 1'b1 :	1'b0;
 
 
endmodule
