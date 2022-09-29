`timescale 1 ns / 100 ps

module BNN_TOP #(
    //==========================================================================================//
    //	Shared Parameter of BNN
    //==========================================================================================//
    parameter WL = 1,       // size of one data
    parameter CH = 48,      // size of channel
    parameter WE = 9,       // size of weight (3x3)
    parameter TH = 11,      // Threshold length 

    //==========================================================================================//
    //	Parameter of CONV2
    //==========================================================================================//    
    parameter OL = 108,     // size of output 108-bit, 9x12  
    parameter CO = 6,        // size of conv2,conv3 output
    
    //==========================================================================================//
    //	Parameter of CONV3
    //==========================================================================================//    
    parameter OL_conv3 = 54,      // size of output 54-bit, 6x9  
    
    //==========================================================================================//
    //	Parameter of fc layer
    //==========================================================================================//    
    parameter TH_fc = 13,      // size of adder output
    parameter OL_fc = 13,      // size of output 13bit  
    parameter CO_fc = 7,        // size of fc layer output	

    //==========================================================================================//
    //	Parameter of FSM //to change
    //==========================================================================================//
    //CONV2
    parameter STATE0_c2 = 5'd0,
    parameter STATE1_c2 = 5'd1,
    parameter STATE2_c2 = 5'd2,
    parameter STATE3_c2 = 5'd3,
    parameter STATE4_c2 = 5'd4,
    parameter STATE5_c2 = 5'd5,
    parameter STATE6_c2 = 5'd6,
    parameter STATE7_c2 = 5'd7,
    parameter STATE8_c2 = 5'd8,
    parameter STATE9_c2 = 5'd9,
    parameter STATE10_c2 = 5'd10,
    parameter STATE11_c2 = 5'd11,
    
    //CONV3    
    parameter STATE1_c3 = 5'd12,
    parameter STATE2_c3 = 5'd13,
    parameter STATE3_c3 = 5'd14,
    parameter STATE4_c3 = 5'd15,
    parameter STATE5_c3 = 5'd16,
    parameter STATE6_c3 = 5'd17,
    parameter STATE7_c3 = 5'd18,
    parameter STATE8_c3 = 5'd19,
    

    //FC    
    parameter STATE1_fc = 5'd20,
    parameter STATE2_fc = 5'd21,
    parameter STATE3_fc = 5'd22,
    parameter STATE4_fc = 5'd23, //oFINISH -> data1
    parameter STATE5_fc = 5'd24, //data1
    parameter STATE6_fc = 5'd25, //data2
    parameter STATE7_fc = 5'd26, //data3
    parameter STATE8_fc = 5'd27, //data4
    parameter STATE9_fc = 5'd28, //one more clock    
    
    //CONV2
    parameter CNT_A_c2 = 34, //34
    parameter CNT_B_c2 = 14, //14

    //CONV3
    parameter CNT_A_c3 = 44, //42
    parameter CNT_B_c3 = 12, //12

    //FC
    parameter CNT_A_fc = 56  //56
)(
    input wire                       iCLK,
    input wire                       iRST,
    input wire         [4:0]         STATE,
    input wire         [5:0]         CNT_STAGE,
    input wire         [2:0]         CNT_STAGE_FC,
    input wire         [3:0]         iSTART,
    input wire         [WL*CH-1:0]   iDATA,         // 48bit iDATA    
    output wire        [153:0]       oDATA,         //output 154bit  
    output wire signed [OL_fc-1 : 0] oDATA_fc_SPI,  //output 13bit   
    output wire                      oEND,          //end signal
    output wire                      oEND_fc,       //end signal of fc layer
    output wire                      oFINISH        //end signal of BNN
);

//==========================================================================================//
//	Internal Signal
//==========================================================================================//
// FSM
reg     [4:0]           current_state;
wire    [4:0]           next_state;

//conv2
wire                    CNTA_EN_c2;
wire                    CNTB_EN_c2;

//conv3
wire                    CNTA_EN_c3;
wire                    CNTB_EN_c3;

//fc
wire                    CNTA_EN_fc;
wire                    CNTB_EN_fc;

//conv2
wire    [5:0]           oCNT_A_c2;     // 34 clock
wire    [4:0]           oCNT_B_c2;     // 14 clock

//conv3
wire    [5:0]           oCNT_A_c3;     // 42 clock
wire    [4:0]           oCNT_B_c3;     // 12 clock

//fc
wire    [5:0]           oCNT_A_fc;     // 56 clock

//conv2
wire                    iEN_A_c2; //SR_EN_c2

//conv3
wire                    iEN_A_c3;

//fc
wire                    iEN_A_fc;

//conv2+conv3
wire                    iEN_A;      //SR_EN

//oEND
wire                    oEND_c2;
wire                    oEND_c3;    //->oEND

// Weight ROM
wire    [8:0]               WEIGHT_ADDR; 
wire    [WE*CH-1:0]         iWEIGHT; //9x48 x 6 layers


// Threshold ROM
wire        [6:0]        TH_ADDR;    // address 96 --> 7bit
wire signed [TH-1:0]     iTH;


//==========================================================================================//
//	BNN Layer
//==========================================================================================//
BNN #(.WL(WL),.CH(CH),.WE(WE),.TH(TH),.OL(OL), .CO(CO), 
.OL_conv3(OL_conv3),.TH_fc(TH_fc),.OL_fc(OL_fc),.CO_fc(CO_fc)) 
BNN0(
    .iCLK           (iCLK               ),
    .iRST           (iRST               ),
    .STATE          (STATE              ),
    .iSTART         (iSTART             ),
    .iDATA          (iDATA              ),
    .iWEIGHT        (iWEIGHT            ),
    .iWEIGHT_FC     (iWEIGHT[WL*CH-1:0] ),
    .iTH            (iTH                ),
    .iEN            (iEN_A              ),
    .oDATA          (oDATA              ),
    .oDATA_fc_SPI   (oDATA_fc_SPI       )
);


//==========================================================================================//
//	Conv2 + Conv3 + FC signal
//==========================================================================================//
assign iEN_A = (iEN_A_c2 | iEN_A_c3 | iEN_A_fc);
assign oEND = (oEND_c2 | oEND_c3 | oEND_fc);


//==========================================================================================//
//	FSM - Conv2
//==========================================================================================//
// Current State register
always @(posedge iCLK or posedge iRST)
begin
    if (iRST)
    begin
        current_state <= #1 STATE0_c2;
    end
    else
    begin
        current_state <= #1 next_state;
    end
end

// Next State logic - conv2
assign next_state = (current_state == STATE0_c2 ) ? ((iSTART == 4'b0010) ? STATE1_c2 : 
                                                     (iSTART == 4'b0100) ? STATE1_c3 : 
                                                     (iSTART == 4'b1000) ? STATE1_fc: STATE0_c2) : 
                    (current_state == STATE1_c2 ) ? ((oCNT_A_c2 == CNT_A_c2-1) ? STATE2_c2  : STATE1_c2) :
                    (current_state == STATE2_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE3_c2  : STATE2_c2) :
                    (current_state == STATE3_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE4_c2  : STATE3_c2) :
                    (current_state == STATE4_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE5_c2  : STATE4_c2) :
                    (current_state == STATE5_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE6_c2  : STATE5_c2) :
                    (current_state == STATE6_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE7_c2  : STATE6_c2) :
                    (current_state == STATE7_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE8_c2  : STATE7_c2) :
                    (current_state == STATE8_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE9_c2  : STATE8_c2) :
                    (current_state == STATE9_c2 ) ? ((oCNT_B_c2 == CNT_B_c2-1) ? STATE10_c2 : STATE9_c2) :
                    (current_state == STATE10_c2) ? ((oCNT_B_c2 == CNT_B_c2-3) ? STATE11_c2 : STATE10_c2) :
                    (current_state == STATE11_c2) ? STATE0_c2 : 

                    (current_state == STATE1_c3 ) ? ((oCNT_A_c3 == CNT_A_c3-1) ? STATE2_c3  : STATE1_c3) :
                    (current_state == STATE2_c3 ) ? ((oCNT_B_c3 == CNT_B_c3-1) ? STATE3_c3  : STATE2_c3) :
                    (current_state == STATE3_c3 ) ? ((oCNT_B_c3 == CNT_B_c3-1) ? STATE4_c3  : STATE3_c3) :
                    (current_state == STATE4_c3 ) ? ((oCNT_B_c3 == CNT_B_c3-1) ? STATE5_c3  : STATE4_c3) :
                    (current_state == STATE5_c3 ) ? ((oCNT_B_c3 == CNT_B_c3-1) ? STATE6_c3  : STATE5_c3) :
                    (current_state == STATE6_c3 ) ? ((oCNT_B_c3 == CNT_B_c3-1) ? STATE7_c3  : STATE6_c3) :
                    (current_state == STATE7_c3 ) ? ((oCNT_B_c3 == CNT_B_c3-4) ? STATE8_c3  : STATE7_c3) :                    
                    (current_state == STATE8_c3) ? STATE0_c2 :               
                    
                    (current_state == STATE1_fc ) ? ((oCNT_A_fc == CNT_A_fc-1) ? STATE2_fc  : STATE1_fc) :
                    (current_state == STATE2_fc ) ? STATE3_fc :
                    (current_state == STATE3_fc ) ? STATE4_fc : 
                    (current_state == STATE4_fc ) ? STATE5_fc :
                    (current_state == STATE5_fc ) ? STATE6_fc :
                    (current_state == STATE6_fc ) ? STATE7_fc : 
                    (current_state == STATE7_fc ) ? STATE8_fc :
                    (current_state == STATE8_fc ) ? STATE9_fc :
                    (current_state == STATE9_fc ) ? STATE0_c2 : STATE9_fc;

// Counter Enable Gen
assign CNTA_EN_c2 = (current_state == STATE1_c2 ) ? 1'b1 : 1'b0 ;

assign CNTB_EN_c2 = (current_state == STATE2_c2 ) ? 1'b1 :
                    (current_state == STATE3_c2 ) ? 1'b1 :
                    (current_state == STATE4_c2 ) ? 1'b1 : 
                    (current_state == STATE5_c2 ) ? 1'b1 :
                    (current_state == STATE6_c2 ) ? 1'b1 :
                    (current_state == STATE7_c2 ) ? 1'b1 :
                    (current_state == STATE8_c2 ) ? 1'b1 :
                    (current_state == STATE9_c2 ) ? 1'b1 :
                    (current_state == STATE10_c2) ? 1'b1 : 1'b0;            

// Counter Function 
// 34 clock
COUNTER #(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A_c2-1))  
BNN_COUNTER_A(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN_c2	),
    .iCLR	(|iSTART		),
    .oCNT	(oCNT_A_c2		)	
);

 // 14 clock
COUNTER #(.WL(5),.IV(0),.LSB(0),.ECV(CNT_B_c2-1))  
BNN_COUNTER_B(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTB_EN_c2	),
    .iCLR	(|iSTART		),
    .oCNT	(oCNT_B_c2		)	
);

// Shift Register Enable Gen
assign iEN_A_c2 =   (current_state == STATE2_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE3_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE4_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE5_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE6_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE7_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE8_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE9_c2 ) ? ( (oCNT_B_c2 < 4'd12) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE10_c2) ? 1'b1 : 1'b0;

assign oEND_c2   =  (current_state == STATE11_c2) ? 1'b1 : 1'b0;

//==========================================================================================//
//	FSM - Conv3
//==========================================================================================//
// Counter Enable Gen
assign CNTA_EN_c3 = (current_state == STATE1_c3 ) ? 1'b1 : 1'b0 ;

assign CNTB_EN_c3 = (current_state == STATE2_c3 ) ? 1'b1 :
                    (current_state == STATE3_c3 ) ? 1'b1 :
                    (current_state == STATE4_c3 ) ? 1'b1 :
                    (current_state == STATE5_c3 ) ? 1'b1 :
                    (current_state == STATE6_c3 ) ? 1'b1 : 
                    (current_state == STATE7_c3 ) ? 1'b1 : 1'b0;                      

// Counter Function 
// 42 clock
COUNTER #(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A_c3-1))  
BNN_COUNTER_D(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN_c3	),
    .iCLR	(|iSTART		),
    .oCNT	(oCNT_A_c3		)	
);

 // 12 clock
COUNTER #(.WL(5),.IV(0),.LSB(0),.ECV(CNT_B_c3-1))  
BNN_COUNTER_E(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTB_EN_c3	),
    .iCLR	(|iSTART		),
    .oCNT	(oCNT_B_c3	)	
);

// Shift Register Enable Gen
assign iEN_A_c3 =   (current_state == STATE2_c3 ) ? ( (oCNT_B_c3 < 4'd9) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE3_c3 ) ? ( (oCNT_B_c3 < 4'd9) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE4_c3 ) ? ( (oCNT_B_c3 < 4'd9) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE5_c3 ) ? ( (oCNT_B_c3 < 4'd9) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE6_c3 ) ? ( (oCNT_B_c3 < 4'd9) ? 1'b1 : 1'b0 )  :
                    (current_state == STATE7_c3 ) ?  1'b1 : 1'b0;

assign oEND_c3  =   (current_state == STATE8_c3) ? 1'b1 : 1'b0;

//==========================================================================================//
//	FSM - FC layer
//==========================================================================================//
// Counter Enable Gen
assign CNTA_EN_fc = (current_state == STATE1_fc ) ? 1'b1 : 1'b0 ;
assign CNTB_EN_fc = (current_state == STATE4_fc ) ? 1'b1 : 1'b0 ;

// Counter Function 
// 56 clock
COUNTER #(.WL(6),.IV(0),.LSB(0),.ECV(CNT_A_fc-1))  
BNN_COUNTER_A_FC(         
    .iCLK	(iCLK		),   
    .iRST	(iRST		),              
    .iEN	(CNTA_EN_fc	),
    .iCLR	(|iSTART		),
    .oCNT	(oCNT_A_fc	)	
);


// Shift Register Enable Gen
assign iEN_A_fc =   (current_state == STATE2_fc ) ? 1'b1 : 1'b0;

assign oEND_fc   =  (current_state == STATE3_fc) ? 1'b1 : 1'b0;

assign oFINISH =    (current_state == STATE4_fc) ? 1'b1 :
                    (current_state == STATE5_fc) ? 1'b1 :
                    (current_state == STATE6_fc) ? 1'b1 : 
                    (current_state == STATE7_fc) ? 1'b1 :
                    (current_state == STATE8_fc) ? 1'b1 :
                    (current_state == STATE9_fc) ? 1'b1 : 1'b0;

//==========================================================================================//
//	Weight ROM
//==========================================================================================//
assign  WEIGHT_ADDR = (STATE==5'd7 ) ? CNT_STAGE : 
                      (STATE==5'd11) ? (CNT_STAGE + 48) : 
                      (STATE==5'd15) ? (96 + CNT_STAGE_FC * 48 + CNT_STAGE) : 9'd0;

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