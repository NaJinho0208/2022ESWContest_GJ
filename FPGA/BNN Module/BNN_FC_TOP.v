`timescale 1 ns / 100 ps

module BNN_FC_TOP(
    iCLK,
    iRST,
    iSTART,
    iDATA,
    RADDR,
	STATE,
	CNT_STAGE_FC,
	oDATA,
	oEND,
    oFINISH
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter IL = 48;
parameter OL = 13;

parameter STATE0 = 2'd0;
parameter STATE1 = 2'd1;
parameter STATE2 = 2'd2;
parameter STATE3 = 2'd3;

parameter CNT_A = 56;

//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input				iCLK;
input 				iRST;
input 				iSTART;
input	[IL-1:0]	iDATA;
input 	[4:0]		STATE;
input 	[7:0]		RADDR;
input 	[2:0]		CNT_STAGE_FC;

output 	[OL-1:0]	oDATA;
output 				oEND;
output 				oFINISH;

//==========================================================================================//
//	Internal Signal
//==========================================================================================//
// FSM
reg     [1:0]       current_state;
wire    [1:0]       next_state;

// FC Layer
wire 				iEN;
// wire 				iEN_REG1;
// wire 				iEN_REG2;

// Counter
wire 	[5:0]		oCNT_A;
wire 				CNTA_EN;

// RADDR Register
// wire 	[7:0]		RADDR_REG1;
// wire 	[7:0]		RADDR_REG2;

// Weight ROM
wire    [8:0]    	WEIGHT_ADDR;    // 0~269 -> 9bit
wire    [IL-1:0]    iWEIGHT;


//==========================================================================================//
//	RADDR / iEN Register
//==========================================================================================//
// D_REG
// #(.WL(8))
// BNN_FC_REG1(
// 	.iRST		(iRST		    ), 
// 	.iCLK		(iCLK		    ), 
// 	.iEN		(1'b1    	    ), 
// 	.iSTART		(iSTART		    ), 
// 	.iDATA		(RADDR  		), 
// 	.oDATA		(RADDR_REG1     )
// );

// D_REG
// #(.WL(8))
// BNN_FC_REG2(
// 	.iRST		(iRST		    ), 
// 	.iCLK		(iCLK		    ), 
// 	.iEN		(1'b1    	    ), 
// 	.iSTART		(iSTART		    ), 
// 	.iDATA		(RADDR_REG1		), 
// 	.oDATA		(RADDR_REG2     )
// );

// D_REG
// #(.WL(1))
// BNN_FC_REG3(
// 	.iRST		(iRST		    ), 
// 	.iCLK		(iCLK		    ), 
// 	.iEN		(1'b1    	    ), 
// 	.iSTART		(iSTART		    ), 
// 	.iDATA		(iEN	  		), 
// 	.oDATA		(iEN_REG1	    )
// );

// D_REG
// #(.WL(1))
// BNN_FC_REG3(
// 	.iRST		(iRST		    ), 
// 	.iCLK		(iCLK		    ), 
// 	.iEN		(1'b1    	    ), 
// 	.iSTART		(iSTART		    ), 
// 	.iDATA		(iEN_REG1  		), 
// 	.oDATA		(iEN_REG2	    )
// );

//==========================================================================================//
//	BNN FC Layer (1)
//==========================================================================================//
BNN_FC	#(.IL(IL), .OL(OL))
BNN_FC_Layer(
	.iCLK		(iCLK		),
	.iRST		(iRST		),
	.iCLR		(iSTART		),
	.iDATA		(iDATA		),
	.iWEIGHT	(iWEIGHT	),
	.iEN		(iEN		),
	.oDATA		(oDATA		)
);


//==========================================================================================//
//	FSM
//==========================================================================================//
// Current State register
always @(posedge iCLK or posedge iRST)
begin
    if (iRST)
    begin
        current_state <= #1 STATE0;
    end
    else
    begin
        current_state <= #1 next_state;
    end
end

// Next State Logic
assign next_state = (current_state == STATE0) ? ((iSTART == 1'b1) ? STATE1 : STATE0) :
					(current_state == STATE1) ? ((oCNT_A == CNT_A-1) ? STATE2 : STATE1) :
					(current_state == STATE2) ? ((CNT_STAGE_FC == 3'd4) ? STATE3 : STATE0) :
					(current_state == STATE3) ? STATE0 : STATE0;

// Counter Function
assign CNTA_EN = (current_state == STATE1) ? 1'b1 : 1'b0;
COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A-1))  // 57 clock = 6bit
BNN_FC_COUNTER(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN	),
    .iCLR	(iSTART		),
    .oCNT	(oCNT_A		)	
);

//==========================================================================================//
//	iEN, oEND, oFINISH
//==========================================================================================//
assign iEN 	= (current_state == STATE1) & (oCNT_A > 6'd1) & (oCNT_A < CNT_A);
assign oEND = (current_state == STATE2) ? 1'b1 : 1'b0;
assign oFINISH = (current_state == STATE3) ? 1'b1 : 1'b0;


//==========================================================================================//
//	Weight ROM
//==========================================================================================//
assign WEIGHT_ADDR = (STATE == 5'd15) ? (CNT_STAGE_FC * 54) + RADDR : 9'dx;

BNN_FC_WEIGHT_ROM	BNN_FC_WEIGHT_ROM_inst (
	.address ( WEIGHT_ADDR 	),
	.clock 	 ( iCLK 		),
	.q 		 ( iWEIGHT 		)
);

endmodule