`timescale 1 ns / 100 ps

module COUNTER(
	iCLK, 
	iRST,
	iEN,
	iCLR,
	oCNT
);

parameter WL = 8;
parameter IV = 0; 	// initial value
parameter LSB = 2;
parameter ECV = 13; // end-count value

input	       		iCLK;
input	       		iRST;
input	     		iCLR;
input	       		iEN;
output	[WL-1:0]	oCNT;
		
reg		[WL-1:0]	oCNT;


always @(posedge iRST or posedge iCLK)
	begin
		if (iRST) 
		begin
	 		oCNT <= #1 IV ; 
        end
		else if(iCLR)
		begin
 			oCNT <= #1 IV ; 
        end			
		else if(iEN) 
		begin
			if(oCNT[WL-1:LSB]==ECV)
			begin	
	    		oCNT <= #1 IV;
            end
			else
			begin
				oCNT <= #1 oCNT+1;
			end			
        end
		else
		begin
				oCNT <= #1 oCNT;		
		end
	end

endmodule
