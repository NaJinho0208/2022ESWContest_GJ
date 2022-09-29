/*
	Shift Register: Serial to Parallel(1-96bit)
	input:
		in(1bit): connected with MOSI data
		en : shift enable bit
		iRST: total reset
		clk: clock
	output:
		out: 96bit data
*/

module s2p_register(
	in,
	en,
	iRST,
	clk,
	out);

parameter WL = 96; // s2p register length

input 				in;
input 				en;
input 				iRST;
input 				clk;
output 	[WL-1:0]	out;

reg [WL-1:0] shift_reg;

integer i;

always @(posedge clk, posedge iRST) begin
	if(iRST) shift_reg <= 0;
	else if(en) begin
		for(i=0; i<(WL-1); i = i+1) begin
			shift_reg[i + 1] <= shift_reg[i];
		end
		shift_reg[0] <= in;
	end
end

assign out = shift_reg;

endmodule
