module IR_16 (
    input CLK,
    input Reset,
    input En,
    input [15:0] IR_In,
    output reg [15:0] IR_Out
    );
    always @(posedge CLK) begin
        if (Reset)
        IR_Out <= 16'h0000;
        else if (En)
        IR_Out <= IR_In;
    end

endmodule