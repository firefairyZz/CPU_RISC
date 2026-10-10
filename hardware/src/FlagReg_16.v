module FlagReg_16 (
    input CLK,
    input Reset,
    input En,
    input [3:0] FlagsIn,
    output reg [3:0] FlagsOut
);
    always @(negedge CLK) begin
        if (Reset)
            FlagsOut <= 4'b0000;
        else if (En)
            FlagsOut <= FlagsIn;
    end
endmodule