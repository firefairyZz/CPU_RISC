.include "data.asm"

.text
        JMP main

main:   LOADI R7, -3
        LOADI R8, -2
        LOADI R9, -1

        LOADI R1, -4
        LOADI R2, 1
        STORE R1, R2

        LOADI R1, 62
        STORE R9, R1
        LOADI R1, 32
        STORE R9, R1

        LOADI R1, -4
        LOADI R2, 0
        STORE R1, R2

        CALL  read_line
        CALL  dispatch
        JMP   main

.include "lib.asm"
.include "readline.asm"
.include "dispatch.asm"
.include "cmds.asm"

; ===== 系统调用入口（固定地址 0x340）=====
.org 0x340
sys_putc:
        STORE R9, R1
        RET

sys_puts:
        CALL  print_string
        RET

sys_getc:
sysg_loop:
        LOAD  R2, R7
        CMP   R2, R0
        JZ    sysg_loop
        LOAD  R1, R8
        RET

sys_exit:
        JMP   R14