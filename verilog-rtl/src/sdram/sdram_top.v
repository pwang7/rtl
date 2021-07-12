module sdram_top(
		//system singles
		input					sclk			,
		input					reset			,
		//SDRAM Interface
		output	wire			sdram_clk		,
		output	wire			sdram_cke		,
		output	wire			sdram_cs_n		,
		output	wire			sdram_ras_n		,
		output	wire			sdram_cas_n		,
		output	wire			sdram_we_n		,
		output	wire [1:0]		sdram_bank		,
		output	reg  [12:0]		sdram_addr		,
		output	wire [1:0]		sdram_dqm		,
		inout	wire [15:0]		sdram_dq		,
		output	wire	 		flag_init_end	,
		//others
		input					wr_trig			,
		input					rd_trig			
);
 
 
//===============================================================
//*************Define parameter and Internal Singles*************
//===============================================================
//仲裁状态机 
localparam        IDLE        =    5'b0_0001        ;
localparam        ARBIT       =    5'b0_0010        ;
localparam        AREF        =    5'b0_0100        ;
localparam		  WRITE		  =	   5'b0_1000		;
localparam		  READ		  =	   5'b1_0000		;
 
				
				reg[3:0]			sd_cmd			;//各种命令组合起来
//init_main				
				wire [3:0]			init_cmd		;
				wire [12:0]			init_addr		;
//状态机状态
				reg  [4:0]           state          ;
//refresh module
				wire                 ref_req        ;
				wire                 flag_ref_end   ;
				reg                  ref_en         ;//仲裁
				wire [3:0]           ref_cmd        ;
				wire [12:0]          ref_addr       ;
//write module
				reg					 wr_en			;
				wire				 wr_req	        ;
				wire				 flag_wr_end    ;                                
				wire[3:0]			 wr_cmd         ;
				wire[12:0]			 wr_addr        ;
				wire[1:0]			 wr_bank_addr	;	
				wire[15:0]			 wr_data		;
//read module	
				reg					 rd_en			;
				wire				 rd_req			;
				wire				 flag_rd_end	;
//				wire				 ref_req		;	//已经有了刷新命令			
//				wire				 rd_trig		;
				wire[3:0]			 rd_cmd			;
				wire[12:0]			 rd_addr		;
				wire[1:0]			 rd_bank_addr	;
 
					
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                state    <=    IDLE;
                
        else case(state)
                IDLE:
                        if(flag_init_end == 1'b1)
                            state <= ARBIT;
                        else
                            state <= IDLE;
                ARBIT://仲裁
                        if(ref_en == 1'b1)
                            state <= AREF;
						else if(wr_en == 1)//写优于读模块
							state <= WRITE;
						else if(rd_en == 1)
							state <= READ;
						else        
                            state <= ARBIT;			
                AREF:
                        if(flag_ref_end == 1'b1)
                            state <= ARBIT;
                        else 
                            state    <=AREF;
				WRITE:
						if(flag_wr_end == 1'b1)
                            state <= ARBIT;
                        else 
                            state    <=WRITE;	
				READ:
						if(flag_rd_end == 1'b1)
                            state <= ARBIT;
                        else 
                            state    <=READ;		
                default: 
                            state <= IDLE;
        endcase
end
 
 
//ref_en
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                ref_en <= 1'b0;
        else if(state == ARBIT && ref_req == 1'b1)
                ref_en <= 1'b1;
        else        
                ref_en <= 1'b0;
end				
//wr_en
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                wr_en <= 1'b0;
        else if(state == ARBIT && ref_req == 1'b0 && wr_req == 1)
                wr_en <= 1'b1;
        else        
                wr_en <= 1'b0;
end				
 
//rd_en
always @(posedge sclk or negedge reset) begin
        if(reset == 1'b0)
                rd_en <= 1'b0;
        else if(state == ARBIT && ref_req == 0 && wr_req == 0 && rd_req == 1)
                rd_en <= 1'b1;
        else        
                rd_en <= 1'b0;
end	
					
//===============================================================
//****************    Main Code    ***********
//===============================================================	
//目前只有刷新和写才有的状态
always@(*)begin
		case(state)
				IDLE:begin
					sd_cmd		<=	init_cmd;
					sdram_addr	<=	init_addr;
				end
				AREF:begin
					sd_cmd		<=	ref_cmd;
					sdram_addr	<=	ref_addr;
				end
				WRITE:begin
					sd_cmd		<=	wr_cmd;
					sdram_addr	<=	wr_addr;
				end
				READ:begin
					sd_cmd		<=	rd_cmd;
					sdram_addr	<=	rd_addr;
				end
				default:begin
					sd_cmd		<=	4'b0111;//nop
					sdram_addr	<=	0;
				end
		endcase
end
 
 
assign	sdram_cke	=	1'b1;
//assign  sdram_addr  =    (state == IDLE)    ?    init_addr    :    ref_addr;
//assign	{sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n}	=	(state == IDLE)    ?    init_cmd    :    ref_cmd;
assign	{sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n}	=	sd_cmd;
assign	sdram_dqm	=	2'b00;
assign  sdram_clk	=    ~sclk;//方便sdram采样
assign	sdram_dq	=	(state == WRITE)? wr_data : {16{1'bz}};
assign	sdram_bank  =	(state == WRITE)? wr_bank_addr : rd_bank_addr;
 
sdram_init sdram_init_inst(
		//system singles
		.sclk					(sclk			),
		.reset					(reset			),
		//others
		.cmd_reg				(init_cmd		),
		.sdram_addr				(init_addr		),
		.flag_init_end			(flag_init_end	)
 
);
 
sdram_aref       sdram_aref_inst(
        //system signals
        .sclk                   (sclk           ),
        .reset            	    (reset          ),
        //comunicat with ARBIT
        .ref_en                 (ref_en         ),
        .ref_req                (ref_req        ),
        .flag_ref_end           (flag_ref_end   ),
        //others        
        .aref_cmd               (ref_cmd        ),
        .sdram_addr             (ref_addr       ),
        .flag_init_end          (flag_init_end  )
);
 
sdram_write sdram_write_inst(
		//system single
		.sclk					(sclk			),	
		.reset					(reset			),
		.wr_en					(wr_en			),//现有请求在使能
		.wr_req					(wr_req			),		
		.flag_wr_end			(flag_wr_end	),	
		.ref_req				(ref_req		),//刷新请求信号
		.wr_trig				(wr_trig		),//写触发
		.wr_cmd					(wr_cmd			),
		.wr_addr				(wr_addr		),
		.bank_addr				(wr_bank_addr	),
		.wr_data				(wr_data		)
		
);
sdram_read sdram_read_inst(
		//system single
		.sclk					(sclk			),	
		.reset					(reset			),
		.rd_en					(rd_en			),//现有请求在使能
		.rd_req					(rd_req			),		
		.flag_rd_end			(flag_rd_end	),	
		.ref_req				(ref_req		),//刷新请求信号
		.rd_trig				(rd_trig		),//写触发
		.rd_cmd					(rd_cmd			),
		.rd_addr				(rd_addr		),
		.bank_addr				(rd_bank_addr	)
);
 
 
 
 
endmodule
