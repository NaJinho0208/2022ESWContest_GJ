`timescale 1 ns / 100 ps

module BNN_CONV_TOP(
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
parameter WL = 1;           // size of one data
parameter CH = 48;          // size of channel
parameter WE = 9;           // size of weight (3x3)
parameter TH = 11;          // Threshold length 11-bit
parameter BL_Conv2 = 108;   // size of output 108-bit, 9x12
parameter BL_Conv3 = 54;    // size of output 54-bit, 6x9
parameter OL = 154;         // Concatenator 154-bit     
parameter CO = 5;           // Convolution Layer Output 5-bit

parameter STATE0 = 5'd0;

parameter STATE1_C2 = 5'd1;
parameter STATE2_C2 = 5'd2;
parameter STATE3_C2 = 5'd3;
parameter STATE4_C2 = 5'd4;
parameter STATE5_C2 = 5'd5;
parameter STATE6_C2 = 5'd6;
parameter STATE7_C2 = 5'd7;
parameter STATE8_C2 = 5'd8;
parameter STATE9_C2 = 5'd9;
parameter STATE10_C2 = 5'd10;
parameter STATE11_C2 = 5'd11;

parameter STATE1_C3 = 5'd12;
parameter STATE2_C3 = 5'd13;
parameter STATE3_C3 = 5'd14;
parameter STATE4_C3 = 5'd15;
parameter STATE5_C3 = 5'd16;
parameter STATE6_C3 = 5'd17;
parameter STATE7_C3 = 5'd18;
parameter STATE8_C3 = 5'd19;

parameter CNT_A_C2 = 36;
parameter CNT_B_C2 = 14;

parameter CNT_A_C3 = 46;
parameter CNT_B_C3 = 12;


//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input                   iCLK;
input                   iRST;
input    [3:0]          iSTART;
input    [WL*CH-1:0]    iDATA;
input    [4:0]          STATE;
input    [5:0]          CNT_STAGE;

output   [OL-1:0]       oDATA;
output                  oEND;

//==========================================================================================//
//	Internal Signal
//==========================================================================================//
// FSM
reg     [4:0]       current_state;
wire    [4:0]       next_state;

wire                CNTA_EN_C2;
wire                CNTB_EN_C2;

wire                CNTA_EN_C3;
wire                CNTB_EN_C3;

wire    [5:0]       oCNT_A_C2;  // 34 clock - 6bit
wire    [3:0]       oCNT_B_C2;  // 14 clock - 4bit

wire    [5:0]       oCNT_A_C3;  // 44 clock - 6bit
wire    [3:0]       oCNT_B_C3;  // 12 clock - 4bit

// BNN Layer
wire                iSEL;
wire                iEN;

// Weight ROM
wire    [6:0]           WEIGHT_ADDR;    // 0~95 -> 7bit
wire    [WE*CH-1:0]     iWEIGHT;


// Threshold ROM
wire        [6:0]       TH_ADDR;    // 0~95 -> 7bit
wire signed [TH-1:0]    iTH;


//==========================================================================================//
//	BNN Layer (1)
//==========================================================================================//
BNN
#(.WL(WL), .CH(CH), .WE(WE), .TH(TH), .BL_Conv2(BL_Conv2), .BL_Conv3(BL_Conv3), .OL(OL), .CO(CO))
BNN_Layer(
    .iCLK       (iCLK       ),
    .iRST       (iRST       ),
    .iSTART     (|iSTART    ),
    .iDATA      (iDATA      ),
    .iWEIGHT    (iWEIGHT    ),
    .iTH        (iTH        ),
    .iEN        (iEN        ),
    .iSEL       (iSEL       ),
    .TH_ADDR    (TH_ADDR    ),
    .oDATA      (oDATA      )
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
assign next_state = (current_state == STATE0 ) ? ((iSTART == 4'b0010) ? STATE1_C2 :
                                                  (iSTART == 4'b0100) ? STATE1_C3 : STATE0) :
                    (current_state == STATE1_C2 ) ? ((oCNT_A_C2 == CNT_A_C2-1) ? STATE2_C2 : STATE1_C2) :
                    (current_state == STATE2_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE3_C2 : STATE2_C2) :
                    (current_state == STATE3_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE4_C2 : STATE3_C2) :
                    (current_state == STATE4_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE5_C2 : STATE4_C2) :
                    (current_state == STATE5_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE6_C2 : STATE5_C2) :
                    (current_state == STATE6_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE7_C2 : STATE6_C2) :
                    (current_state == STATE7_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE8_C2 : STATE7_C2) :
                    (current_state == STATE8_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE9_C2 : STATE8_C2) :
                    (current_state == STATE9_C2 ) ? ((oCNT_B_C2 == CNT_B_C2-1) ? STATE10_C2 : STATE9_C2) :
                    (current_state == STATE10_C2) ? ((oCNT_B_C2 == CNT_B_C2-3) ? STATE11_C2 : STATE10_C2) :
                    (current_state == STATE11_C2) ? STATE0 :

                    (current_state == STATE1_C3 ) ? ((oCNT_A_C3 == CNT_A_C3-1) ? STATE2_C3 : STATE1_C3) :
                    (current_state == STATE2_C3 ) ? ((oCNT_B_C3 == CNT_B_C3-1) ? STATE3_C3 : STATE2_C3) :
                    (current_state == STATE3_C3 ) ? ((oCNT_B_C3 == CNT_B_C3-1) ? STATE4_C3 : STATE3_C3) :
                    (current_state == STATE4_C3 ) ? ((oCNT_B_C3 == CNT_B_C3-1) ? STATE5_C3 : STATE4_C3) :
                    (current_state == STATE5_C3 ) ? ((oCNT_B_C3 == CNT_B_C3-1) ? STATE6_C3 : STATE5_C3) :
                    (current_state == STATE6_C3 ) ? ((oCNT_B_C3 == CNT_B_C3-1) ? STATE7_C3 : STATE6_C3) :
                    (current_state == STATE7_C3 ) ? ((oCNT_B_C3 == CNT_B_C3-4) ? STATE8_C3 : STATE7_C3) :
                    (current_state == STATE8_C3 ) ? STATE0 : STATE0;

// Counter Enable Gen
assign CNTA_EN_C2 = (current_state == STATE1_C2 ) ? 1'b1 : 1'b0;
assign CNTB_EN_C2 = (current_state == STATE2_C2 ) ? 1'b1 : 
                    (current_state == STATE3_C2 ) ? 1'b1 :
                    (current_state == STATE4_C2 ) ? 1'b1 :
                    (current_state == STATE5_C2 ) ? 1'b1 :
                    (current_state == STATE6_C2 ) ? 1'b1 :
                    (current_state == STATE7_C2 ) ? 1'b1 :
                    (current_state == STATE8_C2 ) ? 1'b1 :
                    (current_state == STATE9_C2 ) ? 1'b1 :
                    (current_state == STATE10_C2) ? 1'b1 : 1'b0;

assign CNTA_EN_C3 = (current_state == STATE1_C3 ) ? 1'b1 : 1'b0;
assign CNTB_EN_C3 = (current_state == STATE2_C3 ) ? 1'b1 : 
                    (current_state == STATE3_C3 ) ? 1'b1 :
                    (current_state == STATE4_C3 ) ? 1'b1 :
                    (current_state == STATE5_C3 ) ? 1'b1 :
                    (current_state == STATE6_C3 ) ? 1'b1 :
                    (current_state == STATE7_C3 ) ? 1'b1 : 1'b0;

// Counter Function
COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A_C2-1))   // 34 clock = 6bit
BNN_COUNTER_A(         
    .iCLK   (iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN_C2	),
    .iCLR	(|iSTART    ),
    .oCNT	(oCNT_A_C2	)	
);

 // 12 clock
COUNTER 
#(.WL(4),.IV(0),.LSB(0),.ECV(CNT_B_C2-1))  // 14 clock = 4bit
BNN_COUNTER_B(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTB_EN_C2	),
    .iCLR	(|iSTART	),
    .oCNT	(oCNT_B_C2	)	
);

COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A_C3-1))   // 44 clock = 6bit
BNN_COUNTER_C(         
    .iCLK   (iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN_C3	),
    .iCLR	(|iSTART    ),
    .oCNT	(oCNT_A_C3	)	
);

 // 12 clock
COUNTER 
#(.WL(4),.IV(0),.LSB(0),.ECV(CNT_B_C3-1))  // 12 clock = 4bit
BNN_COUNTER_D(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTB_EN_C3	),
    .iCLR	(|iSTART	),
    .oCNT	(oCNT_B_C3	)	
);

//==========================================================================================//
//	iSEL, iEN, oEND
//==========================================================================================//
assign iSEL =   (STATE == 5'd7) ? 1'b0 : 
                (STATE == 5'd11) ? 1'b1 : 1'bx;

// Shift Register Enable Gen
assign iEN  =   (current_state == STATE2_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE3_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE4_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE5_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE6_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE7_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE8_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE9_C2 ) ? ( (oCNT_B_C2 < 4'd12) ? 1'b1 : 1'b0 ) :
                (current_state == STATE10_C2) ? 1'b1 :

                (current_state == STATE2_C3 ) ? ( (oCNT_B_C3 < 4'd9) ? 1'b1 : 1'b0 ) :
                (current_state == STATE3_C3 ) ? ( (oCNT_B_C3 < 4'd9) ? 1'b1 : 1'b0 ) :
                (current_state == STATE4_C3 ) ? ( (oCNT_B_C3 < 4'd9) ? 1'b1 : 1'b0 ) :
                (current_state == STATE5_C3 ) ? ( (oCNT_B_C3 < 4'd9) ? 1'b1 : 1'b0 ) :
                (current_state == STATE6_C3 ) ? ( (oCNT_B_C3 < 4'd9) ? 1'b1 : 1'b0 ) :
                (current_state == STATE7_C3 ) ? 1'b1 : 1'b0;

assign oEND =   (current_state == STATE11_C2) ? 1'b1 :
                (current_state == STATE8_C3 ) ? 1'b1 : 1'b0;

//==========================================================================================//
//	Weight ROM
//==========================================================================================//
assign  WEIGHT_ADDR = (STATE==5'd7 ) ? CNT_STAGE : 
                      (STATE==5'd11) ? (CNT_STAGE + 48) : 9'd0;

BNN_WEIGHT_ROM	BNN_WEIGHT_ROM_inst (
	.address    ( WEIGHT_ADDR   ),
	.clock      ( iCLK          ),
	.q          ( iWEIGHT       )
);

//==========================================================================================//
//	Threshold ROM
//==========================================================================================//
assign  TH_ADDR = (STATE==5'd7 ) ? CNT_STAGE : 
                  (STATE==5'd11) ? (CNT_STAGE + 48) : 7'd0;

BNN_TH_ROM	BNN_TH_ROM_inst (
	.address    ( TH_ADDR   ),
	.clock      ( iCLK      ),
	.q          ( iTH       )
);

endmodule