module Xnor_popcount_fc#(
    parameter OL = 7        
)(
    input wire           iCLK,
    input wire           iRST,
	input wire [3:0]     iSTART,
    input wire           iDATA, //1bit
    input wire           iEN, //connect to oCNT_FC
    input wire           iWEIGHT, //1bit
    output wire [OL-1:0] oDATA //7bit
);


wire 			   xnor_result; //1bit
reg 	[OL-1 : 0] xnor_pop; //7bit
wire 	[OL-1 : 0] xnor_pop_result;



assign xnor_result = ~(iDATA ^ iWEIGHT); //xnor

always @(posedge iCLK or posedge iRST)
	begin
		if(iRST) begin
			xnor_pop <= 0;
		end
		else if (|iSTART) begin
			xnor_pop <= 0;
		end
		else if (iEN)
			begin
			xnor_pop <= xnor_pop + xnor_result; //accumulate
			end
		else  //if 54 counting complete
			begin
			xnor_pop <= xnor_pop;
			end
	end


assign xnor_pop_result = xnor_pop + xnor_pop - 7'd54;


D_REG #(.WL(OL))
xnor_pop_result_fc(
.iRST		(iRST				), 
.iCLK		(iCLK				), 
.iEN		(1'b1    			), 
.iSTART		(|iSTART			), 
.iDATA		(xnor_pop_result  	), 
.oDATA		(oDATA      		)
);

endmodule
