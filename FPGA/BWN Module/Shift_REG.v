`timescale 1 ns / 100 ps

module Shift_REG(
    iCLK,
    iRST,
    iEN,
    iSTART,
    iDATA,
    oDATA
);

parameter IL = 1;       // Input Size
parameter BL = 154;     // Buffer Size

input               iRST;
input               iCLK;
input               iEN;
input               iSTART;
input   [IL-1:0]    iDATA;
output  [BL-1:0]    oDATA;

reg     [BL-1:0]    Buff;

always @ (posedge iCLK or posedge iRST)
begin
    if (iRST) begin
        Buff <= #1 0;
    end
    else if (iSTART) begin
        Buff <= #1 0;
    end
    else if (iEN) begin
        Buff <= #1 {iDATA, Buff[BL-1:IL]};
    end
    else    begin
        Buff <= #1 Buff;
    end
end

assign oDATA = Buff;

endmodule
