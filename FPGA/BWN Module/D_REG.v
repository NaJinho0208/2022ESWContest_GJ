`timescale 1 ns / 100 ps

module D_REG(
	iRST, 
	iCLK, 
	iEN, 
	iSTART, 
	iDATA, 
	oDATA
);
    
parameter WL = 8;

input				iRST;
input				iCLK;
input				iEN;
input				iSTART;
input	[WL-1:0]	iDATA;
output	[WL-1:0] 	oDATA;
reg 	[WL-1:0] 	oDATA;

always @(posedge iCLK or posedge iRST)
begin
	if (iRST)	begin
		 oDATA  <= #1 0;
	end
	else if (iSTART)	begin
		 oDATA  <= #1 0;
	end
	else if (iEN)	begin
		oDATA	<= #1 iDATA;	
	end
	else	begin
		oDATA	<= #1 oDATA;	
	end
end
endmodule

