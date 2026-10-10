module FIFO_16 (
    input CLK,
    input Reset,
    input Wr,
    input [7:0] WrData,
    input Rd,
    output [7:0] RdData,
    output Empty,
    output Full
);
    reg [7:0] Mem [0:15];
    reg [3:0] WrPtr;
    reg [3:0] RdPtr;
    reg [4:0] Count;

    assign RdData = Mem[RdPtr];
    assign Empty = (Count == 5'd0);
    assign Full  = (Count == 5'd16);

    always @(posedge CLK) begin
        if (Reset) begin
            WrPtr <= 4'd0;
            RdPtr <= 4'd0;
            Count <= 5'd0;
        end else begin
            if (Wr && !Full) begin
                Mem[WrPtr] <= WrData;
                WrPtr <= WrPtr + 1'b1;
            end
            if (Rd && !Empty) begin
                RdPtr <= RdPtr + 1'b1;
            end

            if (Wr && !Full && Rd && !Empty)
                Count <= Count;
            else if (Wr && !Full)
                Count <= Count + 1'b1;
            else if (Rd && !Empty)
                Count <= Count - 1'b1;
        end
    end
endmodule