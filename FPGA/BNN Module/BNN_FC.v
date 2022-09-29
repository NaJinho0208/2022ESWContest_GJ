`timescale 1 ns / 100 ps

module BNN_FC(
	iCLK,
	iRST,
	iCLR,
	iDATA,
	iWEIGHT,
	iEN,
	oDATA
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter IL = 48;
parameter OL = 13;

//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input 				iCLK;
input 				iRST;
input 				iCLR;
input	[IL-1:0] 	iDATA;
input 	[IL-1:0]	iWEIGHT;
input 				iEN;

output 	[OL-1:0]	oDATA;


//==========================================================================================//
//	Internal Signal
//==========================================================================================//
wire 		[IL-1:0]	XNOR;
wire 		[5:0] 		XNOR_SUM; 		// 0 ~ 48 : 6-bit
wire signed	[6:0]		XNOR_POP;		// -48 ~ +48 : 7-bit

reg  signed	[OL-1:0]	FC_Accumulate;	// -2592 ~ +2592 : 13-bit


//==========================================================================================//
//	XNOR_POPCOUNT
//==========================================================================================//
assign XNOR = ~(iDATA ^ iWEIGHT);
assign XNOR_SUM = XNOR[0] + XNOR[1] + XNOR[2] + XNOR[3] + XNOR[4] + 
				  XNOR[5] + XNOR[6] + XNOR[7] + XNOR[8] + XNOR[9] + 
				  XNOR[10] + XNOR[11] + XNOR[12] + XNOR[13] + XNOR[14] + 
				  XNOR[15] + XNOR[16] + XNOR[17] + XNOR[18] + XNOR[19] + 
				  XNOR[20] + XNOR[21] + XNOR[22] + XNOR[23] + XNOR[24] + 
				  XNOR[25] + XNOR[26] + XNOR[27] + XNOR[28] + XNOR[29] + 
				  XNOR[30] + XNOR[31] + XNOR[32] + XNOR[33] + XNOR[34] + 
				  XNOR[35] + XNOR[36] + XNOR[37] + XNOR[38] + XNOR[39] + 
				  XNOR[40] + XNOR[41] + XNOR[42] + XNOR[43] + XNOR[44] + 
				  XNOR[45] + XNOR[46] + XNOR[47];
assign XNOR_POP = XNOR_SUM + XNOR_SUM - 48;

always @ (posedge iCLK or posedge iRST)
begin
	if(iRST) begin
		FC_Accumulate <= #1 0;
	end
	else if(iCLR) begin
		FC_Accumulate <= #1 0;
	end
	else if(iEN) begin
		FC_Accumulate <= FC_Accumulate + XNOR_POP;
	end
	else begin
		FC_Accumulate <= FC_Accumulate;
	end
end

//==========================================================================================//
//	Output
//==========================================================================================//
assign oDATA = FC_Accumulate;

endmodule