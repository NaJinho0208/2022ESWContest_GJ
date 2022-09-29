/*
	Zero Padding: this module will output zero at zero timing 
	input: 
		rst: asynchronous, negedge - set counting data 0
		clk: clock
        in: input data, 96 bit
		wrfull: start signal, this bit will be 1 when FIFO_IN is full
	output:
		out: output data, 96 bit
		rdreq: set reset 

	12 x 15 data -> 14 x 17 data
	row: 14 to 1 active -> 14 and 1 should push 0
	column: 17
*/

module ZeroPadding_new(
	rst,
	clk,
	in,
	wrfull,
	STATE,
	out,
	rdreq
);

// inside parameter
parameter WL = 96; // line width


// I/O
input 				rst;
input 				clk;
input 	[WL-1:0]	in;
input				wrfull;
input	[6:0]		STATE;	// state of W_CTRL
output	[WL-1:0]	out;
output				rdreq;

// inside counter
wire	[3:0]	row_counter;
wire	[4:0]	col_counter;
wire			row_increment;
wire			col_zero_sig;
wire			row_zero_sig;
wire			is_state1; // 1 if STATE==1

// bitwise or signals 
assign is_state1 = (STATE == 7'd1);
assign row_increment = (col_counter == 5'd17); // enable row counter when column counter is 17

// row: from 14 to 1
COUNTER 
#(.WL(4),.IV(1),.LSB(0),.ECV(14))  // 1 -> 14, row 1 and 14 is 0
row_counter_module(         
    .iCLK	(clk			),   
    .iRST	(wrfull | rst	),              
    .iEN	(row_increment	),
    .iCLR	(1'b0			),
    .oCNT	(row_counter	)	
);

// column: from 16 to 0
COUNTER 
#(.WL(5),.IV(1),.LSB(0),.ECV(17))  // 1 -> 17, column 1 and 17 is 0
col_counter_module(         
    .iCLK	(clk			),   
    .iRST	(wrfull	| rst	),              
    .iEN	(is_state1		),
    .iCLR	(1'b0			),
    .oCNT	(col_counter	)	
);

// column zero signal: zero if 00001 or 10001
assign col_zero_sig = ((col_counter == 5'd1) | (col_counter == 5'd17)) ? 1'b0 : 1'b1; 
// column zero signal: zero if 0001 or 1110
assign row_zero_sig = ((row_counter == 4'd1) | (row_counter == 4'd14)) ? 1'b0 : 1'b1;
// total mux control bit = rdreg of FIFO : zero: 96'b0, one: FIFO data
assign rdreq = (col_zero_sig & row_zero_sig) | ((row_counter == 4'd1) & (col_counter == 5'd2)) | wrfull;

// output assign
assign out = rdreq ? in : 96'b0;

endmodule