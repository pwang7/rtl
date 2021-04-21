module apb_bridge #(
    parameter AW = 32,
    parameter PROT_W = 3,
    parameter PSTRB_W = 4,
    parameter DW = 32
)(
    input wire               a_preset_n,
    input wire               a_pclk,
    input wire               a_pwrite,
    input wire               a_psel,
    input wire               a_penable,
    input wire [PROT_W-1:0]  a_pprot,
    input wire [AW-1:0]      a_paddr,
    input wire [DW-1:0]      a_pwdata,
    input wire [PSTRB_W-1:0] a_pstrb,
    output reg               a_pready,
    output reg               a_pslverr,
    output reg [DW-1:0]      a_prdata,

    input wire               b_preset_n,
    input wire               b_pclk,
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

reg a_apb_req;
reg a2b_apb_req_dff1, a2b_apb_req_dff2, a2b_apb_req_dff3;
reg a2b_apb_req_edge, a2b_apb_req_edge_dff;

reg b_pready_req;
reg b2a_pready_req_dff1, b2a_pready_req_dff2, b2a_pready_req_dff3;
reg b2a_pready_req_edge;

always @(posedge a_pclk or negedge a_preset_n) begin
    if (a_preset_n == 'b0)
        a_apb_req <= #1 'b0;
    else if (a_psel == 'b1 && a_penable == 'b0)
        a_apb_req <= #1 ~a_apb_req;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0) begin
        a2b_apb_req_dff1 <= #1 'b0;
        a2b_apb_req_dff2 <= #1 'b0;
        a2b_apb_req_dff3 <= #1 'b0;
    end
    else begin
        a2b_apb_req_dff1 <= #1 a_apb_req;
        a2b_apb_req_dff2 <= #1 a2b_apb_req_dff1;
        a2b_apb_req_dff3 <= #1 a2b_apb_req_dff2;
    end
end

always @(*) begin
    a2b_apb_req_edge = a2b_apb_req_dff3 ^ a2b_apb_req_dff2;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_psel <= #1 'b0;
    else if (b_pready == 'b1 && b_psel == 'b1 && b_penable == 'b1)
        b_psel <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        b_psel <= #1 'b1;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_pwrite <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        b_pwrite <= #1 a_pwrite;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_pprot <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        b_pprot <= #1 a_pprot;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_paddr <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        b_paddr <= #1 a_paddr;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_pwdata <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        b_pwdata <= #1 a_pwdata;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_pstrb <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        b_pstrb <= #1 a_pstrb;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        a2b_apb_req_edge_dff <= #1 'b0;
    else if (a2b_apb_req_edge == 'b1)
        a2b_apb_req_edge_dff <= #1 a2b_apb_req_edge;
end


always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_penable <= #1 'b0;
    else if (b_pready == 'b1 && b_psel == 'b1 && b_penable == 'b1)
        b_penable <= #1 'b0;
    else if (a2b_apb_req_edge_dff == 'b1)
        b_penable <= #1 'b1;
end

always @(posedge b_pclk or negedge b_preset_n) begin
    if (b_preset_n == 'b0)
        b_pready_req <= #1 'b0;
    else if (b_psel == 'b1 && b_penable == 'b1 && b_pready == 'b1)
        b_pready_req <= #1 ~b_pready_req;
    
end

always @(posedge a_pclk or negedge a_preset_n) begin
    if (a_preset_n == 'b0) begin
        b2a_pready_req_dff1 <= #1 'b0;
        b2a_pready_req_dff2 <= #1 'b0;
        b2a_pready_req_dff3 <= #1 'b0;
    end
    else begin
        b2a_pready_req_dff1 <= #1 b_pready_req;
        b2a_pready_req_dff2 <= #1 b2a_pready_req_dff1;
        b2a_pready_req_dff3 <= #1 b2a_pready_req_dff2;
    end
end

always @(*) begin
    b2a_pready_req_edge = b2a_pready_req_dff3 ^ b2a_pready_req_dff2;
end

always @(posedge a_pclk or negedge a_preset_n) begin
    if (a_preset_n == 'b0)
        a_pready <= #1 'b1;
    else if (a_psel == 'b1 && a_penable == 'b0)
        a_pready <= #1 'b0;
    else if (b2a_pready_req_edge == 'b1)
        a_pready <= #1 'b1;
end
endmodule