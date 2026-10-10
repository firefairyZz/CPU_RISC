module tb_CPU_16;
    reg CLK, Reset;
    reg UART_Rx;
    wire [15:0] GPIO_Out;
    wire GPIO_Valid;
    wire UART_Tx;
    wire UART_Busy;

    CPU_16 u_CPU (
        .CLK(CLK),
        .Reset(Reset),
        .GPIO_Out(GPIO_Out),
        .GPIO_Valid(GPIO_Valid),
        .UART_Tx(UART_Tx),
        .UART_Busy(UART_Busy),
        .UART_Rx(UART_Rx)
    );

    always #5 CLK = ~CLK;

    always @(posedge CLK) begin
        if (GPIO_Valid)
            $write("%c", GPIO_Out[7:0]);
    end

    // ---- UART 接收器（基于 CLK 采样）----
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
                    if (UART_Tx == 1'b0) begin
                        rx_tick <= 4'd0;
                        rx_state <= RX_START;
                    end
                end

                RX_START: begin
                    if (rx_tick == 4'd6) begin
                        rx_tick <= 4'd0;
                        if (UART_Tx == 1'b0) begin
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
                        rx_data[rx_bit] <= UART_Tx;
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
                        rx_state <= RX_IDLE;
                    end else begin
                        rx_tick <= rx_tick + 1'b1;
                    end
                end
            endcase
        end
    end

    task send_byte;
        input [7:0] data;
        integer k;
        begin
            UART_Rx = 0; #100;
            for (k = 0; k < 8; k = k + 1) begin
                UART_Rx = data[k]; #100;
            end
            UART_Rx = 1; #600;
        end
    endtask

    // ---- 主流程 ----
    initial begin
        CLK = 0;
        Reset = 1;
        UART_Rx = 1;
        #10;
        Reset = 0;
        #200;

        send_byte(8'h68);  // h
        send_byte(8'h65);  // e
        send_byte(8'h6C);  // l
        send_byte(8'h70);  // p
        send_byte(8'h0D);  // \r —— help

        send_byte(8'h78);  // x
        send_byte(8'h0D);  // \r —— 未知命令 x

        #20000;
        $display("Done");
        $finish;
    end
    
endmodule