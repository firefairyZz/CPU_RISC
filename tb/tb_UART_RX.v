module tb_UART_RX;
    reg CLK, Reset;
    reg Rx;
    wire [7:0] RxData;
    wire RxValid;
    wire RxBusy;

    UART_RX u_rx (
        .CLK(CLK), .Reset(Reset),
        .Rx(Rx),
        .RxData(RxData),
        .RxValid(RxValid),
        .RxBusy(RxBusy)
    );

    always #5 CLK = ~CLK;

    // 打印接收到的数据
    always @(posedge CLK) begin
        if (RxValid)
            $display("RX: %h", RxData);
    end

    // 手动发一个字节 A5（LSB 优先）
    // 位顺序：start=0, b0=1, b1=0, b2=1, b3=0, b4=0, b5=1, b6=0, b7=1, stop=1
    initial begin
        CLK = 0;
        Reset = 1;
        Rx = 1;
        #20;
        Reset = 0;
        #20;

        // 起始位
        Rx = 0; #100;

        // bit0 = 1
        Rx = 1; #100;
        // bit1 = 0
        Rx = 0; #100;
        // bit2 = 1
        Rx = 1; #100;
        // bit3 = 0
        Rx = 0; #100;
        // bit4 = 0
        Rx = 0; #100;
        // bit5 = 1
        Rx = 1; #100;
        // bit6 = 0
        Rx = 0; #100;
        // bit7 = 1
        Rx = 1; #100;

        // 停止位
        Rx = 1; #200;

        $finish;
    end
endmodule