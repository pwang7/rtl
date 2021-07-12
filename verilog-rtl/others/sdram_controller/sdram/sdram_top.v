module sdram_top (
    input sclk,
    input s_rst_n,
    output sdram_clk,
    output sdram_cke,
    output sdram_cs_n,
    output sdram_cas_n,
    output sdram_ras_n,
    output sdram_we_n,
    output [1:0] sdram_bank,
    output reg [11:0] sdram_addr,
    output [1:0] sdram_dqm,
    inout [15:0] sdram_dq,
    input wr_trig,
    input rd_trig
);

localparam IDLE = 5'b00001;
localparam ARBIT = 5'b00010;
localparam AREF = 5'b00100;
localparam WRITE = 5'b01000;
localparam READ = 5'b10000;

reg [3:0] sd_cmd;

wire flag_init_end;
wire [3:0] init_cmd;
wire [11:0] init_addr;

reg [4:0] state;

wire ref_req;
wire flag_ref_end;
reg ref_en;
wire [3:0] ref_cmd;
wire [11:0] ref_addr;

reg wr_en;
wire wr_req;
wire flag_wr_end;
wire [3:0] wr_cmd;
wire [11:0] wr_addr;
wire [1:0] wr_bank_addr;
wire [15:0] wr_data;

reg rd_en;
wire rd_req;
wire flag_rd_end;
wire [3:0] rd_cmd;
wire [11:0] rd_addr;
wire [1:0] rd_bank_addr;
//wire [15:0] rd_data;

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        state <= IDLE;
    else case (state)
        IDLE: 
            if (flag_init_end)
                state <= ARBIT;
            else
                state <= IDLE;
        ARBIT:
            if (ref_en)
                state <= AREF;
            else if (wr_en)
                state <= WRITE;
            else if (rd_en)
                state <= READ;
            else
                state <= ARBIT;
        AREF:
            if (flag_ref_end)
                state <= ARBIT;
            else
                state <= AREF;
        WRITE:
            if (flag_wr_end)
                state <= WRITE;
        READ:
            if (flag_rd_end)
                state <= ARBIT;
            else
                state <= READ;
        default:
            state <= IDLE;
    endcase
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        ref_en <= 'b0;
    else if (state == ARBIT && ref_req)
        ref_en <= 'b1;
    else
        ref_en <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        wr_en <= 'b0;
    else if (state == ARBIT && !ref_req && wr_req)
        wr_en <= 'b1;
    else
        wr_en <= 'b0;
end

always @(posedge sclk or negedge s_rst_n) begin
    if (!s_rst_n)
        rd_en <= 'b0;
    else if (state == ARBIT && !ref_req && !wr_req && rd_req)
        rd_en <= 'b1;
    else
        rd_en <= 'b0;
end

assign sdram_cke = 'b1;
//assign sdram_addr = (state == IDLE) ? init_addr : ref_addr;
//assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = (state == IDLE) ? init_cmd : ref_cmd;
assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = sd_cmd;
assign sdram_dqm = 2'b00;
assign sdram_clk = ~sclk;
assign sdram_dq = (state == WRITE) ? wr_data : 16'bZ;
assign sdram_bank = (state == WRITE) ? wr_bank_addr : rd_bank_addr;

always @(*) begin
    case (state)
        IDLE: begin
            sd_cmd <= init_cmd;
            sdram_addr <= init_addr;
        end
        AREF: begin
            sd_cmd <= ref_cmd;
            sdram_addr <= ref_addr;
        end
        WRITE: begin
            sd_cmd <= wr_cmd;
            sdram_addr <= wr_addr;
        end
        READ: begin
            sd_cmd <= rd_cmd;
            sdram_addr <= rd_addr;
        end
        default: begin
            sd_cmd <= 4'b0111; // NOP
            sdram_addr <= 'b0;
        end
    endcase
end

sdram_init sdram_init_inst(
    .sclk(sclk),
    .s_rst_n(s_rst_n),
    .cmd_reg(init_cmd),
    .sdram_addr(init_addr),
    .flag_init_end(flag_init_end)
);

sdram_aref u_sdram_aref(
    .sclk          (sclk          ),
    .s_rst_n       (s_rst_n       ),
    .ref_en        (ref_en        ),
    .flag_init_end (flag_init_end ),
    .ref_req       (ref_req       ),
    .flag_ref_end  (flag_ref_end  ),
    .aref_cmd      (ref_cmd      ),
    .sdram_addr    (ref_addr    )
);

sdram_write u_sdram_write(
    .sclk        (sclk        ),
    .s_rst_n     (s_rst_n     ),
    .wr_en       (wr_en       ),
    .wr_req      (wr_req      ),
    .flag_wr_end (flag_wr_end ),
    .ref_req     (ref_req     ),
    .wr_trig     (wr_trig     ),
    .wr_cmd      (wr_cmd      ),
    .wr_addr     (wr_addr     ),
    .bank_addr   (wr_bank_addr),
    .wr_data     (wr_data     )
);

sdram_read u_sdram_read(
    .sclk        (sclk        ),
    .s_rst_n     (s_rst_n     ),
    .rd_en       (rd_en       ),
    .rd_req      (rd_req      ),
    .flag_rd_end (flag_rd_end ),
    .ref_req     (ref_req     ),
    .rd_trig     (rd_trig     ),
    .rd_cmd      (rd_cmd      ),
    .rd_addr     (rd_addr     ),
    .bank_addr   (rd_bank_addr   )
);

endmodule