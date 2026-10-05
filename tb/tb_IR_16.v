module tb_IR_16;
    reg CLK;
    reg Reset;
    reg En;
    reg [15:0] IR_In;
    wire [15:0] IR_Out;

    IR_16 u_IR_16(
        .CLK     (CLK     ),
        .Reset   (Reset   ),
        .En      (En      ),
        .IR_In   (IR_In   ),
        .IR_Out  (IR_Out  )
    );

    always #5 CLK = ~CLK;

    initial begin
        CLK = 0;
        Reset = 1;
        #10;
        Reset = 0;
        #1;
        if (IR_Out !== 16'h0000)
            $error("FAIL Reset: exp 0000, got %h", IR_Out);
        else
            $display("Reset OK!");

        // En=1，加载 1234
        En = 1;
        IR_In = 16'h1234;
        #10;
        #1;
        if (IR_Out !== 16'h1234)
            $error("FAIL Load 1234: exp 1234, got %h", IR_Out);
        else
            $display("Load 1234 OK!");

        // En=0，输入变了，但 IR 不应该更新
        En = 0;
        IR_In = 16'h5678;
        #10;
        #1;
        if (IR_Out !== 16'h1234)
            $error("FAIL Hold: exp 1234, got %h", IR_Out);
        else
            $display("Hold OK!");

        // En=1，加载 5678
        En = 1;
        IR_In = 16'h5678;
        #10;
        #1;
        if (IR_Out !== 16'h5678)
            $error("FAIL Load 5678: exp 5678, got %h", IR_Out);
        else
            $display("Load 5678 OK!");

        $display("All IR_16 tests passed!");
        $finish;
    end

endmodule