module UART_RX (
    input CLK,
    input Reset,
    input Rx,
    input Ack,
    output reg [7:0] RxData,
    output reg RxValid,
    output reg RxBusy
);
    localparam BIT_PERIOD = 10;

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;
    reg [3:0] tick;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge CLK) begin
        if (Reset) begin
            state <= IDLE;
            tick <= 4'd0;
            bit_cnt <= 4'd0;
            RxData <= 8'h00;
            RxValid <= 1'b0;
            RxBusy <= 1'b0;
        end else begin
            if (Ack) RxValid <= 1'b0;
            case (state)
                IDLE: begin
                    RxBusy <= 1'b0;
                    if (Rx == 1'b0) begin
                        tick <= 4'd0;
                        state <= START;
                        RxBusy <= 1'b1;
                    end
                end

                START: begin
                    // 半位周期后确认起始位仍然是低
                    if (tick == 4'd5) begin
                        tick <= 4'd0;
                        if (Rx == 1'b0) begin
                            bit_cnt <= 4'd0;
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        tick <= tick + 1'b1;
                    end
                end

                DATA: begin
                    // 每个位周期采样一次，采样点在位中间
                    if (tick == 4'd9) begin
                        tick <= 4'd0;
                        shift_reg[bit_cnt] <= Rx;
                        if (bit_cnt == 4'd7) begin
                            state <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end else begin
                        tick <= tick + 1'b1;
                    end
                end

                STOP: begin
                    // 等停止位结束，输出接收到的数据
                    if (tick == 4'd9) begin
                        tick <= 4'd0;
                        RxData <= shift_reg;
                        RxValid <= 1'b1;
                        RxBusy <= 1'b0;
                        state <= IDLE;
                    end else begin
                        tick <= tick + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule