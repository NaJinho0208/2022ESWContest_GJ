// jongsul module verilog code
/*
	SPI protocol: SPI top module
	included module:
		N Counter(N=96, N=180)
		Comparaotr(expressed as module, but simple code in verilog)
		FIFO(96*180 size, 13*5 size)
		Shift Reg(1 to 96, 13 to 1)
*/

module SPI_protocol(
	sclk,
	ss,
	mosi,
	iRST,
	oFINISH,
	oDATA,
	wren_FIFOOUT,
	clk,
	rden,
	miso,
	spi_out,
	wrfull);

parameter iWL = 96; // input data width
parameter iLEN = 180; // input data length
parameter oWL = 13; // output data width
parameter oLEN = 5; // output data length
parameter WL_96 = 7; // 96 counter bit width
parameter WL_180 = 8; // 180 counter bit width

input 				sclk; // spi line: clock of spi
input 				ss; // spi line: chip select bit
input 				mosi; // spi line: Rpi -> FPGA data
input				iRST; // RESET: positive
input				oFINISH; // oFINISH: signal for total output
input 	[oWL-1:0]	oDATA; // input line for final data to send Rpi
input				wren_FIFOOUT; // wren data of FIFO_OUT: output from BNN Layer
input				rden; // signal for FIFO_IN to Zero Padding
input 				clk; // FPGA clock
output 				miso; // spi_line: FPGA -> Rpi data
output 	[iWL-1:0]	spi_out; // output line for FIFO_IN
output 				wrfull; // signal for data INPUT completed

wire	[iWL-1:0]		line_reg2FIFO; // line connected between shift reg to FIFO_IN
wire	[oWL-1:0]		line_FIFO2reg; // line connected between FIFO_OUT to shift reg
wire	[WL_96-1:0]		oDATA_ct96; // output data of 96 counter
wire	[WL_180-1:0]	oDATA_ct180; // output data of 180 counter
wire	[4:0]			oDATA_ct16; // output data of 16 counter
wire					oDATA_cmp16; // output data of 16 comparator
wire					iDATA_ct96; // rst input data of 96 counter
wire					iDATA_ct180; // rst input data of 180 counter 
wire					oDATA_cmp96; // output data of 96 comparator
wire					oDATA_cmp180; // output data of 180 comparator
wire					wren_FIFOIN; // wren data of FIFO_IN
wire					wrused_FIFOOUT; // rdempty data of FIFO_OUT
wire					rden_FIFOOUT; // rden data of FIFO_OUT
wire	[7:0]			fifo_count; // fifo count of data
wire	[7:0]			fifo_read; // read fifo count of data
wire					wrfull_FIFOIN; // wrfull wire: set 1 when fifo count is 180
reg 	[1:0]			wrfull_reg; // wrfull register: single pulse generator
reg						oFINISH_reg; // oFINISH: set 1 when output occured

s2p_register 
#(.WL(iWL)) 
s2p_reg(
	.in(mosi),
	.en(1'b1),
	.iRST(ss),
	.clk(sclk),
	.out(line_reg2FIFO)
);

fifo_in	fifo_in_inst (
	.aclr (iRST),
	.data (line_reg2FIFO),
	.rdclk (clk),
	.rdreq (rden),
	.wrclk (sclk),
	.wrreq (wren_FIFOIN),
	.q (spi_out),
	.wrusedw (fifo_count),
	.rdusedw (fifo_read)
	);

assign wrfull_FIFOIN = (fifo_count == 8'd181) & ss;

// single pulse generate: 
always @(posedge clk) begin
	wrfull_reg <= {wrfull_reg[0], wrfull_FIFOIN};
end

assign wrfull = ~wrfull_reg[1] & wrfull_reg[0];

p2s_register p2s_reg(
	.in(line_FIFO2reg),
	.en(1'b1),
	.parallel_in(oDATA_cmp16),
	.iRST(ss),
	.clk(sclk),
	.out(miso)
);

COUNTER_SPI 
#(.WL(5),.IV(1),.LSB(0),.ECV(16))  // 16 clock = 5bit
counter_16(         
    .iCLK	(sclk		),   
    .iRST	(ss			),
    .iEN	(oFINISH_reg),
    .iCLR	(1'b0		),
    .oCNT	(oDATA_ct16	)	
);


// save 0 when wrfull signal is on because of saved data vanishing
dcfifo_example
#(.LOG_DEPTH(3), .WIDTH(13), .ALMOST_FULL_VALUE(6), .NUM_WORDS(7))
fifo_out(
	.aclr		(iRST),
	.data		(oDATA),
	.rdclk	(sclk),
	.rdreq	(oDATA_cmp16),
	.wrclk	(clk),
	.wrreq	(wren_FIFOOUT | wrfull),
	.q			(line_FIFO2reg),
	.wrusedw	(wrused_FIFOOUT)
);

/*fifo_out	fifo_out_inst (
	.aclr (iRST),
	.data (oDATA),
	.rdclk (sclk),
	.rdreq (oDATA_cmp16),
	.wrclk (clk),
	.wrreq (wren_FIFOOUT | wrfull),  
	.q (line_FIFO2reg),
	.wrusedw(wrused_FIFOOUT)
	);


Counter_nbit_sync 
#(.WL(WL_96)) 
counter_96(
	.rst(iDATA_ct96),
	.clk(sclk),
	.en(1'b1),
	.out(oDATA_ct96)
); */

COUNTER 
#(.WL(WL_96),.IV(0),.LSB(0),.ECV(95))  // 59 clock = 6bit
counter_96(         
    .iCLK	(sclk		),   
    .iRST	(ss			),              
    .iEN	(1'b1		),
    .iCLR	(1'b0		),
    .oCNT	(oDATA_ct96	)	
);

always @(posedge iRST, posedge clk) begin
	if(iRST) oFINISH_reg <= 1'b0;
	else if(oFINISH) begin
		oFINISH_reg <= 1'b1;
	end
	else if(wrfull) begin
		oFINISH_reg <= 1'b0;
	end
	else begin
		oFINISH_reg <= oFINISH_reg;
	end
end

/*
Counter_nbit_async
#(.WL(WL_180)) 
counter_180(
	.rst(iDATA_ct180),
	.clk(sclk),
	.en(oDATA_cmp96),
	.out(oDATA_ct180)
);*/

COUNTER 
#(.WL(WL_180),.IV(0),.LSB(0),.ECV(181))  // 180 clock = 7bit
counter_180(         
    .iCLK	(sclk		),   
    .iRST	(ss			),              
    .iEN	(oDATA_cmp96),
    .iCLR	(1'b0		),
    .oCNT	(oDATA_ct180)	
);


assign oDATA_cmp96 = (7'd95 == oDATA_ct96) ? 1 : 0;
assign oDATA_cmp180 = (8'd181 == oDATA_ct180) ? 1 : 0;
assign oDATA_cmp16 = (5'd16 == oDATA_ct16) ? 1 : 0;
//assign iDATA_ct96 = oDATA_cmp96 | ss;  // positive rst
// assign iDATA_ct180 = oDATA_cmp180 | ss; // ss = 1 and counter180 = 180 => reset
//assign iDATA_ct180 = ss; // reset when ss = 1, counter 180 is useless?
assign wren_FIFOIN = (~|oDATA_ct96) & |oDATA_ct180;
// assign rden_FIFOOUT = ~(ss | rdempty_FIFOOUT);


endmodule
