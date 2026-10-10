module tb_UART_TX2;
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

    // ---- 接收器（跟 CPU 测试台里一样）----
    reg [3:0] rx_state;
    reg [7:0] rx_data;
    reg [3:0] rx_bit;
    reg [3:0] rx_tick;

    localparam RX_IDLE  = 4'd0;
    localparam RX_START = 4'd1;
    localparam RX_DATA  = 4'd2;
    localparam RX_STOP  = 4'd3;

    always @(posedge CLK) begin
        if (Reset) begin
            rx_state <= RX_IDLE;
            rx_tick  <= 4'd0;
            rx_bit   <= 4'd0;
        end else begin
            case (rx_state)
                RX_IDLE: begin
                    if (Tx == 1'b0) begin
                        rx_tick <= 4'd0;
                        rx_state <= RX_START;
                    end
                end
                RX_START: begin
                    if (rx_tick == 4'd6) begin
                        rx_tick <= 4'd0;
                        if (Tx == 1'b0) begin
                            rx_bit <= 4'd0;
                            rx_state <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_tick <= rx_tick + 1'b1;
                    end
                end
                RX_DATA: begin
                    if (rx_tick == 4'd9) begin
                        rx_tick <= 4'd0;
                        rx_data[rx_bit] <= Tx;
                        if (rx_bit == 4'd7)
                            rx_state <= RX_STOP;
                        else
                            rx_bit <= rx_bit + 1'b1;
                    end else begin
                        rx_tick <= rx_tick + 1'b1;
                    end
                end
                RX_STOP: begin
                    if (rx_tick == 4'd9) begin
                        rx_tick <= 4'd0;
                        $display("RX: %h", rx_data);
                        rx_state <= RX_IDLE;
                    end else begin
                        rx_tick <= rx_tick + 1'b1;
                    end
                end
            endcase
        end
    end

    // ---- 发一个字节 ----
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

        #2000;
        $display("Done");
        $finish;
    end

endmodule