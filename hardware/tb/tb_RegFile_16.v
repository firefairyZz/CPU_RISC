module tb_RegFile_16;
    reg CLK;
    reg Reset;
    reg WE;
    reg [3:0] WriteAddr;
    reg [15:0] WriteData;
    reg [3:0] ReadAddr1;
    reg [3:0] ReadAddr2;
    wire [15:0] ReadData1;
    wire [15:0] ReadData2;

    integer errors;

    RegFile_16 u_RegFile_16(
        .CLK        (CLK        ),
        .Reset      (Reset      ),
        .WE         (WE         ),
        .WriteAddr  (WriteAddr  ),
        .WriteData  (WriteData  ),
        .ReadAddr1  (ReadAddr1  ),
        .ReadAddr2  (ReadAddr2  ),
        .ReadData1  (ReadData1  ),
        .ReadData2  (ReadData2  )
    );

    always #5 CLK = ~CLK;

    initial begin
        errors = 0;
        CLK = 0;
        Reset = 1;
        #10;
        Reset = 0;

        // Write R3 = 00aa
        WriteAddr = 4'd3;
        WriteData = 16'h00aa;
        WE = 1;
        #10;
        WE = 0;

        // Read R3
        ReadAddr1 = 4'd3;
        #1;
        if (ReadData1 !== 16'h00aa) begin
            $error("FAIL R3: exp 00aa, got %h", ReadData1);
            errors = errors + 1;
        end else begin
            $display("R3 write/read OK");
        end

        // ---- Test 1: dual read port ----
        WriteAddr = 4'd5; WriteData = 16'h0055; WE = 1;
        #10; WE = 0;

        WriteAddr = 4'd8; WriteData = 16'h0088; WE = 1;
        #10; WE = 0;

        ReadAddr1 = 4'd5; ReadAddr2 = 4'd8;
        #1;
        if (ReadData1 !== 16'h0055) begin
            $error("FAIL Dual read RD1: exp 0055, got %h", ReadData1);
            errors = errors + 1;
        end else if (ReadData2 !== 16'h0088) begin
            $error("FAIL Dual read RD2: exp 0088, got %h", ReadData2);
            errors = errors + 1;
        end else begin
            $display("Dual read port OK");
        end

        // ---- Test 2: Reset clear ----
        WriteAddr = 4'd5; WriteData = 16'h00aa; WE = 1;
        #10; WE = 0;

        Reset = 1;
        #10;
        Reset = 0;

        ReadAddr1 = 4'd5;
        #1;
        if (ReadData1 !== 16'h0000) begin
            $error("FAIL Reset: exp 0000, got %h", ReadData1);
            errors = errors + 1;
        end else begin
            $display("Reset clear OK");
        end

        // ---- Test 3: same-addr read/write ----
        WriteAddr = 4'd5; WriteData = 16'h00aa; WE = 1;
        #10; WE = 0;

        WriteAddr = 4'd5; WriteData = 16'h0055; WE = 1;
        ReadAddr1 = 4'd5;

        #1;
        if (ReadData1 !== 16'h00aa) begin
            $error("FAIL Same-addr old: exp 00aa, got %h", ReadData1);
            errors = errors + 1;
        end else begin
            $display("Same-addr old value OK");
        end

        #9;
        WE = 0;
        #1;
        if (ReadData1 !== 16'h0055) begin
            $error("FAIL Same-addr new: exp 0055, got %h", ReadData1);
            errors = errors + 1;
        end else begin
            $display("Same-addr new value OK");
        end

        if (errors == 0) begin
            $display("All RegFile_16 tests passed!");
        end else begin
            $display("FAILED: %0d errors", errors);
        end

        $finish;
    end

endmodule