module tb_UART_TX;
    reg CLK, Reset;
    reg TxStart;
    reg [7:0] TxData;
    wire Tx, TxBusy;

    UART_TX u_tx (
        .CLK(CLK), .Reset(Reset),
        .TxStart(TxStart), .TxData(TxData),
        .Tx(Tx), .TxBusy(TxBusy)
    );

    always #5 CLK = ~CLK;

    // ---- UART 接收器 ----
    reg [7:0] rx_data;
    integer i;

    initial begin
        // 等起始位
        @(negedge Tx);
        // 等半个位周期
        #150;
        // 采 8 个数据位
        for (i = 0; i < 8; i = i + 1) begin
            rx_data[i] = Tx;
            #100;
        end
        // 此时是停止位
        $display("UART RX: %h", rx_data);
        $finish;
    end

    // ---- 发送测试 ----
    initial begin
        CLK = 0;
        Reset = 1;
        TxStart = 0;
        TxData = 8'h00;
        #20;
        Reset = 0;
        #20;

        TxData = 8'hA5;
        TxStart = 1;
        #10;
        TxStart = 0;
    end
endmodule