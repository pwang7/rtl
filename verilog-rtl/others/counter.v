// http://hdl.huangzzk.info/
// http://neilturley.dev/netlistsvg/
// http://www.clifford.at/yosys/nogit/YosysJS/snapshot/demo02.html

module counter #(
  parameter integer WIDTH = 4
)(
  output wire [WIDTH:0] io_cnt,
  input  wire           clk,
  input  wire           reset
);
  reg [WIDTH:0]   counter;
  assign io_cnt = counter;

  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      counter <= 'h0;
    end else begin
      counter <= counter + 1'b1;
    end
  end
endmodule
