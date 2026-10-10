module UART_TX (
    input CLK,
    input Reset,
    input TxStart,
    input [7:0] TxData,
    output reg Tx,
    output reg TxBusy
);
    localparam BIT_PERIOD = 10;

    reg [3:0] tick;
    reg [3:0] bit_cnt;
    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [4:0] idle_cnt;

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    always @(posedge CLK) begin
        if (Reset) begin
            state <= IDLE;
            Tx <= 1'b1;
            TxBusy <= 1'b0;
            tick <= 4'd0;
            bit_cnt <= 4'd0;
            idle_cnt <= 5'd0;
        end else begin
            case (state)
                IDLE: begin
                    Tx <= 1'b1;
                    TxBusy <= 1'b0;
                    if (idle_cnt < 5'd20)
                        idle_cnt <= idle_cnt + 1'b1;
                    else if (TxStart) begin
                        idle_cnt <= 5'd0;
                        shift_reg <= TxData;
                        tick <= 4'd0;
                        bit_cnt <= 4'd0;
                        state <= START;
                        TxBusy <= 1'b1;
                    end
                end
                START: begin
                    Tx <= 1'b0;
                    if (tick == BIT_PERIOD) begin
                        tick <= 4'd0;
                        Tx <= shift_reg[0];
                        state <= DATA;
                    end else begin
                        tick <= tick + 1'b1;
                    end
                end
                DATA: begin
                    if (tick == BIT_PERIOD) begin
                        tick <= 4'd0;
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        bit_cnt <= bit_cnt + 1'b1;
                        if (bit_cnt == 4'd7) begin
                            Tx <= 1'b1;
                            state <= STOP;
                        end else begin
                            Tx <= shift_reg[1];
                        end
                    end else begin
                        tick <= tick + 1'b1;
                    end
                end
                STOP: begin
                    Tx <= 1'b1;
                    if (tick == BIT_PERIOD) begin
                        tick <= 4'd0;
                        state <= IDLE;
                        TxBusy <= 1'b0;
                    end else begin
                        tick <= tick + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule