module BWN(
    iCLK,
    iRST,
    iSTART,
    iDATA,
    iWEIGHT,
    iTH,
    iEN,
    oDATA
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter WL = 8;       // size of one data
parameter CH = 12;      // size of channel
parameter WE = 9;       // size of weight (3x3)
parameter TH = 27;      // Threshold length Q(27,4)
parameter BL = 154;     // size of output 154-bit


//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input                   iCLK;
input                   iRST;
input                   iSTART;
input   [WL*CH-1:0]     iDATA;
input   [WE*CH-1:0]     iWEIGHT;
input signed [TH-1:0]   iTH;
input                   iEN;

output  [BL-1:0]        oDATA;

//==========================================================================================//
//	Internal Signal
//==========================================================================================//

// Conv Layer : Q(16,4)
wire signed   [WL+7:0]    oDATA_Conv1;
wire signed   [WL+7:0]    oDATA_Conv2;
wire signed   [WL+7:0]    oDATA_Conv3;
wire signed   [WL+7:0]    oDATA_Conv4;
wire signed   [WL+7:0]    oDATA_Conv5;
wire signed   [WL+7:0]    oDATA_Conv6;
wire signed   [WL+7:0]    oDATA_Conv7;
wire signed   [WL+7:0]    oDATA_Conv8;
wire signed   [WL+7:0]    oDATA_Conv9;
wire signed   [WL+7:0]    oDATA_Conv10;
wire signed   [WL+7:0]    oDATA_Conv11;
wire signed   [WL+7:0]    oDATA_Conv12;

// Adder
wire signed   [TH-1:0]    oDATA_Adder_TMP;
wire signed   [TH-1:0]    oDATA_Adder;

// Comparater
wire                oDATA_CMP_TMP;
wire                oDATA_CMP;

// Maxpooling
wire                oDATA_MP;


//==========================================================================================//
//	Convolutional (12 channel)
//==========================================================================================//
Conv_Layer
#(.WL(WL))
BWN_CH1(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[WL-1:0]          ),
    .iWEIGHT    (iWEIGHT[WE-1:0]        ),
    .oDATA      (oDATA_Conv1            )
);

Conv_Layer
#(.WL(WL))
BWN_CH2(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[2*WL-1:WL]       ),
    .iWEIGHT    (iWEIGHT[2*WE-1:WE]     ),
    .oDATA      (oDATA_Conv2            )
);

Conv_Layer
#(.WL(WL))
BWN_CH3(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[3*WL-1:2*WL]     ),
    .iWEIGHT    (iWEIGHT[3*WE-1:2*WE]   ),
    .oDATA      (oDATA_Conv3            )
);

Conv_Layer
#(.WL(WL))
BWN_CH4(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[4*WL-1:3*WL]     ),
    .iWEIGHT    (iWEIGHT[4*WE-1:3*WE]   ),
    .oDATA      (oDATA_Conv4            )
);

Conv_Layer
#(.WL(WL))
BWN_CH5(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[5*WL-1:4*WL]     ),
    .iWEIGHT    (iWEIGHT[5*WE-1:4*WE]   ),
    .oDATA      (oDATA_Conv5            )
);

Conv_Layer
#(.WL(WL))
BWN_CH6(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[6*WL-1:5*WL]     ),
    .iWEIGHT    (iWEIGHT[6*WE-1:5*WE]   ),
    .oDATA      (oDATA_Conv6            )
);

Conv_Layer
#(.WL(WL))
BWN_CH7(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[7*WL-1:6*WL]     ),
    .iWEIGHT    (iWEIGHT[7*WE-1:6*WE]   ),
    .oDATA      (oDATA_Conv7            )
);

Conv_Layer
#(.WL(WL))
BWN_CH8(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[8*WL-1:7*WL]     ),
    .iWEIGHT    (iWEIGHT[8*WE-1:7*WE]   ),
    .oDATA      (oDATA_Conv8            )
);

Conv_Layer
#(.WL(WL))
BWN_CH9(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[9*WL-1:8*WL]     ),
    .iWEIGHT    (iWEIGHT[9*WE-1:8*WE]   ),
    .oDATA      (oDATA_Conv9            )
);

Conv_Layer
#(.WL(WL))
BWN_CH10(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[10*WL-1:9*WL]    ),
    .iWEIGHT    (iWEIGHT[10*WE-1:9*WE]  ),
    .oDATA      (oDATA_Conv10           )
);

Conv_Layer
#(.WL(WL))
BWN_CH11(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[11*WL-1:10*WL]   ),
    .iWEIGHT    (iWEIGHT[11*WE-1:10*WE] ),
    .oDATA      (oDATA_Conv11           )
);

Conv_Layer
#(.WL(WL))
BWN_CH12(
    .iCLK       (iCLK                   ),
    .iRST       (iRST                   ),
    .iSTART     (iSTART                 ),
    .iDATA      (iDATA[12*WL-1:11*WL]   ),
    .iWEIGHT    (iWEIGHT[12*WE-1:11*WE] ),
    .oDATA      (oDATA_Conv12           )
);



//==========================================================================================//
//	Adder
//==========================================================================================//
assign oDATA_Adder_TMP = oDATA_Conv1 + oDATA_Conv2 + oDATA_Conv3 + oDATA_Conv4 + oDATA_Conv5 +
                         oDATA_Conv6 + oDATA_Conv7 + oDATA_Conv8 + oDATA_Conv9 + oDATA_Conv10 +
                         oDATA_Conv11 + oDATA_Conv12;

D_REG
#(.WL(TH))
BWN_Adder_REG(
.iRST		(iRST		    ), 
.iCLK		(iCLK		    ), 
.iEN		(1'b1    	    ), 
.iSTART		(iSTART		    ), 
.iDATA		(oDATA_Adder_TMP), 
.oDATA		(oDATA_Adder    )
);


//==========================================================================================//
//	Comparator
//==========================================================================================//
assign oDATA_CMP_TMP = (oDATA_Adder > iTH) ? 1'b1 : 1'b0;

D_REG
#(.WL(1))
BWN_CMP_REG(
.iRST		(iRST		    ), 
.iCLK		(iCLK		    ), 
.iEN		(1'b1    	    ), 
.iSTART		(iSTART		    ), 
.iDATA		(oDATA_CMP_TMP  ), 
.oDATA		(oDATA_CMP      )
);


//==========================================================================================//
//	MaxPooling
//==========================================================================================//
MaxPool
#(.WL(1))
BWN_Maxpool(
    .iCLK   (iCLK       ),
    .iRST   (iRST       ),
    .iSTART (iSTART     ),
    .iDATA  (oDATA_CMP  ),
    .oDATA  (oDATA_MP   )
);


//==========================================================================================//
//	Shift Register
//==========================================================================================//
Shift_REG
#(.IL(1), .BL(BL))
BWN_SHIFT_REG(
    .iCLK   (iCLK       ),
    .iRST   (iRST       ),
    .iEN    (iEN        ),
    .iSTART (iSTART     ),
    .iDATA  (oDATA_MP   ),
    .oDATA  (oDATA      )
);

endmodule