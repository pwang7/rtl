module apb_arbiter #(
    parameter AW = 32,
    parameter PROT_W = 3,
    parameter PSTRB_W = 4,
    parameter DW = 32
)(
    input wire               preset_n,
    input wire               pclk,

    input wire               a0_pwrite,
    input wire               a0_psel,
    input wire               a0_penable,
    input wire [PROT_W-1:0]  a0_pprot,
    input wire [AW-1:0]      a0_paddr,
    input wire [DW-1:0]      a0_pwdata,
    input wire [PSTRB_W-1:0] a0_pstrb,
    output reg               a0_pready,
    output reg               a0_pslverr,
    output reg [DW-1:0]      a0_prdata,

    input wire               a1_pwrite,
    input wire               a1_psel,
    input wire               a1_penable,
    input wire [PROT_W-1:0]  a1_pprot,
    input wire [AW-1:0]      a1_paddr,
    input wire [DW-1:0]      a1_pwdata,
    input wire [PSTRB_W-1:0] a1_pstrb,
    output reg               a1_pready,
    output reg               a1_pslverr,
    output reg [DW-1:0]      a1_prdata,

    input wire               a2_pwrite,
    input wire               a2_psel,
    input wire               a2_penable,
    input wire [PROT_W-1:0]  a2_pprot,
    input wire [AW-1:0]      a2_paddr,
    input wire [DW-1:0]      a2_pwdata,
    input wire [PSTRB_W-1:0] a2_pstrb,
    output reg               a2_pready,
    output reg               a2_pslverr,
    output reg [DW-1:0]      a2_prdata,

    input wire               a3_pwrite,
    input wire               a3_psel,
    input wire               a3_penable,
    input wire [PROT_W-1:0]  a3_pprot,
    input wire [AW-1:0]      a3_paddr,
    input wire [DW-1:0]      a3_pwdata,
    input wire [PSTRB_W-1:0] a3_pstrb,
    output reg               a3_pready,
    output reg               a3_pslverr,
    output reg [DW-1:0]      a3_prdata,

    output reg               b_pwrite,
    output reg               b_psel,
    output reg               b_penable,
    output reg [PROT_W-1:0]  b_pprot,
    output reg [AW-1:0]      b_paddr,
    output reg [DW-1:0]      b_pwdata,
    output reg [PSTRB_W-1:0] b_pstrb,
    input wire               b_pready,
    input wire               b_pslverr,
    input wire [DW-1:0]      b_prdata
);

localparam IDLE = 'h0,
           A0_APB_REQ_ST = 'h1,
           A1_APB_REQ_ST = 'h2,
           A2_APB_REQ_ST = 'h4,
           A3_APB_REQ_ST = 'h8;

reg [3:0] cur_st, nxt_st;
reg a_apb_req_end_pos,
    a0_apb_req,
    a1_apb_req,
    a2_apb_req,
    a3_apb_req;

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        cur_st <= #1 IDLE;
    else
        cur_st <= #1 nxt_st;
end

always @(*) begin
    case (cur_st)
        IDLE: begin
            if (a0_apb_req == 'b1)
                nxt_st = A0_APB_REQ_ST;
            else if (a1_apb_req == 'b1)
                nxt_st = A1_APB_REQ_ST;
            else if (a2_apb_req == 'b1)
                nxt_st = A2_APB_REQ_ST;
            else if (a3_apb_req == 'b1)
                nxt_st = A3_APB_REQ_ST;
            else
                nxt_st = IDLE;
        end
        A0_APB_REQ_ST: begin
            if (a0_apb_req == 'b1)
                nxt_st = A0_APB_REQ_ST;
            else if (a1_apb_req == 'b1)
                nxt_st = A1_APB_REQ_ST;
            else if (a2_apb_req == 'b1)
                nxt_st = A2_APB_REQ_ST;
            else if (a3_apb_req == 'b1)
                nxt_st = A3_APB_REQ_ST;
            else
                nxt_st = IDLE;
        end
        A1_APB_REQ_ST: begin
            if (a1_apb_req == 'b1)
                nxt_st = A1_APB_REQ_ST;
            else if (a2_apb_req == 'b1)
                nxt_st = A2_APB_REQ_ST;
            else if (a3_apb_req == 'b1)
                nxt_st = A3_APB_REQ_ST;
            else if (a0_apb_req == 'b1)
                nxt_st = A0_APB_REQ_ST;
            else 
                nxt_st = IDLE;
        end
        A2_APB_REQ_ST: begin
            if (a2_apb_req == 'b1)
                nxt_st = A2_APB_REQ_ST;
            else if (a3_apb_req == 'b1)
                nxt_st = A3_APB_REQ_ST;
            else if (a0_apb_req == 'b1)
                nxt_st = A0_APB_REQ_ST;
            else if (a1_apb_req == 'b1)
                nxt_st = A1_APB_REQ_ST;
            else 
                nxt_st = IDLE;
        end
        A3_APB_REQ_ST: begin
            if (a3_apb_req == 'b1)
                nxt_st = A3_APB_REQ_ST;
            else if (a0_apb_req == 'b1)
                nxt_st = A0_APB_REQ_ST;
            else if (a1_apb_req == 'b1)
                nxt_st = A1_APB_REQ_ST;
            else if (a2_apb_req == 'b1)
                nxt_st = A2_APB_REQ_ST;
            else 
                nxt_st = IDLE;
        end
    endcase
end

always @(*) begin
    a_apb_req_end_pos = b_pready == 'b1 && b_psel == 'b1 && b_penable == 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a0_apb_req <= #1 'b0;
    else if (cur_st == A0_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a0_apb_req <= #1 'b0;
    else if (a0_psel == 'b1 && a0_penable == 'b0)
        a0_apb_req <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a1_apb_req <= #1 'b0;
    else if (cur_st == A1_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a1_apb_req <= #1 'b0;
    else if (a1_psel == 'b1 && a1_penable == 'b0)
        a1_apb_req <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a2_apb_req <= #1 'b0;
    else if (cur_st == A2_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a2_apb_req <= #1 'b0;
    else if (a2_psel == 'b1 && a2_penable == 'b0)
        a2_apb_req <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a3_apb_req <= #1 'b0;
    else if (cur_st == A3_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a3_apb_req <= #1 'b0;
    else if (a3_psel == 'b1 && a3_penable == 'b0)
        a3_apb_req <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        b_psel <= #1 'b0;
    else begin
        case (nxt_st)
            IDLE: begin
                b_psel <= #1 'b0;
            end
            A0_APB_REQ_ST: begin
                if (a_apb_req_end_pos == 'b1)
                    b_psel <= #1 'b0;
                else
                    b_psel <= #1 'b1;
            end
            A1_APB_REQ_ST: begin
                if (a_apb_req_end_pos == 'b1)
                    b_psel <= #1 'b0;
                else
                    b_psel <= #1 'b1;
            end
            A2_APB_REQ_ST: begin
                if (a_apb_req_end_pos == 'b1)
                    b_psel <= #1 'b0;
                else
                    b_psel <= #1 'b1;
            end
            A3_APB_REQ_ST: begin
                if (a_apb_req_end_pos == 'b1)
                    b_psel <= #1 'b0;
                else
                    b_psel <= #1 'b1;
            end
        endcase
    end
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        b_penable <= #1 'b0;
    else if (a_apb_req_end_pos == 'b1)
        b_penable <= #1 'b0;
    else if (b_psel == 'b1)
        b_penable <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        b_paddr <= #1 'b0;
    else begin
        case (nxt_st)
            A0_APB_REQ_ST: b_paddr <= #1 a0_paddr;
            A1_APB_REQ_ST: b_paddr <= #1 a1_paddr;
            A2_APB_REQ_ST: b_paddr <= #1 a2_paddr;
            A3_APB_REQ_ST: b_paddr <= #1 a3_paddr;
        endcase
    end  
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        b_pwdata <= #1 'b0;
    else begin
        case (nxt_st)
            A0_APB_REQ_ST: b_pwdata <= #1 a0_pwdata;
            A1_APB_REQ_ST: b_pwdata <= #1 a1_pwdata;
            A2_APB_REQ_ST: b_pwdata <= #1 a2_pwdata;
            A3_APB_REQ_ST: b_pwdata <= #1 a3_pwdata;
        endcase
    end  
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        b_pstrb <= #1 'b0;
    else begin
        case (nxt_st)
            A0_APB_REQ_ST: b_pstrb <= #1 a0_pstrb;
            A1_APB_REQ_ST: b_pstrb <= #1 a1_pstrb;
            A2_APB_REQ_ST: b_pstrb <= #1 a2_pstrb;
            A3_APB_REQ_ST: b_pstrb <= #1 a3_pstrb;
        endcase
    end  
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a0_pready <= #1 'b1;
    else if (a0_psel == 'b1 && a0_penable == 'b0)
        a0_pready <= #1 'b0;
    else if (cur_st == A0_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a0_pready <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a0_pslverr <= #1 'b0;
    else if (cur_st == A0_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a0_pslverr <= #1 b_pslverr;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a0_prdata <= #1 'b0;
    else if (cur_st == A0_APB_REQ_ST && a_apb_req_end_pos == 'b1 && b_pwrite == 'b0)
        a0_prdata <= #1 b_prdata;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a1_pready <= #1 'b1;
    else if (a1_psel == 'b1 && a1_penable == 'b0)
        a1_pready <= #1 'b0;
    else if (cur_st == A1_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a1_pready <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a1_pslverr <= #1 'b1;
    else if (cur_st == A1_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a1_pslverr <= #1 b_pslverr;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a1_prdata <= #1 'b0;
    else if (cur_st == A1_APB_REQ_ST && a_apb_req_end_pos == 'b1 && b_pwrite == 'b0)
        a1_prdata <= #1 b_prdata;
end


always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a2_pready <= #1 'b1;
    else if (a2_psel == 'b1 && a2_penable == 'b0)
        a2_pready <= #1 'b0;
    else if (cur_st == A2_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a2_pready <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a2_pslverr <= #1 'b0;
    else if (cur_st == A2_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a2_pslverr <= #1 b_pslverr;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a2_prdata <= #1 'b0;
    else if (cur_st == A2_APB_REQ_ST && a_apb_req_end_pos == 'b1 && b_pwrite == 'b0)
        a2_prdata <= #1 b_prdata;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a3_pready <= #1 'b1;
    else if (a3_psel == 'b1 && a3_penable == 'b0)
        a3_pready <= #1 'b0;
    else if (cur_st == A3_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a3_pready <= #1 'b1;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a3_pslverr <= #1 'b1;
    else if (cur_st == A3_APB_REQ_ST && a_apb_req_end_pos == 'b1)
        a3_pslverr <= #1 b_pslverr;
end

always @(posedge pclk or negedge preset_n) begin
    if (preset_n == 'b0)
        a3_prdata <= #1 'b0;
    else if (cur_st == A3_APB_REQ_ST && a_apb_req_end_pos == 'b1 && b_pwrite == 'b0)
        a3_prdata <= #1 b_prdata;
end
endmodule
