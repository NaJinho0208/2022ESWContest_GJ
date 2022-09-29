`timescale 1 ns / 100 ps

module L_BUF(
    iCLK,
    iRST,
    iEN,
    iSTART,
    iDATA,
    oDATA
);

parameter WL = 8;       // Size of one space of buffer
parameter LEN = 17;     // 17-Length Line Buffer

input                   iRST;
input                   iCLK;
input                   iEN;
input                   iSTART;
input   [WL-1:0]        iDATA;
output  [WL-1:0]        oDATA;

reg     [WL*LEN-1:0]    DATA_reg;  // Line-Buffer

always @ (posedge iCLK or posedge iRST)
begin
    if (iRST) begin
        DATA_reg <= #1 0;
    end
    else if (iSTART) begin
        DATA_reg <= #1 0;
    end
    else if (iEN) begin
        DATA_reg <= #1 {iDATA, DATA_reg[WL*LEN-1:WL]};
    end
    else begin
        DATA_reg <= #1 DATA_reg;
    end
end

assign oDATA = DATA_reg[WL-1:0]; 

endmodule