
//iSTART - 0001 BWN           max pool
//         0010 BNN conv2     x
//         0100 BNN conv3     max pool
//         1000 BNN fc layer  x

module MaxPool_C3(
    iCLK,
    iRST,
    iSTART,     
    iDATA,
    oDATA_OR,
    oDATA_AND
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter WL = 1;
parameter LB = 12;
//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input       iCLK;
input       iRST;
input       iSTART;
input       iDATA;

output      oDATA_OR;
output      oDATA_AND;

//==========================================================================================//
//	Internal Signal
//==========================================================================================//

// Line-Buffer
wire    oDATA_BUF1;

// Register (2x2)
wire    oDATA_REG11;
wire    oDATA_REG12;
wire    oDATA_REG21;
wire    oDATA_REG22;

// MaxPooling result
reg    oDATA_TMP; 

//==========================================================================================//
//	Line Buffer
//==========================================================================================//
L_BUF
#(.WL(1), .LEN(LB))
MP1_BUF1(
    .iCLK       (iCLK       ),
    .iRST       (iRST       ),
    .iEN        (1'b1       ),
    .iSTART     (iSTART     ),
    .iDATA      (iDATA      ),
    .oDATA      (oDATA_BUF1 )
);

//==========================================================================================//
//	Register (2x2 kernel)
//==========================================================================================//
D_REG
#(.WL(1))
MP1_REG11(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART 	), 
.iDATA		(iDATA  	), 
.oDATA		(oDATA_REG11)
);

D_REG
#(.WL(1))
MP1_REG12(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART 	), 
.iDATA		(oDATA_REG11), 
.oDATA		(oDATA_REG12)
);

D_REG
#(.WL(1))
MP1_REG21(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART     ), 
.iDATA		(oDATA_BUF1	), 
.oDATA		(oDATA_REG21)
);

D_REG
#(.WL(1))
MP1_REG22(
.iRST		(iRST		), 
.iCLK		(iCLK		), 
.iEN		(1'b1    	), 
.iSTART		(iSTART	    ), 
.iDATA		(oDATA_REG21), 
.oDATA		(oDATA_REG22)
);

//==========================================================================================//
//	Output
//==========================================================================================//
assign oDATA_OR = oDATA_REG11 | oDATA_REG12 | oDATA_REG21 | oDATA_REG22;
assign oDATA_AND = oDATA_REG11 & oDATA_REG12 & oDATA_REG21 & oDATA_REG22;

endmodule