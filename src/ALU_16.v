module ALU_16 (
    input [15:0] A,
    input [15:0] B,
    input [3:0] Sel,
    output reg [15:0] Q,
    output reg Zero,
    output reg Carry,
    output reg Negative,
    output reg Overflow

);
    localparam ADD = 4'd0;
    localparam SUB = 4'd1;
    localparam INC = 4'd2;
    localparam DEC = 4'd3;
    localparam AND_OP = 4'd4;
    localparam OR_OP  = 4'd5;
    localparam XOR_OP = 4'd6;
    localparam NOT_OP = 4'd7;
    localparam SHL    = 4'd8;
    localparam SHR    = 4'd9;
    localparam CMP    = 4'd10;

    always @(*) begin
        Carry = 1'b0;
        Overflow = 1'b0;
        Q = 16'h00;
        case (Sel)
        ADD:    {Carry, Q} = {1'b0, A} + {1'b0, B};
        SUB:    {Carry, Q} = {1'b0, A} - {1'b0, B};
        INC:    {Carry, Q} = {1'b0, A} + 17'd1;
        DEC:    {Carry, Q} = {1'b0, A} - 17'd1;
        AND_OP: Q = A & B;
        OR_OP:  Q = A | B;
        XOR_OP: Q = A ^ B;
        NOT_OP: Q = ~A;
        SHL:    Q = A << B;
        SHR:    Q = A >> B;
        CMP:    {Carry, Q} = {1'b0, A} - {1'b0, B};
        4'd11: Q = A;
        default: Q = 16'h00;
        endcase

        if (Sel == ADD) begin
            if (A[15] == B[15] && Q[15] != A[15])
                Overflow = 1'b1;
        end

        else if (Sel == SUB || Sel == CMP) begin
            if (A[15] != B[15] && Q[15] != A[15])
                Overflow = 1'b1;
        end

        else if (Sel == INC) begin
            if (A[15] == 1'b0 && Q[15] != A[15])
                Overflow = 1'b1;
        end

        else if (Sel == DEC) begin
            if (A[15] == 1'b1 && Q[15] != A[15])
                Overflow = 1'b1;
        end

        Zero = (Q == 16'h0000);
        Negative = Q[15];
    end
endmodule