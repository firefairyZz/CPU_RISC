module Forwarding_Unit (
    input [3:0] Rs1_EX, Rs2_EX,
    input [3:0] Rd_MEM, input RegWE_MEM,
    input [3:0] Rd_WB,  input RegWE_WB,
    output reg [1:0] ForwardA, ForwardB
);
    always @(*) begin
        if (RegWE_MEM && Rd_MEM != 4'd0 && Rd_MEM == Rs1_EX)
            ForwardA = 2'b01;
        else if (RegWE_WB && Rd_WB != 4'd0 && Rd_WB == Rs1_EX)
            ForwardA = 2'b10;
        else
            ForwardA = 2'b00;

        if (RegWE_MEM && Rd_MEM != 4'd0 && Rd_MEM == Rs2_EX)
            ForwardB = 2'b01;
        else if (RegWE_WB && Rd_WB != 4'd0 && Rd_WB == Rs2_EX)
            ForwardB = 2'b10;
        else
            ForwardB = 2'b00;
    end
endmodule
