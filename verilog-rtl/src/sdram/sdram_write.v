module sdram_write(
		//system single
		input				sclk,	
		input				reset,
		//commucation with top
		input				wr_en,//现有请求在使能
		output	wire		wr_req,		
		output	reg			flag_wr_end,	
		//others
		input				ref_req,//刷新请求信号
		input				wr_trig,//写触发
		//write interface
		output	reg[3:0]	wr_cmd,
		output	reg[12:0]	wr_addr,
		output	wire[1:0]	bank_addr,
		output	reg[15:0]	wr_data
		
);

//状态
localparam		S_IDLE			=		5'b0_0001;	
localparam		S_REQ			=		5'b0_0010;	
localparam		S_ACT			=		5'b0_0100;//行激活	
localparam		S_WR			=		5'b0_1000;	
localparam		S_PRE			=		5'b1_0000;	
//SDRAM Comand
localparam		CMD_NOP			=		4'b0111;	
localparam		CMD_PRE			=		4'b0010;	
localparam		CMD_AREF		=		4'b0001;	
localparam		CMD_ACT			=		4'b0011;	
localparam		CMD_WR			=		4'b0100;	
 
reg			flag_wr;//写进行中
reg[4:0]	state;	//5个状态
//*********************************************
reg			flag_act_end;	//4个数据一个act
reg			flag_pre_end;	//写完就激活下一行pre
reg			sd_row_end;		//写一行结束
reg[1:0]	burst_cnt;		//0 1 2 3 
reg[1:0]	burst_cnt_t;	//延迟一拍
reg			wr_data_end;	//两行写完强制结束
//********************************************
reg[3:0]	act_cnt;		//
reg[3:0]	break_cnt;
reg[7:0]	col_cnt;		//列地址计数
//********************************************
reg[12:0]	row_addr;
wire[8:0]	col_addr;
//flag_wr
always@(posedge sclk or negedge reset)begin
	if(!reset)
		flag_wr	<=	1'b0;
	else if(wr_trig == 1'b1 && flag_wr == 0)
		flag_wr	<=	1'b1;
	else if(wr_data_end == 1'b1)
		flag_wr <= 1'b0;
end
//burst_cnt  突发4计数
always@(posedge sclk or negedge reset)begin
	if(!reset)
		burst_cnt	<=	0;
	else if(state == S_WR)
		burst_cnt	<=	burst_cnt + 1;
	else
		burst_cnt 	<=  0;
end
//burst_cnt_t
always@(posedge sclk or negedge reset) begin
	if (!reset)
		burst_cnt_t <= 0;
	else
		burst_cnt_t	<= burst_cnt;
end
//--------------------STATE-----------------------
always@(posedge sclk or negedge reset)begin
	if(!reset)
		state	<=	S_IDLE;
	else  case(state)
		S_IDLE:
			if(wr_trig == 1)
				state	<=	S_REQ;
			else	
				state	<=	S_IDLE;
		S_REQ:
			if(wr_en == 1)
				state	<=	S_ACT;
			else	
				state	<=	S_REQ;
		S_ACT:
			if(flag_act_end == 1)//一次突发写完为1
				state	<=  S_WR;
			else
				state	<=	S_ACT;
		S_WR://些状态跳到充电
			if(wr_data_end == 1)
				state	<= S_PRE; //写完两行
			else if(ref_req == 1 && burst_cnt_t == 'd2 && flag_wr == 1)
				state	<=	S_PRE;//刷新到这里 准备 跳出，下几个时钟周期又回来
			else if(sd_row_end == 1 && flag_wr == 1)//写完一行
				state	<=	S_PRE;
		S_PRE:
			if(ref_req == 1 && flag_wr == 1)
				state	<=	S_REQ;
			else if(flag_pre_end == 1 && flag_wr == 1)
				state	<=	S_ACT;
			else if(wr_data_end == 1)
				state	<=	S_IDLE;
		default:
				state	<=	S_IDLE;
	endcase
end
//wr_cmd
always@(posedge sclk or negedge reset)begin
	if(!reset)
		wr_cmd	<=	CMD_NOP;
	else case(state)
		S_ACT:
			if(act_cnt == 0)
				wr_cmd	<=	CMD_ACT;
			else
				wr_cmd	<=	CMD_NOP;
		S_WR:
			if(burst_cnt == 0)
				wr_cmd	<=	CMD_WR;
			else	
				wr_cmd	<=	CMD_NOP;
		S_PRE:
			if(break_cnt == 0)
				wr_cmd	<=	CMD_PRE;
			else	
				wr_cmd	<=	CMD_NOP;
		default:	
				wr_cmd	<=	CMD_NOP;
		endcase	
end
 
 
//wr_addr
always@(*)begin//组合逻辑不会延一拍
	 case(state)
		S_ACT:
			if(act_cnt == 0)
				wr_addr	<=	row_addr;
		S_WR:
			wr_addr	<=	{4'b0000,col_addr};		//A10为1，，好像是0
		S_PRE:
			if(break_cnt == 0)
				wr_addr	<=	{13'b0_0100_0000_0000};
	endcase
			
end
	
//---------------------------------------------------
//flag_act_end
always@(posedge sclk or negedge reset)begin
	if(!reset)
		flag_act_end	<=	0;
	else if(act_cnt == 'd3)
		flag_act_end	<=	1;//相当于第4个别的模块调用已经是第五个了
	else	
		flag_act_end	<=	0;
end
//act_cnt
always@(posedge sclk or negedge reset)begin
	if(!reset)
		act_cnt	<=	0;
	else if(state == S_ACT)//激活需要4个周期包括 命令行地址 延迟3 列地址 
		act_cnt	<=	act_cnt + 1;
	else	
		act_cnt	<=	0;
end
 
//flag_pre_end //突发为4 结束
always@(posedge sclk or negedge reset)begin
	if(!reset)
		flag_pre_end	<=	0;
	else if(break_cnt == 'd3)//预充电也需要时间
		flag_pre_end	<=  1;
	else	
		flag_pre_end	<=	0;
end
//
always@(posedge sclk or negedge reset)begin
	if(!reset)
		flag_wr_end	<=	0;
	else if((state == S_PRE && ref_req == 1) 
			|| (state == S_PRE && wr_data_end == 1))//刷新计数
		flag_wr_end	<=  1;
	else	
		flag_wr_end	<=	0;
end
 
//break_cnt  //预充电时间
always@(posedge sclk or negedge reset)begin
	if(!reset)
		break_cnt	<=	0;
	else if(state == S_PRE)						
		break_cnt	<=	break_cnt + 1;
	else	
		break_cnt	<=	0;
end
//wr_data_end
always@(posedge sclk or negedge reset)begin
	if(!reset)	
		wr_data_end	<=	0;
	else if(row_addr == 2 && col_addr == 'd511)//自动累加9位 两行写结束//改为3行
		wr_data_end	<=	1;//	
	else
		wr_data_end	<=	0;
end
//col_cnt
always@(posedge sclk or negedge reset)begin
	if(!reset)	
		col_cnt	<=	0;
	else if(col_addr == 511)
		col_cnt	<=	0;
	else if(burst_cnt_t == 3)
		col_cnt	<=	col_cnt + 1;
end
//row_addr
always@(posedge sclk or negedge reset)begin
	if(!reset)	
		row_addr	<=	0;
	else if(sd_row_end == 1)
		row_addr	<=	row_addr + 1;
 
end
//sd_row_end
 
always@(posedge sclk or negedge reset)begin
	if(!reset)	
		sd_row_end	<=	0;
	else if(col_addr == 509)
		sd_row_end	<=	1;
	else
		sd_row_end	<=	0;
 
end
 
 
//
always@(*)begin
	case(burst_cnt_t)
		0:wr_data	<=	1;
		1:wr_data	<=	2;
		2:wr_data	<=	3;
		3:wr_data	<=	4;
	default: wr_data	<=	0;
	endcase
end
 
 
assign	col_addr	=	{col_cnt,burst_cnt_t};
assign  bank_addr	=	2'b00;//写操作代码 
assign	wr_req		= 	state[1];
 
endmodule
