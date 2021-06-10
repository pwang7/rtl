module gray_to_bin(
    gray_in,
    bin_out
    );
parameter WIDTH = 4;

input[WIDTH-1:0] gray_in;
output wire[WIDTH-1:0] bin_out;

// genvar i;
// generate
//     for (i = 0; i < WIDTH; i = i + 1)
//         assign bin_out[i] = ^(gray_in >> i);
// endgenerate

genvar idx;
generate
    assign bin_out[WIDTH-1] = gray_in[WIDTH-1];
    for (idx = WIDTH - 2; idx >= 0; idx = idx -1) begin
        assign bin_out[idx] = bin_out[idx+1] ^ gray_in[idx];
    end
endgenerate

// reg[WIDTH-1:0] binary;
// integer idx;
// always @ (*) begin
//     binary[WIDTH-1] = gray_in[WIDTH-1];
//     for (idx = WIDTH - 2; idx >= 0; idx = idx -1) begin
//         binary[idx] = binary[idx+1] ^ gray_in[idx];
//     end
// end
// assign bin_out = binary;

// always @(*) begin
//     bin_out[3] = gray_in[3];
//     bin_out[2] = gray_in[2]^bin_out[3];
//     bin_out[1] = gray_in[1]^bin_out[2];
//     bin_out[0] = gray_in[0]^bin_out[1];
// end

endmodule