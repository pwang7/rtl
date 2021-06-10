// 实现一
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        y <= 'b0
    end
    else if (vld) begin
        y <= x0 * h7 + x1 * h6 + x2 * h5 + ... + x7 * h0;
    end
end

// 实现二
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
    end
    else if (vld) begin
        m0 <= x0 * h7;
        m1 <= x1 * h6;
        ...
        m7 <= x7 * h0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
    end
    else if (vld_ff0) begin
        n0 <= m0 + m1;
        n1 <= m2 + m3;
        n2 <= m4 + m5;
        n3 <= m6 + m7;
    end 
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
    end
    else if (vld_ff1) begin
        z0 <= n0 + n1;
        z1 <= n2 + n3;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
    end
    else if (vld_ff2) begin
        y <= z0 + z1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vld_ff0 <= 'b0;
        vld_ff1 <= 'b0;
        vld_ff2 <= 'b0;
    end
    else begin
        vld_ff0 <= vld;
        vld_ff1 <= vld_ff0;
        vld_ff2 <= vld_ff1;
        y_vld <= vld_ff2;
    end
end
