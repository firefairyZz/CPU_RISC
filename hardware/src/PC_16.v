module PC_16 (
    input CLK,
    input Reset,
    input Load,
    input En,
    input [15:0] LoadData,
    output reg [15:0] PC
);
    always @(posedge CLK) begin
        if (Reset)
            PC <= 16'h0000;
        else if (Load)
            PC <= LoadData;
        else if (En)
            PC <= PC + 1;
    end
endmodule