module BNN_CONV(
	iCLK,
	iRST,
	iSTART,
	iDATA,
	iWEIGHT,
	iSEL,
	oDATA
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter OL = 5;   // size of output : -9(10111) ~ +9(01001) -> 5bit

//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input				iCLK;
input				iRST;
input				iSTART;
input				iDATA;
input	[8:0]		iWEIGHT;
input				iSEL;

output signed [OL-1:0]	oDATA;


//==========================================================================================//
//	Internal Signal
//==========================================================================================//
// Line-Buffer
wire	oDATA_Conv2_BUF1; 	// 2-length line buffer for conv3
wire    oDATA_Conv2_BUF2; 	// 2-length line buffer for conv3

wire    oDATA_MUX_BUF1; 	// 12-length line buffer(input)
wire    oDATA_MUX_BUF2; 	// 12-length line buffer(input)

wire    oDATA_BUF1; 		// 14-length buffer(output)
wire    oDATA_BUF2; 		// 14-length buffer(output)

// Register
wire    oDATA_REG33; 
wire    oDATA_REG32; 
wire    oDATA_REG31;

wire    oDATA_REG23; 
wire    oDATA_REG22; 
wire    oDATA_REG21;

wire    oDATA_REG13; 
wire    oDATA_REG12; 
wire    oDATA_REG11;

// XNOR
wire    oDATA_XNOR33;
wire    oDATA_XNOR32;
wire    oDATA_XNOR31;

wire    oDATA_XNOR23;
wire    oDATA_XNOR22;
wire    oDATA_XNOR21;

wire    oDATA_XNOR13;
wire    oDATA_XNOR12;
wire    oDATA_XNOR11;

// POPCOUNT
wire          [OL-2:0] oDATA_POP;  //5bit 0~9 1001
wire signed   [OL-1:0] oDATA_TMP;  //6bit

//==========================================================================================//
//	Line Buffer
//==========================================================================================//

// 2-length line buffer (for conv2)
L_BUF #(.WL(1), .LEN(2))
Conv2_BUF1(
	.iCLK		(iCLK				),
	.iRST       (iRST      			),
	.iEN        (1'b1       		),
	.iSTART     (iSTART     		),
	.iDATA      (iDATA      		),
	.oDATA      (oDATA_Conv2_BUF1 	)
);

L_BUF #(.WL(1), .LEN(2))
Conv2_BUF2(
	.iCLK       (iCLK       		),
	.iRST       (iRST      			),
	.iEN        (1'b1       		),
	.iSTART     (iSTART     		),
	.iDATA      (oDATA_BUF1 		),
	.oDATA      (oDATA_Conv2_BUF2 	)
);

// 12-length line buffer (for sharing)
L_BUF #(.WL(1), .LEN(12))
Conv3_BUF1(
	.iCLK       (iCLK       		),
	.iRST       (iRST      			),
	.iEN        (1'b1       		),
	.iSTART     (iSTART     		),
	.iDATA      (oDATA_MUX_BUF1 	),
	.oDATA      (oDATA_BUF1 		)
);

L_BUF #(.WL(1), .LEN(12))
Conv3_BUF2(
	.iCLK       (iCLK       		),
	.iRST       (iRST      			),
	.iEN        (1'b1       		),
	.iSTART     (iSTART     		),
	.iDATA      (oDATA_MUX_BUF2 	),
	.oDATA      (oDATA_BUF2 		)
);


//==========================================================================================//
//	MUX - conv2 / conv3
//==========================================================================================//
assign oDATA_MUX_BUF1 = (iSEL == 1'b0)? oDATA_Conv2_BUF1 : iDATA;
assign oDATA_MUX_BUF2 = (iSEL == 1'b0)? oDATA_Conv2_BUF2 : oDATA_BUF1;


//==========================================================================================//
//	Register (3x3 kernel)
//==========================================================================================//
D_REG #(.WL(1))
Conv_REG33(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(iDATA  	), 
.oDATA		(oDATA_REG33)
);

D_REG #(.WL(1))
Conv_REG32(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_REG33), 
.oDATA		(oDATA_REG32)
);

D_REG #(.WL(1))
Conv_REG31(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_REG32), 
.oDATA		(oDATA_REG31)
);

D_REG #(.WL(1))
Conv_REG23(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_BUF1	), 
.oDATA		(oDATA_REG23)
);

D_REG #(.WL(1))
Conv_REG22(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_REG23), 
.oDATA		(oDATA_REG22)
);

D_REG #(.WL(1))
Conv_REG21(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_REG22), 
.oDATA		(oDATA_REG21)
);

D_REG #(.WL(1))
Conv_REG13(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_BUF2	), 
.oDATA		(oDATA_REG13)
);

D_REG #(.WL(1))
Conv_REG12(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_REG13), 
.oDATA		(oDATA_REG12)
);

D_REG #(.WL(1))
Conv_REG11(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART		), 
.iDATA		(oDATA_REG12), 
.oDATA		(oDATA_REG11)
);

//==========================================================================================//
//	XNOR
//==========================================================================================//
assign oDATA_XNOR33 = ~(iWEIGHT[0] ^ oDATA_REG33);
assign oDATA_XNOR32 = ~(iWEIGHT[1] ^ oDATA_REG32);
assign oDATA_XNOR31 = ~(iWEIGHT[2] ^ oDATA_REG31);

assign oDATA_XNOR23 = ~(iWEIGHT[3] ^ oDATA_REG23);
assign oDATA_XNOR22 = ~(iWEIGHT[4] ^ oDATA_REG22);
assign oDATA_XNOR21 = ~(iWEIGHT[5] ^ oDATA_REG21);

assign oDATA_XNOR13 = ~(iWEIGHT[6] ^ oDATA_REG13);
assign oDATA_XNOR12 = ~(iWEIGHT[7] ^ oDATA_REG12);
assign oDATA_XNOR11 = ~(iWEIGHT[8] ^ oDATA_REG11);


//==========================================================================================//
//	Popcount calculation
//==========================================================================================//
assign oDATA_POP =  oDATA_XNOR33 + oDATA_XNOR32 + oDATA_XNOR31 +
                    oDATA_XNOR23 + oDATA_XNOR22 + oDATA_XNOR21 +
                    oDATA_XNOR13 + oDATA_XNOR12 + oDATA_XNOR11;	// counting '1'

assign oDATA_TMP = oDATA_POP + oDATA_POP - 9;	// popcount

//==========================================================================================//
//	Output- 9bit calculation (accumulation X) 
//==========================================================================================//

D_REG #(.WL(OL))
Conv_OUT(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART    	), 
.iDATA		(oDATA_TMP  ), 
.oDATA		(oDATA      )
);

endmodule