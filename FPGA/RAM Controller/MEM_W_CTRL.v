`timescale 1 ns / 100 ps

module MEM_W_CTRL(
    iFULL,
    iCLK,
    iRST,
    iEND_BWN,
    iEND_BNN_CONV,
    iEND_BNN_FC,
    oSTART_BWN,
    oSTART_BNN,
    oWADDR,
    oEN_WC,
    STATE,
    CNT_STAGE,
	CNT_STAGE_FC,
    oConCaten_Sel,
    oConCaten_CLR,
    oSel
);

//==========================================================================================//
//	parameter Definition    							    
//==========================================================================================//
parameter   STATE0      = 5'd0;
parameter   STATE1      = 5'd1;
parameter   STATE2      = 5'd2;
parameter   STATE3      = 5'd3;
parameter   STATE4      = 5'd4;
parameter   STATE5      = 5'd5;
parameter   STATE6      = 5'd6;
parameter   STATE7      = 5'd7;
parameter   STATE8      = 5'd8;
parameter   STATE9      = 5'd9;
parameter   STATE10     = 5'd10;
parameter   STATE11     = 5'd11;
parameter   STATE12     = 5'd12;
parameter   STATE13     = 5'd13;
parameter   STATE14     = 5'd14;
parameter   STATE15     = 5'd15;
parameter   STATE16     = 5'd16;

parameter   CNT_A       = 238;      // SPI -> RAM (0~237)
parameter   CNT_B       = 154;      // Conv1 -> RAM (0~153)
parameter   CNT_C       = 108;      // Conv2 -> RAM (0~107)
parameter   CNT_D       = 54;       // Conv3 -> RAM (0~53)
parameter   CNT_Stage   = 48;       // 48 STAGE
parameter   CNT_Stage_FC = 5;       // 5 LOOP(FC)

//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input               iFULL;
input               iCLK;
input               iRST;
input               iEND_BWN;
input               iEND_BNN_CONV;
input               iEND_BNN_FC;

output              oSTART_BWN;
output  [3:0]       oSTART_BNN;

output  [7:0]       oWADDR;   // 96-bit data
output              oEN_WC;

output  [7:0]       oConCaten_Sel;       // Concatenator Select Signal
output              oConCaten_CLR;  // Concatenator Clear Signal

output  [4:0]       STATE;      // 0~17 -> 5-bit
output  [5:0]       CNT_STAGE;  // oCNT_STAGE
output  [2:0]       CNT_STAGE_FC;

output              oSel;

//==========================================================================================//
//	Internal Signals
//==========================================================================================//
reg     [4:0]       current_state;
wire    [4:0]       next_state;

wire    [7:0]       oCNT_A;     // 0~237 -> 8bit
wire    [7:0]       oCNT_B;     // 0~153 -> 8bit
wire    [6:0]       oCNT_C;     // 0~107 -> 7bit
wire    [5:0]       oCNT_D;     // 0~53 -> 6bit
wire    [5:0]       oCNT_STAGE; // 0~47 -> 6bit
wire    [2:0]       oCNT_STAGE_FC;  // 0~4 -> 3bit

wire                CntA_EN;
wire                CntB_EN;
wire                CntC_EN;
wire                CntD_EN;
wire                CntStage_EN;
wire                CntStage_FC_EN;

//==========================================================================================//
// FSM
//==========================================================================================//
// Current State register
always @(posedge iCLK or posedge iRST)
begin
	if(iRST)
	begin
	    //current_state <= #1 STATE2;     // TB
        current_state <= #1 STATE0;     
	end
	else
	begin
	    current_state <= #1 next_state;
	end
end

// Next State logic
assign next_state = (current_state == STATE0 ) ? ((iFULL == 1               ) ? STATE1 : STATE0) :      // SPI -> RAM
                    (current_state == STATE1 ) ? ((oCNT_A == CNT_A-1        ) ? STATE2 : STATE1) :

                    (current_state == STATE2 ) ? STATE3 :                                               // BWN(Conv1) iSTART ON
                    (current_state == STATE3 ) ? ((iEND_BWN == 1            ) ? STATE4  : STATE3) :     // BWN(Conv1) 동작
                    (current_state == STATE4 ) ? ((oCNT_STAGE == CNT_Stage-1) ? STATE5  : STATE2) :     // 48번 동작
                    (current_state == STATE5 ) ? ((oCNT_B == CNT_B-1        ) ? STATE6  : STATE5) :     // Concatenator -> RAM

                    (current_state == STATE6 ) ? STATE7 :                                               // BNN(Conv2) iSTART ON
                    (current_state == STATE7 ) ? ((iEND_BNN_CONV == 1       ) ? STATE8  : STATE7) :     // BWN(Conv2) 동작
                    (current_state == STATE8 ) ? ((oCNT_STAGE == CNT_Stage-1) ? STATE9  : STATE6) :     // 48번 동작
                    (current_state == STATE9 ) ? ((oCNT_C == CNT_C-1        ) ? STATE10 : STATE9) :     // Concatenator -> RAM

                    (current_state == STATE10) ? STATE11 :                                                      // BNN(Conv3) iSTART ON
                    (current_state == STATE11) ? ((iEND_BNN_CONV == 1       ) ? STATE12 : STATE11) :            // BWN(Conv3) 동작
                    (current_state == STATE12) ? ((oCNT_STAGE == CNT_Stage-1) ? STATE13 : STATE10) :            // 48번 동작
                    (current_state == STATE13) ? ((oCNT_D == CNT_D-1        ) ? STATE14 : STATE13) :            // Concatenator -> RAM

                    (current_state == STATE14) ? STATE15 :                                                      // BNN(FC1) iSTART ON
                    (current_state == STATE15) ? ((iEND_BNN_FC == 1         ) ? STATE16 : STATE15) :            // BWN(FC1) 동작
                    (current_state == STATE16) ? ((oCNT_STAGE_FC == CNT_Stage_FC-1) ? STATE0 : STATE14) : STATE0;    // 5번 반복


//==========================================================================================//
// Output_logic
//==========================================================================================//
// Counter Enable Gen
assign CntA_EN = (current_state == STATE1 ) ? 1'b1 : 1'b0;
assign CntB_EN = (current_state == STATE5 ) ? 1'b1 : 1'b0;
assign CntC_EN = (current_state == STATE9 ) ? 1'b1 : 1'b0;
assign CntD_EN = (current_state == STATE13) ? 1'b1 : 1'b0;
assign CntStage_EN = (current_state == STATE4 ) ? 1'b1 :
                     (current_state == STATE8 ) ? 1'b1 :
                     (current_state == STATE12) ? 1'b1 : 1'b0;
assign CntStage_FC_EN = (current_state == STATE16) ? 1'b1 : 1'b0;                  

// Counter Function 
COUNTER 
#(.WL(8),.IV(0),.LSB(0),.ECV(CNT_A-1))    // 0~237 --> 8bit
MEM_W_COUNTER_A(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntA_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_A		)	
);

COUNTER 
#(.WL(8),.IV(0),.LSB(0),.ECV(CNT_B-1))    // 0~153 -> 8bit
MEM_W_COUNTER_B(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntB_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_B		)	
);

COUNTER 
#(.WL(7),.IV(0),.LSB(0),.ECV(CNT_C-1))    // 0~107 -> 7bit
MEM_W_COUNTER_C(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntC_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_C		)	
);

COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_D-1))    // 0~53 -> 6bit
MEM_W_COUNTER_D(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntD_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_D		)	
);

COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_Stage-1))    // 0~47 -> 6bit
MEM_W_COUNTER_STAGE(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntStage_EN),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_STAGE	)	
);

COUNTER 
#(.WL(3),.IV(0),.LSB(0),.ECV(CNT_Stage_FC-1))    // 0~4 -> 3bit
MEM_W_COUNTER_STAGE_FC(         
    .iCLK	(iCLK		    ),   
    .iRST	(iRST		    ),              
    .iEN	(CntStage_FC_EN ),
    .iCLR	(1'b0		    ),
    .oCNT	(oCNT_STAGE_FC	)	
);

//==========================================================================================//
// Final Outputs : oEN_WC, oWADDR, oSTART_BWN, oSTART_BNN, oSel, STATE, CNT_STAGE, oConCaten_CLR, CNT_STAGE_FC
//==========================================================================================//

assign oEN_WC = (current_state == STATE1 ) ? 1'b1 : 
                (current_state == STATE5 ) ? 1'b1 : 
                (current_state == STATE9 ) ? 1'b1 : 
                (current_state == STATE13) ? 1'b1 : 1'b0;

assign oWADDR = (current_state == STATE1 ) ? oCNT_A :               // 0~237 --> 8bit
                (current_state == STATE5 ) ? oCNT_B :               // 0~153 -> 8bit
                (current_state == STATE9 ) ? {1'b0, oCNT_C} :       // 0~107 -> 7bit
                (current_state == STATE13) ? {2'b0, oCNT_D} : 8'b0; // 0~53 -> 6bit

assign oSTART_BWN = (current_state == STATE2 ) ? 1'b1 : 1'b0;

assign oSTART_BNN = (current_state==STATE6 ) ? 4'b0010 :    // BNN(Conv2)
                    (current_state==STATE10) ? 4'b0100 :    // BNN(Conv3) 
                    (current_state==STATE14) ? 4'b1000 : 4'b0000;

assign oConCaten_Sel = (current_state == STATE5 ) ? oCNT_B :
                       (current_state == STATE9 ) ? {1'b0, oCNT_C} :
                       (current_state == STATE13) ? {2'b0, oCNT_D} : 8'b0;

assign oConCaten_CLR = ((current_state == STATE2) | (current_state == STATE6) | (current_state == STATE10)) & (oCNT_STAGE == 6'd0);

assign STATE = current_state;

assign CNT_STAGE = oCNT_STAGE;

assign CNT_STAGE_FC = oCNT_STAGE_FC;

assign oSel = (current_state == STATE3) ? 1'b0 :
              (current_state == STATE7) ? 1'b1 :
              (current_state == STATE11) ? 1'b1 : 1'bx;

endmodule