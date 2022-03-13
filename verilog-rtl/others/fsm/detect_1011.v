module detect_1011(
        input           clk_i       ,
        input           rst_n_i     ,
        input           seq_i       ,
        output          out_o        
        );
//mealy,repeat detect 
parameter IDLE  = 4'b0001;
parameter D_1   = 4'b0010;
parameter D_10  = 4'b0100;
parameter D_101 = 4'b1000;

reg [3:0] cstate , nstate ;
always @(posedge clk_i or negedge rst_n_i)begin 
    if(!rst_n_i)
        cstate <= IDLE ;
    else 
        cstate <= nstate ;
end 

always @(*)begin 
    nstate = IDLE ;
    case(cstate)
        IDLE:begin 
            if(seq_i==1'b1)
                nstate = D_1 ;
            else 
                nstate = IDLE ;
        end 
        D_1     :begin
            if(seq_i == 1'b0)
                nstate = D_10   ;
            else 
                nstate = D_1    ;
        end 
        D_10    :begin
            if(seq_i == 1'b1)
                nstate = D_101  ;
            else 
                nstate = IDLE   ;
        end 
        D_101   :begin
            if(seq_i == 1'b1)
                nstate = D_1    ;
            else 
                nstate = IDLE   ;
        end 
    endcase 
end 

assign out_o = cstate[3] && seq_i ;

endmodule 
