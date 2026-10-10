# Software

C 虚拟机 + Win32 终端 + 汇编 CLI。

## 结构

- `vm.c` — 16 位 CPU 虚拟机
- `viewer.c` — Win32 终端窗口
- `shared.h` — 共享内存协议
- `program/` — CLI 源码（汇编）
- `tools/asm.py` — 汇编器

## 运行

\`\`\`
cd software
.\run.bat
\`\`\`

会编译所有东西，然后启动 vm.exe 和 viewer.exe。

## 命令

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

## 系统调用

程序通过 `CALL 0x340` 请求服务：

| 地址 | 服务 |
|------|------|
| 0x340 | putc (R1 = 字符) |
| 0x342 | puts (R1 = 字符串地址) |
| 0x345 | getc (返回 R1) |
| 0x349 | exit |

## 程序文件格式

裸机器码，每个字 16 位，小端字节序。加载到 RAM `0x800`。

## 开发

\`\`\`
py tools/asm.py a program/program.asm program.mem   # 汇编 CLI
py tools/asm.py b hello.asm hello.bin                # 汇编独立程序
\`\`\`