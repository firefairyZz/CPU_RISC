        ; ===== 初始化 =====
        LOADI R7, -3
        LOADI R8, -2
        LOADI R9, -1

main:   LOADI R1, 62
        STORE R9, R1
        LOADI R1, 32
        STORE R9, R1

        CALL  read_line
        CALL  dispatch
        JMP   main

; ===== read_line =====
read_line:
        LOADI R6, 16
        LOADI R5, 0

rl_loop:
        LOAD  R1, R7
        CMP   R1, R0
        JZ    rl_loop

        LOAD  R2, R8
        STORE R9, R2

        LOADI R3, 13
        CMP   R2, R3
        JZ    rl_done

        LOADI R3, 8
        CMP   R2, R3
        JZ    rl_back

        STORE R6, R2
        ADDI  R6, 1
        ADDI  R5, 1
        JMP   rl_loop

rl_back:
        CMP   R5, R0
        JZ    rl_loop
        ADDI  R6, -1
        ADDI  R5, -1
        LOADI R3, 8
        STORE R9, R3
        LOADI R3, 32
        STORE R9, R3
        LOADI R3, 8
        STORE R9, R3
        JMP   rl_loop

rl_done:
        LOADI R3, 0
        STORE R6, R3
        LOADI R3, 10
        STORE R9, R3
        RET

; ===== dispatch =====
dispatch:
        LOADI R4, 16
        LOAD  R1, R4
        CMP   R1, R0
        JZ    cmd_empty

        LOADI R2, 104
        CMP   R1, R2
        JZ    try_help

        LOADI R2, 99
        CMP   R1, R2
        JZ    try_clear

        LOADI R2, 101
        CMP   R1, R2
        JZ    try_echo

        JMP   cmd_unknown

; ---- help ----
try_help:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 101
        CMP   R1, R2
        JZ    help2
        JMP   cmd_unknown
help2:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 108
        CMP   R1, R2
        JZ    help3
        JMP   cmd_unknown
help3:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 112
        CMP   R1, R2
        JZ    help4
        JMP   cmd_unknown
help4:  ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    cmd_help
        JMP   cmd_unknown

; ---- clear ----
try_clear:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 108
        CMP   R1, R2
        JZ    clear2
        JMP   cmd_unknown
clear2: ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 101
        CMP   R1, R2
        JZ    clear3
        JMP   cmd_unknown
clear3: ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 97
        CMP   R1, R2
        JZ    clear4
        JMP   cmd_unknown
clear4: ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 114
        CMP   R1, R2
        JZ    clear5
        JMP   cmd_unknown
clear5: ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    cmd_clear
        JMP   cmd_unknown

; ---- echo ----
try_echo:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 99
        CMP   R1, R2
        JZ    echo2
        JMP   cmd_unknown
echo2:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 104
        CMP   R1, R2
        JZ    echo3
        JMP   cmd_unknown
echo3:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 111
        CMP   R1, R2
        JZ    cmd_echo
        JMP   cmd_unknown

; ---- 命令处理 ----
cmd_empty:
        JMP   main

cmd_unknown:
        LOADI R1, 63
        STORE R9, R1
        LOADI R1, 10
        STORE R9, R1
        JMP   main

cmd_help:
        LOADI R1, 104
        STORE R9, R1
        LOADI R1, 101
        STORE R9, R1
        LOADI R1, 108
        STORE R9, R1
        LOADI R1, 112
        STORE R9, R1
        LOADI R1, 58
        STORE R9, R1
        LOADI R1, 32
        STORE R9, R1
        LOADI R1, 104
        STORE R9, R1
        LOADI R1, 101
        STORE R9, R1
        LOADI R1, 108
        STORE R9, R1
        LOADI R1, 112
        STORE R9, R1
        LOADI R1, 44
        STORE R9, R1
        LOADI R1, 32
        STORE R9, R1
        LOADI R1, 99
        STORE R9, R1
        LOADI R1, 108
        STORE R9, R1
        LOADI R1, 101
        STORE R9, R1
        LOADI R1, 97
        STORE R9, R1
        LOADI R1, 114
        STORE R9, R1
        LOADI R1, 10
        STORE R9, R1
        JMP   main

cmd_clear:
        LOADI R5, 10
cc_loop:
        LOADI R1, 10
        STORE R9, R1
        ADDI  R5, -1
        CMP   R5, R0
        JZ    cc_done
        JMP   cc_loop
cc_done:
        JMP   main

cmd_echo:
        LOADI R4, 20        ; R4 = 缓冲区 + 4（echo 后面那个字符）
        LOAD  R1, R4
        CMP   R1, R0
        JZ    ec_newline    ; 是 \0，直接输出换行
        LOADI R2, 32
        CMP   R1, R2
        JZ    ec_skip       ; 是空格，跳过
        JMP   ec_loop       ; 其他，从当前位置读
ec_skip:
        ADDI  R4, 1         ; 跳过空格
ec_loop:
        LOAD  R1, R4
        CMP   R1, R0
        JZ    ec_newline
        STORE R9, R1
        ADDI  R4, 1
        JMP   ec_loop
ec_newline:
        LOADI R1, 10
        STORE R9, R1
        JMP   main        ; 缓冲区 + 4 = 0x14，跳过 "echo"
ec_loop:
        LOAD  R1, R4
        CMP   R1, R0
        JZ    ec_done
        STORE R9, R1
        ADDI  R4, 1
        JMP   ec_loop
ec_done:
        LOADI R1, 10
        STORE R9, R1
        JMP   main