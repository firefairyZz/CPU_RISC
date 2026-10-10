module ROM_16 (
    input [15:0] Addr,
    output [15:0] Data
);
    reg [15:0] Mem [0:4095];
    initial $readmemh("program.mem", Mem);
    assign Data = Mem[Addr[11:0]];
endmodule