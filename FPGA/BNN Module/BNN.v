module BNN(
    iCLK,
    iRST,
    iSTART,
    iDATA,
    iWEIGHT,
    iTH,
    iEN,
    iSEL,
    TH_ADDR,
    oDATA
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter WL = 1;           // size of one data
parameter CH = 48;          // size of channel
parameter WE = 9;           // size of weight (3x3)
parameter TH = 11;          // Threshold length 11-bit
parameter BL_Conv2 = 108;   // size of output 108-bit, 9x12
parameter BL_Conv3 = 54;    // size of output 54-bit, 6x9
parameter OL = 154;         // Concatenator 154-bit     
parameter CO = 5;           // Convolution Layer Output 5-bit


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
input                   iSEL;
input   [6:0]           TH_ADDR;

output  [OL-1:0]        oDATA;


//==========================================================================================//
//	Internal Signal
//==========================================================================================//
// Conv Layer 
wire signed [CO-1:0]    oDATA_Conv [0:CH-1];    // 5-bit * 48CH

// Adder
wire signed [TH-1:0]    oDATA_Adder_TMP;
wire signed [TH-1:0]    oDATA_Adder;

// Comparater
wire                    oDATA_CMP_TMP_UP;
wire                    oDATA_CMP_TMP_DOWN;
wire                    oDATA_CMP_TMP;
wire                    oDATA_CMP;

// Maxpooling
wire                    oDATA_MP_OR;
wire                    oDATA_MP_AND;
wire                    oDATA_MP;

// Shift Reg
wire                    iSR_DATA;
wire    [BL_Conv2-1:0]  oDATA_SR;

//==========================================================================================//
//	Convolutional (48 channel)
//==========================================================================================//
genvar i;
generate 
    for(i=0; i<CH; i=i+1) begin : conv_xnor
        BNN_CONV #(.OL(CO)) 
        BNN_Conv_Layer(
            .iCLK       (iCLK                       ),
	        .iRST       (iRST                       ),
	        .iSTART     (iSTART                     ),
	        .iDATA      (iDATA[i]                   ),
	        .iWEIGHT    (iWEIGHT[(i+1)*WE-1:(i)*WE] ),
	        .iSEL       (iSEL                       ),
	        .oDATA      (oDATA_Conv[i]              )
        );
    end
endgenerate

//==========================================================================================//
//	Adder
//==========================================================================================//
assign oDATA_Adder_TMP = oDATA_Conv[0] + oDATA_Conv[1] + oDATA_Conv[2] + oDATA_Conv[3] + oDATA_Conv[4] + 
                         oDATA_Conv[5] + oDATA_Conv[6] + oDATA_Conv[7] + oDATA_Conv[8] + oDATA_Conv[9] + 
                         oDATA_Conv[10] + oDATA_Conv[11] + oDATA_Conv[12] + oDATA_Conv[13] + oDATA_Conv[14] + 
                         oDATA_Conv[15] + oDATA_Conv[16] + oDATA_Conv[17] + oDATA_Conv[18] + oDATA_Conv[19] + 
                         oDATA_Conv[20] + oDATA_Conv[21] + oDATA_Conv[22] + oDATA_Conv[23] + oDATA_Conv[24] + 
                         oDATA_Conv[25] + oDATA_Conv[26] + oDATA_Conv[27] + oDATA_Conv[28] + oDATA_Conv[29] + 
                         oDATA_Conv[30] + oDATA_Conv[31] + oDATA_Conv[32] + oDATA_Conv[33] + oDATA_Conv[34] + 
                         oDATA_Conv[35] + oDATA_Conv[36] + oDATA_Conv[37] + oDATA_Conv[38] + oDATA_Conv[39] + 
                         oDATA_Conv[40] + oDATA_Conv[41] + oDATA_Conv[42] + oDATA_Conv[43] + oDATA_Conv[44] + 
                         oDATA_Conv[45] + oDATA_Conv[46] + oDATA_Conv[47];

D_REG #(.WL(TH)) 
BNN_Adder_REG(
    .iRST		(iRST		        ), 
    .iCLK	   	(iCLK		        ), 
    .iEN		(1'b1    	        ), 
    .iSTART		(iSTART		        ), 
    .iDATA		(oDATA_Adder_TMP    ), 
    .oDATA		(oDATA_Adder        )
);

//==========================================================================================//
//	Comparator
//==========================================================================================//
assign oDATA_CMP_TMP_UP = (oDATA_Adder > iTH) ? 1'b1 : 1'b0;
assign oDATA_CMP_TMP_DOWN = (oDATA_Adder > iTH) ? 1'b0 : 1'b1;

assign oDATA_CMP_TMP = (TH_ADDR == 7'd14) ? oDATA_CMP_TMP_DOWN :
                       (TH_ADDR == 7'd50) ? oDATA_CMP_TMP_DOWN :
                       (TH_ADDR == 7'd51) ? oDATA_CMP_TMP_DOWN :
                       (TH_ADDR == 7'd53) ? oDATA_CMP_TMP_DOWN :
                       (TH_ADDR == 7'd62) ? oDATA_CMP_TMP_DOWN :
                       (TH_ADDR == 7'd86) ? oDATA_CMP_TMP_DOWN :
                       (TH_ADDR == 7'd90) ? oDATA_CMP_TMP_DOWN : oDATA_CMP_TMP_UP;

D_REG #(.WL(1))
BNN_CMP_REG(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART         ), 
    .iDATA		(oDATA_CMP_TMP  ), 
    .oDATA		(oDATA_CMP      )
);

//==========================================================================================//
//	MaxPooling
//==========================================================================================//
MaxPool_C3 #(.WL(1), .LB(12)) 
BNN_Maxpool(
    .iCLK       (iCLK           ),
    .iRST       (iRST           ),
    .iSTART     (iSTART         ), 
    .iDATA      (oDATA_CMP      ),
    .oDATA_OR   (oDATA_MP_OR    ),
    .oDATA_AND  (oDATA_MP_AND   )
);

assign oDATA_MP = (TH_ADDR == 7'd14) ? oDATA_MP_AND :
                  (TH_ADDR == 7'd50) ? oDATA_MP_AND :
                  (TH_ADDR == 7'd51) ? oDATA_MP_AND :
                  (TH_ADDR == 7'd53) ? oDATA_MP_AND :
                  (TH_ADDR == 7'd62) ? oDATA_MP_AND :
                  (TH_ADDR == 7'd86) ? oDATA_MP_AND :
                  (TH_ADDR == 7'd90) ? oDATA_MP_AND : oDATA_MP_OR;

//==========================================================================================//
//	Shift Register
//==========================================================================================//
// iSEL=0 -> Conv2 (NO Maxpooling)
// iSEL=1 -> Conv3 (Maxpooling)
assign iSR_DATA = (iSEL == 1'b0) ? oDATA_CMP : oDATA_MP;

Shift_REG #(.IL(1), .BL(BL_Conv2))
BNN_SHIFT_REG2(
    .iCLK       (iCLK       ),
    .iRST       (iRST       ),
    .iEN		(iEN    	),
    .iSTART     (iSTART     ),
    .iDATA      (iSR_DATA   ),
    .oDATA      (oDATA_SR   )
);

// oDATA
assign oDATA = (iSEL == 1'b0) ? {46'b0, oDATA_SR} : {100'b0, oDATA_SR[BL_Conv2-1:BL_Conv2-BL_Conv3]};

endmodule