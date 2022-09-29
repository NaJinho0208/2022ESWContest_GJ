`timescale 1 ns / 100 ps

module MEM_R_CTRL(
    iCLK,
    iRST,
    iSTART_BWN,
    iSTART_BNN,
    oRADDR,
    oEN_RC
);

//==========================================================================================//
//	parameter Definition    							    
//==========================================================================================//
parameter   STATE0      = 4'd0;
parameter   STATE1      = 4'd1;
parameter   STATE2      = 4'd2;
parameter   STATE3      = 4'd3;
parameter   STATE4      = 4'd4;
parameter   STATE5      = 4'd5;
parameter   STATE6      = 4'd6;
parameter   STATE7      = 4'd7;
parameter   STATE8      = 4'd8;
parameter   STATE9      = 4'd9;
parameter   STATE10     = 4'd10;
parameter   STATE11     = 4'd11;

parameter   CNT_A       = 238;      // RAM -> SPI   (0~237)
parameter   CNT_B       = 154;      // RAM -> Conv1 (0~153)
parameter   CNT_C       = 108;      // RAM -> Conv2 (0~107)
parameter   CNT_D       = 54;       // RAM -> Conv3 (0~53)
parameter   CNT_Stage   = 48;       // 48 STAGE
parameter   CNT_Stage_FC = 5;       // 5 LOOP(FC)


//==========================================================================================//
//	Input/Output Signal
//==========================================================================================//
input               iCLK;
input               iRST;
input               iSTART_BWN;
input   [3:0]       iSTART_BNN;

output  [7:0]       oRADDR;
output              oEN_RC;


//==========================================================================================//
//	Internal Signals
//==========================================================================================//
reg     [3:0]       current_state;
wire    [3:0]       next_state;

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
	    current_state <= #1 STATE0;
	end
	else
	begin
	    current_state <= #1 next_state;
	end
end

// Next State logic
assign next_state = (current_state == STATE0 ) ? ((iSTART_BWN == 1          ) ? STATE1 : STATE0) :      // BWN(Conv1)
                    (current_state == STATE1 ) ? ((oCNT_A == CNT_A-1        ) ? STATE2 : STATE1) :
                    (current_state == STATE2 ) ? ((oCNT_STAGE == CNT_Stage-1) ? STATE3 : STATE0) : 

                    (current_state == STATE3 ) ? ((iSTART_BNN == 4'b0010    ) ? STATE4 : STATE3) :      // BNN(Conv2)
                    (current_state == STATE4 ) ? ((oCNT_B == CNT_B-1        ) ? STATE5 : STATE4) :
                    (current_state == STATE5 ) ? ((oCNT_STAGE == CNT_Stage-1) ? STATE6 : STATE3) :

                    (current_state == STATE6 ) ? ((iSTART_BNN == 4'b0100    ) ? STATE7 : STATE6) :      // BNN(Conv3)
                    (current_state == STATE7 ) ? ((oCNT_C == CNT_C-1        ) ? STATE8 : STATE7) :
                    (current_state == STATE8 ) ? ((oCNT_STAGE == CNT_Stage-1) ? STATE9 : STATE6) :

                    (current_state == STATE9 ) ? ((iSTART_BNN == 4'b1000    ) ? STATE10 : STATE9) :     // BNN(FC1)
                    (current_state == STATE10) ? ((oCNT_D == oCNT_D-1       ) ? STATE11 : STATE10) :
                    (current_state == STATE11) ? ((oCNT_STAGE_FC == CNT_Stage_FC-1) ? STATE0 : STATE9) : STATE0;


//==========================================================================================//
// Output_logic
//==========================================================================================//
// Counter Enable Gen
assign CntA_EN = (current_state == STATE1 ) ? 1'b1 : 1'b0;
assign CntB_EN = (current_state == STATE4 ) ? 1'b1 : 1'b0;
assign CntC_EN = (current_state == STATE7 ) ? 1'b1 : 1'b0;
assign CntD_EN = (current_state == STATE10) ? 1'b1 : 1'b0;
assign CntStage_EN = (current_state == STATE2) ? 1'b1 :
                     (current_state == STATE5) ? 1'b1 :
                     (current_state == STATE8) ? 1'b1 : 1'b0;
assign CntStage_FC_EN = (current_state == STATE11) ? 1'b1 : 1'b0;                  

// Counter Function 
COUNTER 
#(.WL(8),.IV(0),.LSB(0),.ECV(CNT_A-1))    // 0~237 --> 8bit
MEM_R_COUNTER_A(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntA_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_A		)	
);

COUNTER 
#(.WL(8),.IV(0),.LSB(0),.ECV(CNT_B-1))    // 0~153 -> 8bit
MEM_R_COUNTER_B(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntB_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_B		)	
);

COUNTER 
#(.WL(7),.IV(0),.LSB(0),.ECV(CNT_C-1))    // 0~107 -> 7bit
MEM_R_COUNTER_C(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntC_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_C		)	
);

COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_D-1))    // 0~53 -> 6bit
MEM_R_COUNTER_D(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntD_EN	),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_D		)	
);

COUNTER 
#(.WL(6),.IV(0),.LSB(0),.ECV(CNT_Stage-1))    // 0~47 -> 6bit
MEM_R_COUNTER_STAGE(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CntStage_EN),
    .iCLR	(1'b0		),
    .oCNT	(oCNT_STAGE	)	
);

COUNTER 
#(.WL(3),.IV(0),.LSB(0),.ECV(CNT_Stage_FC-1))    // 0~4 -> 3bit
MEM_R_COUNTER_STAGE_FC(         
    .iCLK	(iCLK		    ),   
    .iRST	(iRST		    ),              
    .iEN	(CntStage_FC_EN ),
    .iCLR	(1'b0		    ),
    .oCNT	(oCNT_STAGE_FC	)	
);


//==========================================================================================//
// Final Outputs : oEN_RC, oRADDR
//==========================================================================================//
assign	oEN_RC  =   (current_state == STATE1 ) ? 1'b1 : 
                    (current_state == STATE4 ) ? 1'b1 : 
                    (current_state == STATE7 ) ? 1'b1 : 
                    (current_state == STATE10) ? 1'b1 : 1'b0;

assign	oRADDR  =   (current_state == STATE1 ) ? {oCNT_A        } :         // 8bit(0~237)
                    (current_state == STATE4 ) ? {oCNT_B        } :         // 8bit(0~153)
                    (current_state == STATE7 ) ? {1'b0, oCNT_C  } :         // 7bit(0~107)
                    (current_state == STATE10) ? {2'b0, oCNT_D  } : 8'b0;   // 6bit(0~53)

endmodule