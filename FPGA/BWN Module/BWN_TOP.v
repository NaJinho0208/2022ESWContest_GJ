`timescale 1 ns / 100 ps

module BWN_TOP(
    iCLK,
    iRST,
    iSTART,
    iDATA,
    oDATA,
    oEND,
    STATE,
    CNT_STAGE
);

//==========================================================================================//
//	Parameter
//==========================================================================================//
parameter WL = 8;       // size of one data
parameter CH = 12;      // size of channel
parameter WE = 9;       // size of weight (3x3)
parameter TH = 27;      // Threshold length Q(27,4)
parameter BL = 154;     // size of output 154-bit

parameter STATE0 = 4'b0000;
parameter STATE1 = 4'b0001;
parameter STATE2 = 4'b0010;
parameter STATE3 = 4'b0011;
parameter STATE4 = 4'b0100;
parameter STATE5 = 4'b0101;
parameter STATE6 = 4'b0110;
parameter STATE7 = 4'b0111;
parameter STATE8 = 4'b1000;
parameter STATE9 = 4'b1001;
parameter STATE10 = 4'b1010;
parameter STATE11 = 4'b1011;
parameter STATE12 = 4'b1100;
parameter STATE13 = 4'b1101;

parameter CNT_A = 60;
parameter CNT_B = 17;


//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input                   iCLK;
input                   iRST;
input                   iSTART;
input   [WL*CH-1:0]     iDATA;
input   [4:0]           STATE;
input   [5:0]           CNT_STAGE;

output  [BL-1:0]        oDATA;
output                  oEND;


//==========================================================================================//
//	Internal Signal
//==========================================================================================//

// FSM
reg     [3:0]           current_state;
wire    [3:0]           next_state;
wire                    CNTA_EN;
wire                    CNTB_EN;

wire    [5:0]           oCNT_A;     // 57 clock
wire    [4:0]           oCNT_B;     // 17 clock

wire                    iEN;

// Weight ROM
wire    [5:0]           WEIGHT_ADDR;
wire    [WE*CH-1:0]     iWEIGHT;

// Threshold ROM
wire        [5:0]       TH_ADDR;
wire signed [TH-1:0]    iTH;


//==========================================================================================//
//	BWN Layer (6)
//==========================================================================================//
BWN
#(.WL(WL),.CH(CH),.WE(WE),.TH(TH),.BL(BL))
BWN_Layer(
    .iCLK       (iCLK                       ),
    .iRST       (iRST                       ),
    .iSTART     (iSTART                     ),
    .iDATA      (iDATA                      ),
    .iWEIGHT    (iWEIGHT                    ),
    .iTH        (iTH                        ),
    .iEN        (iEN                        ),
    .oDATA      (oDATA                      )
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

// Next State logic
assign next_state = (current_state == STATE0 ) ? ((iSTART == 1) ? STATE1 : STATE0) :
                    (current_state == STATE1 ) ? ((oCNT_A == CNT_A-1) ? STATE2  : STATE1) :
                    (current_state == STATE2 ) ? ((oCNT_B == CNT_B-1) ? STATE3  : STATE2) :
                    (current_state == STATE3 ) ? ((oCNT_B == CNT_B-1) ? STATE4  : STATE3) :
                    (current_state == STATE4 ) ? ((oCNT_B == CNT_B-1) ? STATE5  : STATE4) :
                    (current_state == STATE5 ) ? ((oCNT_B == CNT_B-1) ? STATE6  : STATE5) :
                    (current_state == STATE6 ) ? ((oCNT_B == CNT_B-1) ? STATE7  : STATE6) :
                    (current_state == STATE7 ) ? ((oCNT_B == CNT_B-1) ? STATE8  : STATE7) :
                    (current_state == STATE8 ) ? ((oCNT_B == CNT_B-1) ? STATE9  : STATE8) :
                    (current_state == STATE9 ) ? ((oCNT_B == CNT_B-1) ? STATE10 : STATE9) :
                    (current_state == STATE10) ? ((oCNT_B == CNT_B-1) ? STATE11 : STATE10) :
                    (current_state == STATE11) ? ((oCNT_B == CNT_B-1) ? STATE12 : STATE11) :
                    (current_state == STATE12) ? ((oCNT_B == CNT_B-4) ? STATE13 : STATE12) :
                    (current_state == STATE13) ? STATE0 : STATE0;

// Counter Enable Gen
assign CNTA_EN = (current_state == STATE1 ) ? 1'b1 : 1'b0;
assign CNTB_EN = (current_state == STATE0 ) ? 1'b0 :
                 (current_state == STATE1 ) ? 1'b0 :
                 (current_state == STATE13) ? 1'b0 : 1'b1;

// Counter Function 
COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A-1))  // 57 clock = 6bit
BWN_COUNTER_A(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN	),
    .iCLR	(iSTART		),
    .oCNT	(oCNT_A		)	
);

COUNTER 
#(.WL(5),.IV(0),.LSB(0),.ECV(CNT_B-1))  // 17 clock = 5bit
BWN_COUNTER_B(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTB_EN	),
    .iCLR	(iSTART		),
    .oCNT	(oCNT_B		)	
);

// Shift Register Enable Gen
assign iEN      =   (current_state == STATE2 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE3 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE4 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE5 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE6 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE7 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE8 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE9 ) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE10) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE11) ? ( (oCNT_B < 4'd14) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE12) ? 1'b1 : 1'b0;

assign oEND     =   (current_state == STATE13) ? 1'b1 : 1'b0;


//==========================================================================================//
//	Weight ROM
//==========================================================================================//
assign WEIGHT_ADDR = (STATE==5'd3) ? CNT_STAGE : 6'dx;

BWN_WEIGHT_ROM	BWN_WEIGHT_ROM_inst (
	.address    ( WEIGHT_ADDR   ),
	.clock      ( iCLK          ),
	.q          ( iWEIGHT       )
);


//==========================================================================================//
//	Threshold ROM
//==========================================================================================//
assign TH_ADDR = (STATE==5'd3) ? CNT_STAGE : 6'dx;

BWN_TH_ROM	BWN_TH_ROM_inst (
	.address    ( TH_ADDR   ),
	.clock      ( iCLK      ),
	.q          ( iTH       )
);

endmodule