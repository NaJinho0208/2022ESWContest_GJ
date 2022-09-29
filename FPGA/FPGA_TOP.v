// jongsul module verilog code
/*
	SPI&BWN_top_module Topmodule: FOR TEST
	included module:
		SPI protocol: shift reg & FIFO
		Zero Padding: gives zero padding for spectrogram
        RAM: Dual port ram(96bit & 6bit port), 396 size
        mem_w_ctrl: Memory Write Controller(completed)
		mem_r_ctrl: Memory Read Controller(completed)
*/

module total_BNN_acc_top(
    sclk,
	ss,
	iRSTn,
	mosi,
	clk,
	miso
);

/*
================= Parameters ===================
*/
parameter WLa = 96; // Port a width: 96bit
parameter WLb = 6; // Port b width: 6bit
parameter WLc = 13; // Final Output data width: 13bit(signed)
parameter iLEN = 181; // input data length
parameter oLEN = 5; // output data length
parameter ADDRWa = 9; // address width of 96bit port
parameter ADDRWb = 13; // address width of 6bit port

/*
================= I/O ===================
*/
input 				    sclk; // spi line: clock of spi
input 				    ss; // spi line: chip select bit
input				    iRSTn; // total RESET: negative reset
input					mosi; // spi line: master out slave in 
input 				    clk; // FPGA clock
output 				    miso; // spi_line: FPGA -> Rpi data

/*
================= Data wires ===================
*/
wire    [WLa-1:0]       line_SPI2padding; // line from SPI to Zero Padding
wire    [WLa-1:0]       line_padding2RAM; // line from Zero Padding to RAM   
wire	[153:0]		    line_bwn2con; // bwn output: connected to Concatenater
wire	[153:0]		    line_bnn2con; // bnn output: connected to Concatenater
wire    [153:0]         iDATA_Concate; // concatenater input: MUX output
wire	[WLa-1:0]		iDATA_RAM; // MUX output, input line for RAM
wire	[WLa-1:0]		oDATA_RAM; // output line for RAM
wire	[WLc-1:0]		line_bnn2SPI; // line from BNN to SPI: Final Value
wire    [47:0]          Concate_Data; // output data of Concatenater

/*
================= Control Wires ===================
*/
wire					iRST; // iRST: positive reset
wire                    FIFO_IN_rden; // rden for FIFO_IN
wire                    iFULL; // set 1 if FIFO_IN is full(181)
wire    [3:0]           start_bnn; // starting signal of BNN
wire                    start_bwn; // starting signal of BNN
wire                    RAM_EN_WC; // write enable signal of RAM
wire                    RAM_EN_RC; // read enable signal of RAM
wire    [ADDRWa-1:0]    RAM_RADDR; // RAM read address: output of read controller
wire    [ADDRWa-1:0]    RAM_WADDR; // RAM write address: output of write controller
wire    [ADDRWa-1:0]    RAM_ADDR; // RAM address: OR data of WADDR & RADDR
wire					oSel; // Selection bit for RAM B input(BWN or BNN)
wire    [7:0]           Concate_Sel; // Selection bit for Concatenater
wire					oEND_bwn; // end signal of BWN
wire					oEND_bnn; // end signal of BNN
wire					oEND_bnn_fc; // end signal of FC Layer
wire                    iEN_Concate; // iEN signal of Concatenater
wire					oFINISH; // Total end signal of BNN: SPI get it					
wire	[6:0]			STATE; // state value of write controller
wire    [5:0]           STAGE; // Stage value of total BNN Structure
wire    [2:0]           STAGE_FC; // Stage value of FC Structure

assign iRST = ~iRSTn;	// reset change: neg to pos

SPI_protocol spi0 (
    .sclk(sclk),
    .ss(ss),
    .mosi(mosi),
    .iRST(iRST),
    .oFINISH(oFINISH),
    .oDATA(line_bnn2SPI),
    .wren_FIFOOUT(oEND_bnn_fc),
    .rden(FIFO_IN_rden),
    .clk(clk),
    .miso(miso),
    .spi_out(line_SPI2padding),
    .wrfull(iFULL)
);

ZeroPadding_new zeropadding (
	.rst(iRST),
	.clk(clk),
	.in(line_SPI2padding),
	.STATE(STATE),
	.wrfull(iFULL),
	.out(line_padding2RAM),
	.rdreq(FIFO_IN_rden)
);

// RAM Write Controller
MEM_W_CTRL mem_w_ctrl (
    .iFULL(iFULL),
	.iCLK(clk),
	.iRST(iRST),
    .iEND_BWN(oEND_bwn),
    .iEND_BNN_CONV(oEND_bnn),
    .iEND_BNN_FC(oEND_bnn_fc),
    .oSTART_BWN(start_bwn),
    .oSTART_BNN(start_bnn),
    .oWADDR         (RAM_WADDR),
    .oEN_WC         (RAM_EN_WC),
    .STATE          (STATE),
    .CNT_STAGE      (STAGE),
    .CNT_STAGE_FC   (STAGE_FC),
    .oConCaten_Sel  (Concate_Sel),
    .oConCaten_CLR  (Concate_CLR),
	.oSel(oSel)
);

reg start_bwn_delay;
always @(posedge clk or posedge iRST) begin
	if(iRST) start_bwn_delay <= 1'b0;
	else start_bwn_delay <= start_bwn;
end

// RAM Read Controller
MEM_R_CTRL MEM_R_CTRL0(
    .iCLK           (clk),
    .iRST           (iRST),
    .iSTART_BWN     (start_bwn),
    .iSTART_BNN     (start_bnn),
    .oRADDR         (RAM_RADDR),
    .oEN_RC         (RAM_EN_RC)
);

RAM	RAM_inst (
	.address        (RAM_ADDR),
	.clock          (clk),
	.data           (iDATA_RAM),
	.rden           (RAM_EN_RC),
	.wren           (RAM_EN_WC),
	.q              (oDATA_RAM)
);
assign RAM_ADDR = RAM_RADDR | RAM_WADDR;
assign iDATA_RAM = line_padding2RAM | {48'b0, Concate_Data};

// BWN module
BWN_TOP bwn_top0(
    .iCLK(clk),
    .iRST(iRST),
    .iSTART(start_bwn_delay),
    .iDATA(oDATA_RAM),
    .oDATA(line_bwn2con),
    .oEND(oEND_bwn),
    .STATE(STATE),
    .CNT_STAGE(STAGE)
);

BNN_CONV_TOP bnn_top0(
    .iCLK(clk),
    .iRST(iRST),
    .iSTART(start_bnn),
    .iDATA(oDATA_RAM[47:0]),
    .oDATA(line_bnn2con),
    .oEND(oEND_bnn),
    .STATE(STATE),
    .CNT_STAGE(STAGE)
);

BNN_FC_TOP fc_top0(
    .iCLK(clk),
    .iRST(iRST),
    .iSTART(start_bnn[3]),
    .iDATA(oDATA_RAM[47:0]),
    .RADDR(RAM_RADDR),
    .oDATA(line_bnn2SPI),
    .oEND(oEND_bnn_fc),
    .STATE(STATE),
    .oFINISH(oFINISH),
    .CNT_STAGE_FC(STAGE_FC)
);

// Concatenater
Concatenater Concatenater0(
    .iCLK           (clk),
    .iRST           (iRST),
    .iCLR           (Concate_CLR),
    .iEN            (iEN_Concate),
    .iSel           (Concate_Sel),
    .iDATA          (iDATA_Concate),
    .oDATA          (Concate_Data)
);
assign iDATA_Concate = oSel ? line_bnn2con : line_bwn2con;
assign iEN_Concate = oEND_bnn | oEND_bwn;

endmodule