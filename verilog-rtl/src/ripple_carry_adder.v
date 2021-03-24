module half_adder(a,b,sum,carry);
   input a, b;
   output sum, carry;
   assign sum = a ^ b;
   assign carry = a & b;
endmodule


module full_adder(a, b, cin, sum, cout);
   input a, b, cin;
   output sum, cout;
   wire   t1, t2;
   half_adder h(a, b, t1, t2);
   assign cout = t1 & cin;
   assign sum = t1 ^ cin;
   assign cout = t2 | cout;
endmodule // full_adder

module ripple_carry_adder(input1, input2, answer);
   input [31:0] input1, input2;
   output [31:0] answer;
   wire [31:0]   carry;
   full_adder fa(input1[0], input2[0], 1'b0, answer[0], carry[0]);
   genvar i;
   generate
      for(i = 1; i <= 31; i = i + 1)
        begin : my_mabel
           full_adder fb(input1[i], input2[i], carry[i-1], answer[i], carry[i]);
        end
   endgenerate
endmodule
