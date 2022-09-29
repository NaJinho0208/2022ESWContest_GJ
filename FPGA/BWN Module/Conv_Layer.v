module Conv_Layer(
    iCLK,
    iRST,
    iSTART,
    iDATA,
    iWEIGHT,
    oDATA
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter WL = 8;

//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input                       iCLK;
input                       iRST;
input                       iSTART;
input signed    [WL-1:0]    iDATA;
input           [8:0]       iWEIGHT;
output          [WL+7:0]    oDATA;

//==========================================================================================//
//	Internal Signal
//==========================================================================================//

// Line-Buffer
wire signed     [WL-1:0]    oDATA_BUF1;
wire signed     [WL-1:0]    oDATA_BUF2;

// Register
wire signed     [WL-1:0]    oDATA_REG33; 
wire signed     [WL-1:0]    oDATA_REG32; 
wire signed     [WL-1:0]    oDATA_REG31;

wire signed     [WL-1:0]    oDATA_REG23; 
wire signed     [WL-1:0]    oDATA_REG22; 
wire signed     [WL-1:0]    oDATA_REG21;

wire signed     [WL-1:0]    oDATA_REG13; 
wire signed     [WL-1:0]    oDATA_REG12; 
wire signed     [WL-1:0]    oDATA_REG11;
 
// MUX
wire signed     [WL:0]      oDATA_MUX33;
wire signed     [WL:0]      oDATA_MUX32;
wire signed     [WL:0]      oDATA_MUX31;

wire signed     [WL:0]      oDATA_MUX23;
wire signed     [WL:0]      oDATA_MUX22;
wire signed     [WL:0]      oDATA_MUX21;

wire signed     [WL:0]      oDATA_MUX13;
wire signed     [WL:0]      oDATA_MUX12;
wire signed     [WL:0]      oDATA_MUX11;

// Adder
wire signed     [WL+7:0]    oDATA_TMP;      // Q(8,4) * 9 = Q(16,4)


//==========================================================================================//
//	Line Buffer
//==========================================================================================//
L_BUF
#(.WL(WL), .LEN(17))
Conv1_BUF1(
    .iCLK       (iCLK       ),
    .iRST       (iRST       ),
    .iEN        (1'b1       ),
    .iSTART     (iSTART     ),
    .iDATA      (iDATA      ),
    .oDATA      (oDATA_BUF1 )
);

L_BUF
#(.WL(WL), .LEN(17))
Conv1_BUF2(
    .iCLK       (iCLK       ),
    .iRST       (iRST       ),
    .iEN        (1'b1       ),
    .iSTART     (iSTART     ),
    .iDATA      (oDATA_BUF1 ),
    .oDATA      (oDATA_BUF2 )
);

//==========================================================================================//
//	Register (3x3 kernel)
//==========================================================================================//
D_REG
#(.WL(WL))
Conv1_REG33(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(iDATA  	    ), 
    .oDATA		(oDATA_REG33    )
);

D_REG
#(.WL(WL))
Conv1_REG32(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG33    ), 
    .oDATA		(oDATA_REG32    )
);

D_REG
#(.WL(WL))
Conv1_REG31(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG32    ), 
    .oDATA		(oDATA_REG31    )
);

D_REG
#(.WL(WL))
Conv1_REG23(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_BUF1	    ), 
    .oDATA		(oDATA_REG23    )
);

D_REG
#(.WL(WL))
Conv1_REG22(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG23    ), 
    .oDATA		(oDATA_REG22    )
);

D_REG
#(.WL(WL))
Conv1_REG21(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG22    ), 
    .oDATA		(oDATA_REG21    )
);

D_REG
#(.WL(WL))
Conv1_REG13(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_BUF2	    ), 
    .oDATA		(oDATA_REG13    )
);

D_REG
#(.WL(WL))
Conv1_REG12(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG13    ), 
    .oDATA		(oDATA_REG12    )
);

D_REG
#(.WL(WL))
Conv1_REG11(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG12    ), 
    .oDATA		(oDATA_REG11    )
);


//==========================================================================================//
//	MUX
//==========================================================================================//
assign oDATA_MUX33 = iWEIGHT[0] ? oDATA_REG33 : (~oDATA_REG33 + 1);
assign oDATA_MUX32 = iWEIGHT[1] ? oDATA_REG32 : (~oDATA_REG32 + 1);
assign oDATA_MUX31 = iWEIGHT[2] ? oDATA_REG31 : (~oDATA_REG31 + 1);

assign oDATA_MUX23 = iWEIGHT[3] ? oDATA_REG23 : (~oDATA_REG23 + 1);
assign oDATA_MUX22 = iWEIGHT[4] ? oDATA_REG22 : (~oDATA_REG22 + 1);
assign oDATA_MUX21 = iWEIGHT[5] ? oDATA_REG21 : (~oDATA_REG21 + 1);

assign oDATA_MUX13 = iWEIGHT[6] ? oDATA_REG13 : (~oDATA_REG13 + 1);
assign oDATA_MUX12 = iWEIGHT[7] ? oDATA_REG12 : (~oDATA_REG12 + 1);
assign oDATA_MUX11 = iWEIGHT[8] ? oDATA_REG11 : (~oDATA_REG11 + 1);


//==========================================================================================//
//	Parallel Adder : Q(8,4) * 9 = Q(16,4)
//==========================================================================================//
assign oDATA_TMP = oDATA_MUX11 + oDATA_MUX12 + oDATA_MUX13 +
                   oDATA_MUX21 + oDATA_MUX22 + oDATA_MUX23 +
                   oDATA_MUX31 + oDATA_MUX32 + oDATA_MUX33;


//==========================================================================================//
//	Output
//==========================================================================================//
D_REG
#(.WL(WL+8))
Conv1_OUT(
    .iRST		(iRST		), 
    .iCLK		(iCLK		), 
    .iEN		(1'b1    	), 
    .iSTART		(iSTART		), 
    .iDATA		(oDATA_TMP  ), 
    .oDATA		(oDATA      )
);

endmodule