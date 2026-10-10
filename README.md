# CPU_RISC

一台从零手搓的 16 位 RISC CPU，带 5 级流水线、软件虚拟机、Win32 终端、汇编 CLI 和程序加载器。

硬件用 Verilog 写，软件用 C 和自研汇编写。整个项目不依赖任何现成的 CPU 或操作系统。

## 目录结构

```
.
├── hardware/        Verilog 硬件源码
│   ├── src/         CPU、ALU、RegFile、流水线、UART、FIFO
│   ├── tb/          每个模块的测试台
│   ├── filelist/    多文件编译列表
│   └── tools/       汇编器
└── software/        软件层
    ├── vm.c         C 语言的 16 位 CPU 虚拟机
    ├── viewer.c     Win32 终端窗口
    ├── shared.h     虚拟机与查看器的共享内存协议
    ├── program/     CLI 源码（拆分后的汇编）
    ├── tools/       汇编器
    └── run.bat      一键编译 + 运行
```

## 硬件

- **数据位宽**：16 位
- **指令位宽**：16 位定长
- **流水线**：5 级（IF / ID / EX / MEM / WB）
- **前递**：EX/MEM 和 MEM/WB 两级前递
- **冒险处理**：LOAD 后数据冒险用 stall
- **寄存器**：16 个通用寄存器，R0 恒为 0
- **栈**：256 层硬件栈，SP 从 0xFF 往下增长
- **存储**：4096 字 ROM，4096 字 RAM
- **外设**：GPIO、UART TX / RX、FIFO

### 指令集

19 条指令，6 种格式：

| 格式 | 操作码 | 指令 |
|------|--------|------|
| R 型 | 0000-0111 | ADD、SUB、AND、OR、XOR、SHL、SHR、CMP |
| I 型 | 1000-1010 | LOADI、ADDI、SUBI |
| 特殊 | 1011 | HLT |
| J 型 | 1100 | JMP / CALL / JMP R / RET（用 bit[11:10] 区分） |
| 条件跳转 | 1101 | JZ / JN（用 bit[11:10] 区分） |
| 访存 | 1110-1111 | LOAD、STORE |

详细编码见 `hardware/README.md`。

## 软件

软件层是硬件 CPU 的"操作系统"：

- **`vm.c`** — 用 C 语言重新实现了整个 CPU 的指令集。读 `program.mem`，从 ROM 取指，从 RAM 读写数据。ROM 区（`0x000-0x7FF`）执行 CLI，RAM 区（`0x800+`）执行加载的程序。
- **`viewer.c`** — 用 Win32 GDI 渲染一个终端窗口。通过共享内存读 CPU 写出的字符，支持颜色、滚动条、光标闪烁、增量渲染。
- **`shared.h`** — 屏幕和键盘的共享内存协议。
- **`program/`** — CLI 源码，用本项目的汇编器编写。包含命令分发、行编辑、参数解析、内存操作、蜂鸣器控制、程序加载。

### 支持的命令

| 命令 | 作用 |
|------|------|
| `help [cmd]` | 帮助 |
| `clear` | 清屏 |
| `echo <text>` | 回显 |
| `mem <addr>` | 读一个内存字 |
| `dump <addr>` | 读 16 个内存字 |
| `write <a> <v>` | 写内存 |
| `beep <freq>` | 发声 |
| `play` | 播放内置旋律 |
| `load <file>` | 加载程序到 0x800 |
| `run [addr]` | 执行程序 |

### 行编辑

- 退格：删一个字符
- `Ctrl+U`：清空当前行
- `Ctrl+C`：放弃当前行
- `Ctrl+L`：清屏

### 系统调用

独立程序通过 `CALL` 固定地址请求操作系统服务：

| 地址 | 服务 | 参数 |
|------|------|------|
| `0x340` | putc | R1 = 字符 |
| `0x342` | puts | R1 = 字符串地址 |
| `0x345` | getc | 返回 R1 |
| `0x349` | exit | R14 = 返回地址 |

程序不需要知道硬件端口在哪。改端口只改 CLI 一处。

### 程序文件格式

裸机器码，每个字 16 位，小端字节序。加载到 RAM `0x800`，用 `JMP R14` 返回 CLI。

## 运行

需要：

- **MinGW-w64**（gcc）
- **Python 3**（跑汇编器）
- **Windows 10/11**

```
cd software
.\run.bat
```

`run.bat` 会：

1. 用汇编器编译 CLI（`program/program.asm` → `program.mem`）
2. 编译测试程序（`hello.asm` → `hello.bin`）
3. 编译 `vm.c` → `vm.exe`
4. 编译 `viewer.c` → `viewer.exe`
5. 启动两个程序

`vm.exe` 是虚拟机，跑 CPU 逻辑。`viewer.exe` 是终端窗口，显示 CPU 的输出、接收键盘输入。

命令在**窗口**里输入，不在 `vm.exe` 的控制台里。

## 汇编器

`software/tools/asm.py` 支持：

- 标签：`main:` / `loop:` / `done:`
- 数据段：`.data 0x20` / `.text`
- 字符串：`.string "hello\n"`
- 数据：`.word 0x106, 0x106`
- 包含：`.include "lib.asm"`
- 定位：`.org 0x340`
- 二进制输出：`asm.py b hello.asm hello.bin`

用法：

```
py tools/asm.py a program/program.asm program.mem   # 汇编成文本格式
py tools/asm.py b hello.asm hello.bin                # 汇编成二进制
py tools/asm.py d program.mem                        # 反汇编
```

## 开发历程

从 Logisim 手搓 CPU 开始，踩过时序竞争、两相时钟、门控时钟毛刺、幽灵数据。转 Verilog 后从 ALU 起步，逐步搭出 RegFile、PC、IR、控制单元、单周期 CPU、5 级流水线、前递、冒险检测。然后加 UART、FIFO、GPIO，再写 C 虚拟机、Win32 终端、汇编器、CLI、程序加载器和系统调用。

中间踩的坑包括：`=` 和 `==` 不分、悬空 else、锁存器、位宽不匹配、先用后声明、符号扩展、流水线数据冒险、UART 采样点偏移、共享内存竞态、`LOADI` 地址截断。

每一步都单独写过测试台，用自动比对替代肉眼检查。

## 限制

- **UART 输出在仿真里偶尔错位。** iverilog 的时序精度问题，真实硬件上不存在。调试建议用 GPIO 输出。
- **没有中断。** CPU 只能轮询。
- **没有磁盘文件系统。** 程序通过 `vm.c` 直接读宿主文件。
- **RAM 只有 4K。** 复杂程序会撞上限。
- **`CALL` 只能跳 10 位地址（0x000-0x3FF）。** 系统调用入口必须在这范围内。

## License

MIT