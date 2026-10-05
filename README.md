# 16 位 RISC CPU

一台从零手写的 16 位 CPU。5 级流水线，自定义 RISC 指令集，带 UART 命令行系统。

用 Verilog 写硬件，用 Python 写汇编器，用汇编写软件。

## 架构

- **数据位宽**：16 位
- **指令位宽**：16 位定长
- **寄存器**：16 个通用寄存器（R0 恒为 0）
- **流水线**：5 级（IF / ID / EX / MEM / WB）
- **前递**：EX/MEM 和 MEM/WB 两级前递，LOAD 冒险用 stall 处理
- **栈**：256 层硬件栈，SP 从 0xFF 往下增长
- **ROM**：4096 条指令
- **RAM**：4096 字节

## 指令集

### R 型：`[op 4][Rd 4][Rs1 4][Rs2 4]`

| 操作码 | 助记符 | 操作 |
|--------|--------|------|
| 0000 | ADD | Rd = Rs1 + Rs2 |
| 0001 | SUB | Rd = Rs1 - Rs2 |
| 0010 | AND | Rd = Rs1 & Rs2 |
| 0011 | OR  | Rd = Rs1 \| Rs2 |
| 0100 | XOR | Rd = Rs1 ^ Rs2 |
| 0101 | SHL | Rd = Rs1 << Rs2 |
| 0110 | SHR | Rd = Rs1 >> Rs2 |
| 0111 | CMP | 只更新标志位 |

### I 型：`[op 4][Rd 4][imm8]`

| 操作码 | 助记符 | 操作 |
|--------|--------|------|
| 1000 | LOADI | Rd = 符号扩展(imm8) |
| 1001 | ADDI  | Rd = Rd + 符号扩展(imm8) |
| 1010 | SUBI  | Rd = Rd - 符号扩展(imm8) |

### 特殊

| 操作码 | 助记符 | 操作 |
|--------|--------|------|
| 1011 | HLT | 永久停机 |

### J 型：`[1100][子模式 2][地址 10 或 12]`

| 子模式 | 助记符 | 操作 |
|--------|--------|------|
| 00 | JMP addr | PC = addr（10 位） |
| 01 | CALL addr | 压栈，PC = addr（10 位） |
| 10 | JMP Rn | PC = Rn |
| 11 | RET | 弹栈，PC = 返回地址 |

### 条件跳转

| 操作码 | 助记符 | 操作 |
|--------|--------|------|
| 1101 | JZ addr | Zero=1 时 PC = addr（12 位） |

### 访存：`[op 4][Rd 4][Rs1 4][0000]`

| 操作码 | 助记符 | 操作 |
|--------|--------|------|
| 1110 | LOAD  | Rd = Mem[Rs1] |
| 1111 | STORE | Mem[Rd] = Rs1 |

## 内存映射

| 地址 | 用途 |
|------|------|
| 0x000 - 0xEFF | 通用 RAM |
| 0xFFD | UART 状态（读） |
| 0xFFE | UART 数据（读） |
| 0xFFF | GPIO / UART TX（写） |

## 模块清单

### 硬件（`src/`）

| 文件 | 作用 |
|------|------|
| `CPU_16.v` | 顶层，连接所有模块 |
| `ALU_16.v` | 算术逻辑单元，12 种运算 + 4 个标志位 |
| `RegFile_16.v` | 16 个 16 位寄存器，2 读 1 写 |
| `PC_16.v` | 程序计数器 |
| `IR_16.v` | 指令寄存器 |
| `FlagReg_16.v` | 标志寄存器 |
| `ControlUnit_16.v` | 控制单元（单周期版） |
| `Pipelined_CU.v` | 控制单元（流水线版） |
| `Forwarding_Unit.v` | 前递单元 |
| `ROM_16.v` | 4096 条指令的 ROM，从 program.mem 加载 |
| `FIFO_16.v` | 16 字节环形缓冲，隔离 UART 和 CPU |
| `UART_TX.v` | 串口发送 |
| `UART_RX.v` | 串口接收 |

### 测试台（`tb/`）

每个模块都有独立测试台，用 filelist 分别编译。

### 工具（`tools/`）

| 文件 | 作用 |
|------|------|
| `asm.py` | 汇编器 / 反汇编器，支持标签 |

## 汇编器用法

```bash
# 汇编
python tools/asm.py a program.asm program.mem

# 反汇编
python tools/asm.py d program.mem
```

汇编器支持标签：

```asm
        LOADI R1, 10
loop:   ADDI R1, -1
        CMP  R1, R0
        JZ   done
        JMP  loop
done:   HLT
```

## 编译和仿真

项目用 filelist 管理多文件编译。

```bash
# 编译 CPU
iverilog -g2012 -o sim.out -f filelist/filelist_cpu.f

# 运行仿真
vvp sim.out
```

换测试目标时，改 `filelist/filelist_cpu.f` 里的文件名，或者建新的 filelist。

## 示例程序

`test_cli2.asm` 是一个完整的命令行系统：

```asm
main:   CALL read_line     ; 读一行到缓冲区
        CALL dispatch      ; 解析并分发命令
        JMP  main

read_line:  ; 轮询 UART，存进缓冲区，支持退格
dispatch:   ; 逐字符对比命令表
cmd_help:   ; 输出 "help: help, clear"
cmd_clear:  ; 输出 10 个换行
cmd_echo:   ; 输出参数
```

运行效果：

```
> help
help: help, clear
> echo Hello
Hello
> x
?
> 
```

## 已知限制

- **UART 输出在仿真里偶尔错位。** 这是 iverilog 的时序精度问题，不是 CPU 逻辑错误。真实硬件上 UART 有标准波特率，不会出现。调试时建议用 GPIO 输出，不经过串行化。
- **LOAD 之后立刻用结果，会 stall 一拍。** 前递单元无法处理 LOAD 结果（数据在 MEM 阶段才从内存出来），只能等。
- **没有中断。** CPU 只能轮询。加中断需要额外的硬件设计。
- **指令空间已满。** 16 个操作码全用完了。加新指令需要转义前缀。