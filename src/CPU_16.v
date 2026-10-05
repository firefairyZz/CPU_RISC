module CPU_16 (
    input CLK, Reset,
    input UART_Rx,
    output [15:0] GPIO_Out, output GPIO_Valid,
    output UART_Tx, output UART_Busy
);

    // ============================================
    // 第一部分：所有 reg 声明
    // ============================================
    reg [7:0]  SP;
    reg [15:0] StackMem [0:255];

    reg [15:0] IF_ID_PC, IF_ID_Instr;
    reg [15:0] ID_EX_Ctl, ID_EX_Addr;
    reg [15:0] ID_EX_Data1, ID_EX_Data2, ID_EX_Imm;
    reg [15:0] EX_MEM_Ctl, EX_MEM_Addr, EX_MEM_ALU, EX_MEM_Data2;
    reg [15:0] MEM_WB_Ctl, MEM_WB_ALU, MEM_WB_RAM;
    reg [15:0] PC_Out;
    reg halted;

    reg [15:0] RAM [0:4095];

    reg [15:0] GPIO_Out_r;
    reg GPIO_Valid_r;
    reg fifo_wr;
    reg [7:0]  fifo_wdata;
    reg fifo_rd;
    reg UART_Start;
    reg [7:0]  UART_TxData_r;
    reg just_launched;

    // ============================================
    // 第二部分：所有 wire 声明（模块输出）
    // ============================================
    wire [15:0] ROM_Out;
    wire [15:0] ALU_Q;
    wire ALU_Zero, ALU_Carry, ALU_Neg, ALU_Ov;
    wire [3:0]  Flags;
    wire [15:0] RegData1, RegData2;
    wire [15:0] RAM_Out;
    wire [7:0]  UART_RxData;
    wire UART_RxValid;
    wire fifo_empty;
    wire [7:0]  fifo_rdata;

    // 控制单元输出
    wire ID_RegWE, ID_ImmSel, ID_MemRead, ID_MemWrite, ID_MemToReg, ID_PCLoad, ID_FlagWE;
    wire [3:0] ID_ALUSel;

    // 前递单元输出
    wire [1:0] ForwardA, ForwardB;

    // ============================================
    // 第三部分：所有 wire 声明（组合逻辑）
    // ============================================
    wire [15:0] PC_Plus1;
    wire [3:0]  Op_id, Rd_id, Rs1_id, Rs2_id;
    wire ID_HLT;
    wire [1:0]  jmp_mode;
    wire is_jmp_direct, is_call, is_jmp_indirect, is_ret;
    wire [3:0]  Ra1, Ra2;
    wire [15:0] ImmExt;
    wire [15:0] ID_Ctl, ID_Addr;
    wire [3:0]  ID_JmpReg;
    wire ID_JmpHazard_EX, ID_JmpHazard_MEM, ID_JmpHazard_WB;
    wire [15:0] ID_JmpData;
    wire [15:0] PCLoadTarget;
    wire [15:0] WB_Data, WB_Data_F;
    wire WB_RegWE, WB_MemToReg;
    wire [3:0]  WB_Addr;
    wire MEM_MemWrite, MEM_IsLoad;
    wire [11:0] MEM_Addr;
    wire [15:0] MEM_In;
    wire is_uart_data, is_uart_stat, rx_ack, is_gpio;
    wire [15:0] UART_RxData_16, UART_RxValid_16;
    wire [3:0]  EX_Rs1, EX_Rs2, MEM_Rd_F, WB_Rd_F;
    wire MEM_RegWE_F, WB_RegWE_F;
    wire [3:0]  EX_ALUSel;
    wire EX_ImmSel;
    wire [11:0] EX_MEM_Addr_F;
    wire [15:0] EX_MEM_FwdData;
    wire [15:0] EX_A_mux, EX_Data2_mux, EX_B;
    wire [3:0]  MEM_Rd_Ld;
    wire MEM_RegWE_Ld;
    wire stall;
    wire is_I_type;

    // ============================================
    // 第四部分：RAM 初始化
    // ============================================
    initial begin
        RAM[0]=16'h0005; RAM[1]=16'h0003; RAM[2]=16'h0008; RAM[3]=16'h0001;
        RAM[4]=16'h0009; RAM[5]=16'h0002; RAM[6]=16'h0007; RAM[7]=16'h0004;
    end

    // ============================================
    // 第五部分：组合逻辑赋值
    // ============================================
    assign PC_Plus1 = PC_Out + 1;

    assign Op_id  = IF_ID_Instr[15:12];
    assign Rd_id  = IF_ID_Instr[11:8];
    assign Rs1_id = IF_ID_Instr[7:4];
    assign Rs2_id = IF_ID_Instr[3:0];
    assign ID_HLT = (Op_id == 4'd11);

    assign jmp_mode = IF_ID_Instr[11:10];
    assign is_jmp_direct   = (Op_id == 4'd12) && (jmp_mode == 2'b00);
    assign is_call         = (Op_id == 4'd12) && (jmp_mode == 2'b01);
    assign is_jmp_indirect = (Op_id == 4'd12) && (jmp_mode == 2'b10);
    assign is_ret          = (Op_id == 4'd12) && (jmp_mode == 2'b11);

    assign is_I_type = (Op_id >= 4'd8 && Op_id <= 4'd10);
    assign Ra1 = (Op_id == 4'd15) ? Rd_id  :
                 (Op_id == 4'd8)  ? 4'd0   :
                 is_I_type        ? Rd_id  :
                 Rs1_id;
    assign Ra2 = (Op_id == 4'd15) ? Rs1_id : Rs2_id;

    assign ImmExt = {{8{IF_ID_Instr[7]}}, IF_ID_Instr[7:0]};

    assign ID_Ctl  = {1'b0, Rd_id, ID_ALUSel, ID_FlagWE, ID_PCLoad,
                      ID_MemToReg, ID_MemWrite, ID_MemRead, ID_ImmSel, ID_RegWE};
    assign ID_Addr = {4'b0, Ra2, Ra1, Rd_id};

    // ID 阶段前递（间接跳转）
    assign ID_JmpReg = IF_ID_Instr[7:4];
    assign ID_JmpHazard_EX  = ID_EX_Ctl[0]  && ID_EX_Addr[3:0]   != 4'd0 && ID_EX_Addr[3:0]   == ID_JmpReg;
    assign ID_JmpHazard_MEM = EX_MEM_Ctl[0] && EX_MEM_Addr[3:0]  != 4'd0 && EX_MEM_Addr[3:0]  == ID_JmpReg;
    assign ID_JmpHazard_WB  = MEM_WB_Ctl[0] && MEM_WB_Ctl[14:11] != 4'd0 && MEM_WB_Ctl[14:11] == ID_JmpReg;

    assign ID_JmpData =
        ID_JmpHazard_EX  ? ALU_Q      :
        ID_JmpHazard_MEM ? EX_MEM_ALU :
        ID_JmpHazard_WB  ? WB_Data    :
        RegData1;

    assign PCLoadTarget =
        is_ret          ? StackMem[SP] :
        is_jmp_indirect ? ID_JmpData :
        {6'b0, IF_ID_Instr[9:0]};

    // WB 阶段
    assign WB_RegWE    = MEM_WB_Ctl[0];
    assign WB_MemToReg = MEM_WB_Ctl[4];
    assign WB_Addr     = MEM_WB_Ctl[14:11];
    assign WB_Data     = WB_MemToReg ? MEM_WB_RAM : MEM_WB_ALU;
    assign WB_Data_F   = MEM_WB_Ctl[4] ? MEM_WB_RAM : MEM_WB_ALU;

    // MEM 阶段
    assign MEM_MemWrite = EX_MEM_Ctl[3];
    assign MEM_Addr     = EX_MEM_ALU[11:0];
    assign MEM_In       = EX_MEM_Data2;
    assign MEM_IsLoad   = EX_MEM_Ctl[4];
    assign is_gpio      = (MEM_Addr == 12'hFFF);
    assign is_uart_data = (MEM_Addr == 12'hFFE);
    assign is_uart_stat = (MEM_Addr == 12'hFFD);
    assign rx_ack       = is_uart_data && MEM_IsLoad;
    assign UART_RxData_16  = {8'h00, UART_RxData};
    assign UART_RxValid_16 = {15'b0, UART_RxValid};

    assign RAM_Out = is_uart_data ? UART_RxData_16 :
                     is_uart_stat ? UART_RxValid_16 :
                     RAM[MEM_Addr];

    // Forwarding
    assign EX_Rs1     = ID_EX_Addr[7:4];
    assign EX_Rs2     = ID_EX_Addr[11:8];
    assign MEM_Rd_F   = EX_MEM_Addr[3:0];
    assign MEM_RegWE_F = EX_MEM_Ctl[0];
    assign WB_Rd_F    = MEM_WB_Ctl[14:11];
    assign WB_RegWE_F = MEM_WB_Ctl[0];

    // EX 阶段
    assign EX_ALUSel = ID_EX_Ctl[10:7];
    assign EX_ImmSel = ID_EX_Ctl[1];

    assign EX_MEM_Addr_F = EX_MEM_ALU[11:0];
    assign EX_MEM_FwdData =
        EX_MEM_Ctl[4] ?
            ((EX_MEM_Addr_F == 12'hFFE) ? UART_RxData_16  :
             (EX_MEM_Addr_F == 12'hFFD) ? UART_RxValid_16 :
             (EX_MEM_Addr_F == 12'hFFF) ? 16'h0000 :
             RAM[EX_MEM_Addr_F]) :
        EX_MEM_ALU;

    assign EX_A_mux = (ForwardA == 2'b01) ? EX_MEM_FwdData :
                      (ForwardA == 2'b10) ? WB_Data_F :
                      ID_EX_Data1;

    assign EX_Data2_mux = (ForwardB == 2'b01) ? EX_MEM_FwdData :
                          (ForwardB == 2'b10) ? WB_Data_F :
                          ID_EX_Data2;

    assign EX_B = EX_ImmSel ? ID_EX_Imm : EX_Data2_mux;

    // Stall
    assign MEM_Rd_Ld   = EX_MEM_Addr[3:0];
    assign MEM_RegWE_Ld = EX_MEM_Ctl[0];
    assign stall = MEM_RegWE_Ld && MEM_IsLoad &&
                   MEM_Rd_Ld != 4'd0 &&
                   (MEM_Rd_Ld == Ra1 || MEM_Rd_Ld == Ra2);

    // ============================================
    // 第六部分：always 块
    // ============================================

    // halted
    always @(posedge CLK) begin
        if (Reset) halted <= 1'b0;
        else if (ID_HLT) halted <= 1'b1;
    end

    // SP 更新
    always @(posedge CLK) begin
        if (Reset) begin
            SP <= 8'hFF;
        end else if (is_call && !stall && !halted) begin
            StackMem[SP - 1] <= IF_ID_PC;
            SP <= SP - 1;
        end else if (is_ret && !stall && !halted) begin
            SP <= SP + 1;
        end
    end

    // PC
    always @(posedge CLK) begin
        if (Reset) PC_Out <= 16'h0000;
        else if (stall || halted) PC_Out <= PC_Out;
        else if (ID_PCLoad) PC_Out <= PCLoadTarget;
        else PC_Out <= PC_Plus1;
    end

    // IF/ID
    always @(posedge CLK) begin
        if (Reset || (ID_PCLoad && !stall)) begin
            IF_ID_PC <= 16'h0000;
            IF_ID_Instr <= 16'h0000;
        end else if (!stall && !halted) begin
            IF_ID_PC <= PC_Plus1;
            IF_ID_Instr <= ROM_Out;
        end
    end

    // ID/EX
    always @(posedge CLK) begin
        if (Reset || (ID_PCLoad && !stall) || halted) begin
            ID_EX_Ctl   <= 16'h0000;
            ID_EX_Addr  <= 16'h0000;
            ID_EX_Data1 <= 16'h0000;
            ID_EX_Data2 <= 16'h0000;
            ID_EX_Imm   <= 16'h0000;
        end else if (!stall) begin
            ID_EX_Ctl   <= ID_Ctl;
            ID_EX_Addr  <= ID_Addr;
            ID_EX_Data1 <= RegData1;
            ID_EX_Data2 <= RegData2;
            ID_EX_Imm   <= ImmExt;
        end
    end

    // EX/MEM
    always @(posedge CLK) begin
        if (Reset) begin
            EX_MEM_Ctl <= 0; EX_MEM_Addr <= 0;
            EX_MEM_ALU <= 0; EX_MEM_Data2 <= 0;
        end else begin
            EX_MEM_Ctl   <= ID_EX_Ctl;
            EX_MEM_Addr  <= ID_EX_Addr;
            EX_MEM_ALU   <= ALU_Q;
            EX_MEM_Data2 <= EX_Data2_mux;
        end
    end

    // MEM/WB
    always @(posedge CLK) begin
        if (Reset) begin
            MEM_WB_Ctl <= 0; MEM_WB_ALU <= 0; MEM_WB_RAM <= 0;
        end else begin
            MEM_WB_Ctl <= EX_MEM_Ctl;
            MEM_WB_ALU <= EX_MEM_ALU;
            MEM_WB_RAM <= RAM_Out;
        end
    end

    // RAM 写
    always @(posedge CLK) begin
        if (MEM_MemWrite && !is_gpio && !is_uart_data && !is_uart_stat)
            RAM[MEM_Addr] <= MEM_In;
    end

    // GPIO
    always @(posedge CLK) begin
        GPIO_Valid_r <= 1'b0;
        fifo_wr <= 1'b0;
        if (MEM_MemWrite && is_gpio) begin
            GPIO_Out_r <= MEM_In;
            GPIO_Valid_r <= 1'b1;
            fifo_wr <= 1'b1;
            fifo_wdata <= MEM_In[7:0];
        end
    end
    assign GPIO_Out = GPIO_Out_r;
    assign GPIO_Valid = GPIO_Valid_r;

    // FIFO + UART TX
    always @(posedge CLK) begin
        UART_Start <= 1'b0;
        fifo_rd <= 1'b0;
        if (Reset) just_launched <= 1'b0;
        else if (just_launched) just_launched <= 1'b0;
        else if (!fifo_empty && !UART_Busy) begin
            UART_TxData_r <= fifo_rdata;
            fifo_rd <= 1'b1;
            UART_Start <= 1'b1;
            just_launched <= 1'b1;
        end
    end

    // ============================================
    // 第七部分：模块例化
    // ============================================

    Pipelined_CU u_CU (
        .Opcode(Op_id), .Zero(Flags[0]),
        .RegWE(ID_RegWE), .ALUSel(ID_ALUSel), .ImmSel(ID_ImmSel),
        .MemRead(ID_MemRead), .MemWrite(ID_MemWrite), .MemToReg(ID_MemToReg),
        .PCLoad(ID_PCLoad), .FlagWE(ID_FlagWE)
    );

    RegFile_16 u_RegFile (
        .CLK(CLK), .Reset(Reset),
        .WE(WB_RegWE), .WriteAddr(WB_Addr), .WriteData(WB_Data),
        .ReadAddr1(Ra1), .ReadAddr2(Ra2),
        .ReadData1(RegData1), .ReadData2(RegData2)
    );

    ALU_16 u_ALU (
        .A(EX_A_mux), .B(EX_B), .Sel(EX_ALUSel),
        .Q(ALU_Q), .Zero(ALU_Zero), .Carry(ALU_Carry),
        .Negative(ALU_Neg), .Overflow(ALU_Ov)
    );

    FlagReg_16 u_FlagReg (
        .CLK(CLK), .Reset(Reset), .En(ID_EX_Ctl[6]),
        .FlagsIn({ALU_Ov, ALU_Neg, ALU_Carry, ALU_Zero}),
        .FlagsOut(Flags)
    );

    Forwarding_Unit u_Fwd (
        .Rs1_EX(EX_Rs1), .Rs2_EX(EX_Rs2),
        .Rd_MEM(MEM_Rd_F), .RegWE_MEM(MEM_RegWE_F),
        .Rd_WB(WB_Rd_F), .RegWE_WB(WB_RegWE_F),
        .ForwardA(ForwardA), .ForwardB(ForwardB)
    );

    ROM_16 u_ROM (.Addr(PC_Out), .Data(ROM_Out));

    FIFO_16 u_FIFO (
        .CLK(CLK), .Reset(Reset),
        .Wr(fifo_wr), .WrData(fifo_wdata),
        .Rd(fifo_rd), .RdData(fifo_rdata),
        .Empty(fifo_empty), .Full()
    );

    UART_RX u_UART_RX (
        .CLK(CLK), .Reset(Reset),
        .Rx(UART_Rx),
        .RxData(UART_RxData),
        .RxValid(UART_RxValid),
        .RxBusy(),
        .Ack(rx_ack)
    );

    UART_TX u_UART (
        .CLK(CLK), .Reset(Reset),
        .TxStart(UART_Start), .TxData(UART_TxData_r),
        .Tx(UART_Tx), .TxBusy(UART_Busy)
    );

endmodule