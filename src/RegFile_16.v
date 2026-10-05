module RegFile_16 (
    input CLK,
    input Reset,
    input WE,
    input [3:0] WriteAddr,
    input [15:0] WriteData,
    input [3:0] ReadAddr1,
    input [3:0] ReadAddr2,
    output [15:0] ReadData1,
    output [15:0] ReadData2
);
    reg [15:0] Regs [0:15];
    integer i;
    always @(negedge CLK)begin
        if (Reset) begin
            for (i = 0; i < 16; i = i + 1) Regs[i] <= 16'h0000;
        end

        else if (WE && WriteAddr != 4'd0) begin
            Regs[WriteAddr] <= WriteData;
        end

    end
    
    assign ReadData1 = Regs[ReadAddr1];
    assign ReadData2 = Regs[ReadAddr2];
endmodule