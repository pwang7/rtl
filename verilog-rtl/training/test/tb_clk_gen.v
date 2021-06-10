`timescale 1ns / 1ps

module tb_clk_gen();
    reg clk;
    //--------------------//
    // Clock generation
    initial clk = 0;


    initial begin
        $monitor("clk time %d %b", $time, clk);
        #500 $finish;
    end

    //--------------------//
    // Nonsense delay
    reg a, b, c, d, e, f;
    always @ (posedge clk) begin #5  a <= b & c; #10  d <= e & f; end
    always @ (posedge clk) begin #5; a <= b & c; #10; d <= e & f; end
    always @ (b, c, e, f)  begin #5  a  = b & c; #10  d  = e & f; end
    always @ (b, c, e, f)  begin #5; a  = b & c; #10; d  = e & f; end

    always @ (b, c, e, f)  begin a  = #5 b & c; d = #10 e & f; end
    reg a_tmp, d_tmp;
    always @ (b, c, e, f)  begin
        a_tmp = b & c;
        #5;
        a = a_tmp;

        d_tmp = e & f;
        #5;
        d = d_tmp;
    end

    //--------------------//
    // Transport delay
    always @ (posedge clk) begin a <= #5 b & c; d <= #10 e & f; end
    // a_rhs = b & c; then put "a=a_rhs after 5ns" into non-blocking assignment queue
    // d_rhs = e & f; then put "d=d_rhs after 10ns" into non-blocking assignment queue

    //--------------------//
    // Inertial delay
    wire x;
    reg y, z;
    initial begin
        y = 1;
        z = 0;
        #1 z = 1; // @1ns -> @6ns x = 1;
        #2 z = 0; // @3ns -> @8ns x = 0;
        #3 z = 1; // @6ns -> @11ns x = 1;
        #4 z = 0; // @10ns -> @15ns x = 0;
        #5 z = 1; // @15ns -> @20ns x = 1;
        #6 z = 0; // @21ns -> @26ns x = 0;
        #7 z = 1; // @28ns -> @33ns x = 1;
        // #6 $finish; // @34ns
    end
    assign #5 x = y & z;
endmodule

/*
module tb;
wire p;
reg q;
assign p = q;
initial begin
    q = 1;
    #10 q = 0;
    $display("p = %b", p);
end

//--------------------//

reg a, b, clk, rst_n;
wire q2;
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end
skblk1 u1(.q2(q2), .a(a), .b(b), .clk(clk), .rst_n(rst_n));
initial begin
    a = 0;
    b = 0;
    rst_n <= 0;
    @(posedge clk);
    @(negedge clk) rst_n = 1;
    a = 1;
    b = 1;
    @(negedge clk) a = 0;
    @(negedge clk) b = 0;
    @(negedge clk) $finish;
end

endmodule

module skblk1(
    output reg q2,
    input a, b, clk, rst_n
    );

    reg q1, d1, d2;

    always @ (a or b or q1) begin
        d1 = a & b;
        d2 = d1 | q1;
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= 0;
            q2 <= 0;
        end
        else begin
            q1 <= d1;
            q2 <= d2;
        end
    end
endmodule
*/