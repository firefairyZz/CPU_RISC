module Pipelined_CU (
    input [3:0] Opcode,
    input [1:0] CondMode,    // IF_ID_Instr[11:10]，条件跳转家族的子操作码
    input Zero,
    input Neg,
    output reg RegWE,
    output reg [3:0] ALUSel,
    output reg ImmSel,
    output reg MemRead,
    output reg MemWrite,
    output reg MemToReg,
    output reg PCLoad,
    output reg FlagWE
);
    always @(*) begin
        RegWE=0; ALUSel=4'd11; ImmSel=0; MemRead=0;
        MemWrite=0; MemToReg=0; PCLoad=0; FlagWE=0;
        case (Opcode)
            4'd0:  begin RegWE=1; ALUSel=4'd0;  FlagWE=1; end
            4'd1:  begin RegWE=1; ALUSel=4'd1;  FlagWE=1; end
            4'd2:  begin RegWE=1; ALUSel=4'd4;  FlagWE=1; end
            4'd3:  begin RegWE=1; ALUSel=4'd5;  FlagWE=1; end
            4'd4:  begin RegWE=1; ALUSel=4'd6;  FlagWE=1; end
            4'd5:  begin RegWE=1; ALUSel=4'd8;  FlagWE=1; end
            4'd6:  begin RegWE=1; ALUSel=4'd9;  FlagWE=1; end
            4'd7:  begin RegWE=0; ALUSel=4'd10; FlagWE=1; end
            4'd8:  begin RegWE=1; ALUSel=4'd0;  ImmSel=1; end
            4'd9:  begin RegWE=1; ALUSel=4'd0;  ImmSel=1; FlagWE=1; end
            4'd10: begin RegWE=1; ALUSel=4'd1;  ImmSel=1; FlagWE=1; end
            4'd11: begin end
            4'd12: begin PCLoad=1; end
            4'd13: begin
                case (CondMode)
                    2'b00:   PCLoad = Zero;    // JZ
                    2'b01:   PCLoad = Neg;     // JN
                    default: PCLoad = 1'b0;
                endcase
            end
            4'd14: begin RegWE=1; ALUSel=4'd11; MemRead=1; MemToReg=1; end
            4'd15: begin MemWrite=1; ALUSel=4'd11; end
        endcase
    end
endmodule