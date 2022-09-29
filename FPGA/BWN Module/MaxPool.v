module MaxPool(
    iCLK,
    iRST,
    iSTART,
    iDATA,
    oDATA
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter WL = 1;

//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input       iCLK;
input       iRST;
input       iSTART;
input       iDATA;
output      oDATA;

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
wire    oDATA_MP_TMP;

//==========================================================================================//
//	Line Buffer
//==========================================================================================//
L_BUF
#(.WL(1), .LEN(17))
MP1_BUF1(
    .iCLK       (iCLK           ),
    .iRST       (iRST          ),
    .iEN        (1'b1           ),
    .iSTART     (iSTART         ),
    .iDATA      (iDATA          ),
    .oDATA      (oDATA_BUF1     )
);

//==========================================================================================//
//	Register (2x2 kernel)
//==========================================================================================//
D_REG
#(.WL(1))
MP1_REG11(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(iDATA  	    ), 
    .oDATA		(oDATA_REG11    )
);

D_REG
#(.WL(1))
MP1_REG12(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG11    ), 
    .oDATA		(oDATA_REG12    )
);

D_REG
#(.WL(1))
MP1_REG21(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_BUF1	    ), 
    .oDATA		(oDATA_REG21    )
);

D_REG
#(.WL(1))
MP1_REG22(
    .iRST		(iRST		    ), 
    .iCLK		(iCLK		    ), 
    .iEN		(1'b1    	    ), 
    .iSTART		(iSTART		    ), 
    .iDATA		(oDATA_REG21    ), 
    .oDATA		(oDATA_REG22    )
);

//==========================================================================================//
//	OR Operation (2x2 MaxPooling)
//==========================================================================================//
// assign oDATA_MP_TMP = oDATA_REG11 | oDATA_REG12 | oDATA_REG21 | oDATA_REG22;


//==========================================================================================//
//	Output
//==========================================================================================//
assign oDATA = oDATA_REG11 | oDATA_REG12 | oDATA_REG21 | oDATA_REG22;

// D_REG
// #(.WL(1))
// MP1_OUT(
//     .iRST		(iRST		    ), 
//     .iCLK		(iCLK		    ), 
//     .iEN		(1'b1    	    ), 
//     .iSTART		(iSTART		    ), 
//     .iDATA		(oDATA_REG11 | oDATA_REG12 | oDATA_REG21 | oDATA_REG22   ), 
//     .oDATA		(oDATA          )
// );


endmodule