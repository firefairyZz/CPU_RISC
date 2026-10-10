module ControlUnit_16 (
    input [15:0] Instr,
    input Zero,
    output reg RegWE,
    output reg [3:0] RegWriteAddr,
    output reg [3:0] RegReadAddr1,
    output reg [3:0] RegReadAddr2,
    output reg [3:0] ALUSel,
    output reg PCLoad,
    output reg PCEn,
    output reg IREn,
    output reg RAMWE,
    output reg ImmSel,
    output reg FlagWE,
    output reg WriteBackSel
    
);
    localparam ADD    = 4'd0;
    localparam SUB    = 4'd1;
    localparam AND_OP = 4'd4;
    localparam OR_OP  = 4'd5;
    localparam XOR_OP = 4'd6;
    localparam SHL    = 4'd8;
    localparam SHR    = 4'd9;
    localparam CMP    = 4'd10;

    wire [3:0] Opcode = Instr[15:12];
    wire [3:0] Rd     = Instr[11:8];
    wire [3:0] Rs1    = Instr[7:4];
    wire [3:0] Rs2    = Instr[3:0];

    always @(*) begin
        RegWE        = 1'b0;
        RegWriteAddr = 4'd0;
        RegReadAddr1 = 4'd0;
        RegReadAddr2 = 4'd0;
        ALUSel       = ADD;
        PCLoad       = 1'b0;
        PCEn         = 1'b1;
        IREn         = 1'b1;
        RAMWE        = 1'b0;
        ImmSel       = 1'b0;
        FlagWE       = 1'b0;;
        WriteBackSel = 1'b0;

        case (Opcode)
            4'd0: begin  // ADD
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = ADD;
                FlagWE = 1'b1;
            end
            4'd1: begin  // SUB
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = SUB;
                FlagWE = 1'b1;
            end
            4'd2: begin  // AND
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = AND_OP;
                FlagWE = 1'b1;
            end
            4'd3: begin  // OR
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = OR_OP;
                FlagWE = 1'b1;
            end
            4'd4: begin  // XOR
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = XOR_OP;
                FlagWE = 1'b1;
            end
            4'd5: begin  // SHL
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = SHL;
                FlagWE = 1'b1;
            end
            4'd6: begin  // SHR
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = SHR;
                FlagWE = 1'b1;
            end
            4'd7: begin  // CMP
                RegWE = 1'b0;
                RegReadAddr1 = Rs1; RegReadAddr2 = Rs2;
                ALUSel = CMP;
                FlagWE = 1'b1;
            end
            4'd8: begin  // LOADI
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = 4'd0;
                ImmSel = 1'b1;
                ALUSel = ADD;
            end
            4'd9: begin  // ADDI
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rd;
                ImmSel = 1'b1;
                ALUSel = ADD;
                FlagWE = 1'b1;
            end
            4'd10: begin // SUBI
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rd;
                ImmSel = 1'b1;
                ALUSel = SUB;
                FlagWE = 1'b1;
            end
            4'd11: begin // HLT
                PCEn = 1'b0;
                IREn = 1'b0;
            end
            4'd12: begin // JMP
                PCLoad = 1'b1;
                PCEn = 1'b0;
            end
            4'd13: begin // JZ
                PCLoad = Zero;
                PCEn = ~Zero;
            end
            4'd14: begin // LOAD
                RegWE = 1'b1; RegWriteAddr = Rd;
                RegReadAddr1 = Rs1;
                WriteBackSel = 1'b1;
                ALUSel = ADD;
            end
            4'd15: begin // STORE
                RegReadAddr1 = Rd;
                RegReadAddr2 = Rs1;
                RAMWE = 1'b1;
            end
        endcase
    end
endmodule