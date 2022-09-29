/*
	Shift Register: Parallel to Serial(16-1bit)
	input:
		in(13bit): connected with FIFO out
		en : shift enable bit
		in_en: input enable bit
		iRST: total reset
		clk: clock
	output:
		out: 1bit data
*/

module p2s_register(
	in,
	en,
	parallel_in,
	iRST,
	clk,
	out);

parameter WL = 13; // input data length

input 	[WL-1:0]	in;
input 				en;
input 				parallel_in;
input 				iRST;
input 				clk;
output 				out;

reg [15:0]	shift_reg; // 16 bit register

integer i;

always @(posedge clk, posedge iRST) begin
	if(iRST) shift_reg <= 16'b0;
	else if(en) begin
		if(parallel_in) begin
			shift_reg <= {in[WL-1], in[WL-1], in[WL-1], in}; // sign extention data put in
		end else begin
			for(i=0; i<15; i = i+1) begin
				shift_reg[i + 1] <= shift_reg[i];
			end
			shift_reg[0] <= 0;
		end
	end
end

assign out = shift_reg[15];

endmodule
