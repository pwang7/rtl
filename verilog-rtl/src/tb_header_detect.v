`timescale 1ns / 10ps

module tb_header_detect();

localparam CYCLE = 4;
localparam RST_TIME = 3;

reg clk;
reg rst_n;
reg [7:0] din;

integer fd;
reg result;

initial begin
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars;
end

header_detect u_header_detect(
  .clk(clk),
  .rst_n(rst_n),
  .din(din)
);

initial begin
  clk = 0;
  forever
  #(CYCLE/2)
  clk=~clk;
end

initial begin
  rst_n = 1;
  #2;
  rst_n = 0;
  #(CYCLE*RST_TIME);
  rst_n = 1;
end

initial begin
  fd = $fopen("tb_header_detect.log", "w");
  #1;
  din = 0;
  #(10*CYCLE);
  repeat(5) begin
    din = 8'h55;
    #CYCLE;
    din = 8'hd5;
    #CYCLE;
  end
  #(2*CYCLE);
  repeat(2) begin
    din = 8'h55;
    #CYCLE;
    din = 8'hd5;
    #CYCLE;
  end
  #(2*CYCLE);
  repeat(3) begin
    din = 8'h56;
    #CYCLE;
    din = 8'hd6;
    #CYCLE;
  end
  #(2*CYCLE);
  repeat(5) begin
    din = 8'h55;
    #CYCLE;
    din = 8'hd5;
    #CYCLE;
  end
  #(2*CYCLE);
  
  if (result) begin
    $fdisplay(fd, "%m Test: SUCCESS, at %0d ns", $time);
    //$finish_and_return(1);
    //$error("some error");
    //$fatal(1);
  end
  else begin
    $fdisplay(fd, "%m Test: FAIL, at %0d ns", $time);
    //$stop(2);
  end
  $fclose(fd);
  //$stop(2);
  $finish;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    result = 1'b0;
  else if (u_header_detect.cnt1 == 5 - 1)
    result = 1'b1;
end

endmodule

