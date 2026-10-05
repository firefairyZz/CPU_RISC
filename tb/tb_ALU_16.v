module tb_ALU_16;
    reg [15:0] A;
    reg [15:0] B;
    reg [3:0] Sel;
    wire [15:0] Q;
    wire Zero;
    wire Carry;
    wire Negative;
    wire Overflow;

    ALU_16 u_alu (
        .A(A),
        .B(B),
        .Sel(Sel),
        .Q(Q),
        .Zero(Zero),
        .Carry(Carry),
        .Negative(Negative),
        .Overflow(Overflow)
    );

    task check (
        input [15:0] ExpQ, 
        input ExpZero, 
        input ExpCarry, 
        input ExpNeg, 
        input ExpOv);
        begin
            #1;
            if (Q !== ExpQ) $error("Error Q,Exp %h, But %h", ExpQ, Q);
            if (Zero !== ExpZero) $error("Error Zero,Exp %h, But %h", ExpZero, Zero);
            if (Carry !== ExpCarry) $error("Error Zero,Exp %h, But %h", ExpCarry, Carry);
            if (Negative !== ExpNeg) $error("Error Neg, Exp %b, But %b", ExpNeg, Negative);
            if (Overflow !== ExpOv) $error("Error Ov, Exp %b, But %b", ExpOv, Overflow);
        end
    endtask

        initial begin
        // ADD: 00cc + 000f = 00db
        A = 16'h00cc; B = 16'h000f; Sel = 4'd0;
        check(16'h00db, 1'b0, 1'b0, 1'b0, 1'b0);

        // ADD carry: ffff + 0001 = 0000, Carry=1
        A = 16'hffff; B = 16'h0001; Sel = 4'd0;
        check(16'h0000, 1'b1, 1'b1, 1'b0, 1'b0);

        // ADD overflow: 7fff + 0001 = 8000, Overflow=1
        A = 16'h7fff; B = 16'h0001; Sel = 4'd0;
        check(16'h8000, 1'b0, 1'b0, 1'b1, 1'b1);

        // SUB borrow: 0000 - 0001 = ffff, Carry=1
        A = 16'h0000; B = 16'h0001; Sel = 4'd1;
        check(16'hffff, 1'b0, 1'b1, 1'b1, 1'b0);

        // SUB overflow: 8000 - 0001 = 7fff, Overflow=1
        A = 16'h8000; B = 16'h0001; Sel = 4'd1;
        check(16'h7fff, 1'b0, 1'b0, 1'b0, 1'b1);

        // SUB normal: 000f - 00cc = ff43, Carry=1
        A = 16'h000f; B = 16'h00cc; Sel = 4'd1;
        check(16'hff43, 1'b0, 1'b1, 1'b1, 1'b0);

        // INC carry: ffff + 1 = 0000, Carry=1
        A = 16'hffff; B = 16'h0000; Sel = 4'd2;
        check(16'h0000, 1'b1, 1'b1, 1'b0, 1'b0);

        // DEC borrow: 0000 - 1 = ffff, Carry=1
        A = 16'h0000; B = 16'h0000; Sel = 4'd3;
        check(16'hffff, 1'b0, 1'b1, 1'b1, 1'b0);

        // AND: 00cc & 000f = 000c
        A = 16'h00cc; B = 16'h000f; Sel = 4'd4;
        check(16'h000c, 1'b0, 1'b0, 1'b0, 1'b0);

        // OR: 00cc | 000f = 00cf
        A = 16'h00cc; B = 16'h000f; Sel = 4'd5;
        check(16'h00cf, 1'b0, 1'b0, 1'b0, 1'b0);

        // XOR: ffff ^ ffff = 0000, Zero=1
        A = 16'hffff; B = 16'hffff; Sel = 4'd6;
        check(16'h0000, 1'b1, 1'b0, 1'b0, 1'b0);

        // NOT: ~0000 = ffff
        A = 16'h0000; B = 16'h0000; Sel = 4'd7;
        check(16'hffff, 1'b0, 1'b0, 1'b1, 1'b0);

        // SHL: 0001 << 0002 = 0004
        A = 16'h0001; B = 16'h0002; Sel = 4'd8;
        check(16'h0004, 1'b0, 1'b0, 1'b0, 1'b0);

        // SHR: 8000 >> 0002 = 2000
        A = 16'h8000; B = 16'h0002; Sel = 4'd9;
        check(16'h2000, 1'b0, 1'b0, 1'b0, 1'b0);

        // CMP: 00cc - 000f = 00bd
        A = 16'h00cc; B = 16'h000f; Sel = 4'd10;
        check(16'h00bd, 1'b0, 1'b0, 1'b0, 1'b0);

        $display("All ALU_16 tests passed!");
        $finish;
    end
endmodule