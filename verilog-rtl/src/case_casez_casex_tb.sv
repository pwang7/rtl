/*
  SystemVerilog Structure and Union Example

  Copyright (C) 2017 Jason Yu (http://www.verilogpro.com)
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  ------------------------------------------------------------------
  -- Revision History
  ------------------------------------------------------------------
  1.0                 Initial release
*/


module case_module
(
  input logic clk,
  input logic rst_n,
  input logic [3:0] arb_in[7:0]
);

  logic [3:0] count;

  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)
      count <= '0;
  	else
      count <= count + 1;

  
  always_comb begin
    //
    // Note an initial printout of count=x, arb_in[count]==4'bxxxx
    // always_comb is executed once at time 0
    //
    
    $display("\n----------------------------------------");
    $display("-- Count = %0d, arb_in[count] = 4'b%4b --", count, arb_in[count]);
    $display("----------------------------------------");
    
    // Case without default
    // Does not match any case expression containing 'z' or 'x'
    case (arb_in[count])
      4'd0: $display("Case                  : case item 0");
      4'd1: $display("Case                  : case item 1");
      4'd2: $display("Case                  : case item 2");
	  endcase

    
    // Case with default
    // Case expressions containing 'z' or 'x' fall through to default case
    case (arb_in[count])
      4'd0: $display("Case w/ default       : case item 0");
      4'd1: $display("Case w/ default       : case item 1");
      4'd2: $display("Case w/ default       : case item 2");
      default: $display("Case w/ default       : default case");
	  endcase

    
    // Casez
    // Matches case expression containing 'z', but not 'x'
    casez (arb_in[count])
      4'd0: $display("Casez                 : case item 0");
      4'd1: $display("Casez                 : case item 1");
      4'd2: $display("Casez                 : case item 2");
    endcase


    // Casez with default
    // Matches case expression containing 'z', case expression containing 'x' fall through to default case
    casez (arb_in[count])
      4'd0: $display("Casez w/ default      : case item 0");
      4'd1: $display("Casez w/ default      : case item 1");
      4'd2: $display("Casez w/ default      : case item 2");
      default: $display("Casez w/ default      : default case");
    endcase
    
    
    // Casex
    // Matches case expression containing 'z' or 'x'
    casex (arb_in[count])
      4'd0: $display("Casex                 : case item 0");
      4'd1: $display("Casex                 : case item 1");
      4'd2: $display("Casex                 : case item 2");
    endcase

    
    // Casex with default
    // Matches case expression containing 'z' or 'x'
    casex (arb_in[count])
      4'd0: $display("Casex w/ default      : case item 0");
      4'd1: $display("Casex w/ default      : case item 1");
      4'd2: $display("Casex w/ default      : case item 2");
      default: $display("Casex w/ default      : default case");
    endcase

    
	  // Unique case without default
    // Does not match case expression containing 'z' or 'x', gives runtime warning if no match
    unique case (arb_in[count])
      4'd0: $display("Unique case           : case item 0");
      4'd1: $display("Unique case           : case item 1");
      4'd2: $display("Unique case           : case item 2");
	  endcase

    
	  // Unique case with default
    // Case expressions containing 'z' or 'x' fall through to default case, no runtime warning
    unique case (arb_in[count])
      4'd0: $display("Unique case w/ default: case item 0");
      4'd1: $display("Unique case w/ default: case item 1");
      4'd2: $display("Unique case w/ default: case item 2");
      default: $display("Unique case w/ default: default case");
	  endcase


	  // Unique casez
    // Matches case expression containing 'z', but not 'x'gives runtime warning if multiple matches or no match
    unique casez (arb_in[count])
      4'd0: $display("Unique casez          : case item 0");
      4'd1: $display("Unique casez          : case item 1");
      4'd2: $display("Unique casez          : case item 2");
	  endcase

    
  	// Unique casex
    // Matches case expression containing 'z' and 'x', gives runtime warning if multiple matches or no match
    unique casex (arb_in[count])
      4'd0: $display("Unique casex          : case item 0");
      4'd1: $display("Unique casex          : case item 1");
      4'd2: $display("Unique casex          : case item 2");
	  endcase


	  // Priority case without default
    // Does not match case expression containing 'z' or 'x', gives runtime warning if no match
    priority case (arb_in[count])
      4'd0: $display("Priority case           : case item 0");
      4'd1: $display("Priority case           : case item 1");
      4'd2: $display("Priority case           : case item 2");
	  endcase

    
	  // Priority case with default
    // Case expressions containing 'z' or 'x' fall through to default case, no runtime warning
    priority case (arb_in[count])
      4'd0: $display("Priority case w/ default: case item 0");
      4'd1: $display("Priority case w/ default: case item 1");
      4'd2: $display("Priority case w/ default: case item 2");
      default: $display("Priority case w/ default: default case");
	  endcase


	  // Priority casez
    // Matches case expression containing 'z', but not 'x'gives runtime warning if multiple matches or no match
    priority casez (arb_in[count])
      4'd0: $display("Priority casez          : case item 0");
      4'd1: $display("Priority casez          : case item 1");
      4'd2: $display("Priority casez          : case item 2");
	  endcase

    
  	// Priority casex
    // Matches case expression containing 'z' and 'x', gives runtime warning if multiple matches or no match
    priority casex (arb_in[count])
      4'd0: $display("Priority casex          : case item 0");
      4'd1: $display("Priority casex          : case item 1");
      4'd2: $display("Priority casex          : case item 2");
	  endcase
  end // always_comb
  
endmodule



module case_tb;
  
  logic clk;
  logic rst_n;
  logic [3:0] arb_in[7:0];
  
  initial begin
    clk = 1'b0;
    forever #10 clk <= ~clk;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    rst_n = 1'b1;

    #130;
    $finish;
  end
  
  initial begin
    for (logic[3:0] i=0; i<4; i++)
      arb_in[i] = i;
      arb_in[4] = 'x;
      arb_in[5] = 'z;
      arb_in[6] = 4'b000x;
      arb_in[7] = 4'b000z;
  end
  
  
  case_module u_case_module (.*);

endmodule