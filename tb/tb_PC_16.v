module tb_PC_16;
    reg CLK;
    reg Reset;
    reg Load;
    reg En;
    reg [15:0] LoadData;
    wire [15:0] PC;

    PC_16 u_PC_16(
        .CLK      	(CLK       ),
        .Reset    	(Reset     ),
        .Load     	(Load      ),
        .En       	(En        ),
        .LoadData 	(LoadData  ),
        .PC       	(PC        )
    );

    always #5 CLK = ~CLK;

    initial begin
        CLK = 0;
        Reset = 1;
        #10;
        Reset = 0;
        #1;
        if (PC !== 16'h0000)
            $error("FAIL Reset: exp 0000, got %h", PC);
        else
            $display("Reset OK!");

        // En=1，跑一个周期，PC 从 0 变 1
        En = 1;
        #10;
        #1;
        if (PC !== 16'h0001)
            $error("FAIL Count1: exp 0001, got %h", PC);
        else
            $display("01 OK!");

        // 再跑一个周期，PC 从 1 变 2
        #10;
        #1;
        if (PC !== 16'h0002)
            $error("FAIL Count2: exp 0002, got %h", PC);
        else
            $display("02 OK!");

        // 加载 0x8000
        En = 0;
        Load = 1;
        LoadData = 16'h8000;
        #10;
        Load = 0;
        #1;
        if (PC !== 16'h8000)
            $error("FAIL Load: exp 8000, got %h", PC);
        else
            $display("Load OK!");

        // 加载完再自增，PC 从 8000 变 8001
        En = 1;
        #10;
        #1;
        if (PC !== 16'h8001)
            $error("FAIL Count3: exp 8001, got %h", PC);
        else
            $display("8000+1 OK!");

        $finish;
    end
    

endmodule