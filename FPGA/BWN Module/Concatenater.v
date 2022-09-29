`timescale 1 ns / 100 ps

module Concatenater(
    iCLK,
    iRST,
    iCLR,
    iEN,
    iSel,
    iDATA,
    oDATA
);

parameter IL = 154;
parameter OL = 48;

input               iCLK;
input               iRST;
input               iCLR;
input               iEN;    // oEND(1~47)   (BWN, BNN -> Concatenator)
input   [7:0]       iSel;   // 0~153
input   [IL-1:0]    iDATA;
output  [OL-1:0]    oDATA;

reg     [OL-1:0]    Buff [0:IL-1];  // Width:48 x HEIGHT:154

integer i;

always @ (posedge iCLK or posedge iRST)
begin
    if (iRST) begin
        for (i=0; i<IL; i=i+1) begin
            Buff[i] <= #1 0;
        end
    end
    else if (iCLR) begin
        for (i=0; i<IL; i=i+1) begin
            Buff[i] <= #1 0;
        end
    end
    else if (iEN) begin
        for (i=0; i<IL; i=i+1) begin
            Buff[i] <= #1 {iDATA[i], Buff[i][OL-1:1]};
        end
    end
    else    begin
        for (i=0; i<IL; i=i+1) begin
            Buff[i] <= #1 Buff[i];
        end
    end
end

assign oDATA = Buff[iSel];

// output
// genvar j;
// generate
//     for (j=0; j<48; j=j+1) begin : Concaten
//         assign oDATA[j] = Buff[j];
//     end
// endgenerate

endmodule