.text

cmd_empty:
        RET

cmd_unknown:
        LOADI R1, -4
        LOADI R2, 2
        STORE R1, R2
        LOADI R4, 16
cu_loop:
        LOAD  R1, R4
        CMP   R1, R0
        JZ    cu_done
        STORE R9, R1
        ADDI  R4, 1
        JMP   cu_loop
cu_done:
        LOADI R1, ptr_nf
        LOAD  R1, R1
        CALL  print_string
        LOADI R1, -4
        LOADI R2, 0
        STORE R1, R2
        RET

cmd_help:
        LOADI R5, 20
        LOAD  R1, R5
        CMP   R1, R0
        JZ    help_all
        LOADI R2, 32
        CMP   R1, R2
        JZ    help_sub
help_all:
        LOADI R1, -4
        LOADI R2, 4
        STORE R1, R2
        LOADI R1, ptr_help
        LOAD  R1, R1
        CALL  print_string
        LOADI R1, -4
        LOADI R2, 0
        STORE R1, R2
        RET
help_sub:
        LOADI R5, 21
        LOAD  R1, R5
        LOADI R2, 109
        CMP   R1, R2
        JZ    help_m
        LOADI R2, 100
        CMP   R1, R2
        JZ    help_d
        LOADI R2, 119
        CMP   R1, R2
        JZ    help_w
        LOADI R2, 101
        CMP   R1, R2
        JZ    help_e
        LOADI R2, 99
        CMP   R1, R2
        JZ    help_c
        LOADI R2, 98
        CMP   R1, R2
        JZ    help_b
        LOADI R2, 112
        CMP   R1, R2
        JZ    help_p
        JMP   help_all
help_m: LOADI R1, ptr_usage_mem
        LOAD  R1, R1
        JMP   help_print
help_d: LOADI R1, ptr_usage_dump
        LOAD  R1, R1
        JMP   help_print
help_w: LOADI R1, ptr_usage_write
        LOAD  R1, R1
        JMP   help_print
help_e: LOADI R1, ptr_usage_echo
        LOAD  R1, R1
        JMP   help_print
help_c: LOADI R1, ptr_usage_clear
        LOAD  R1, R1
        JMP   help_print
help_b: LOADI R1, ptr_usage_beep
        LOAD  R1, R1
        JMP   help_print
help_p: LOADI R1, ptr_usage_play
        LOAD  R1, R1
help_print:
        LOADI R2, -4
        LOADI R3, 4
        STORE R2, R3
        CALL  print_string
        LOADI R2, -4
        LOADI R3, 0
        STORE R2, R3
        RET

cmd_clear:
        LOADI R1, -5
        LOADI R2, 0
        STORE R1, R2
        RET

cmd_echo:
        LOADI R4, 20
        LOAD  R1, R4
        CMP   R1, R0
        JZ    ec_newline
        LOADI R2, 32
        CMP   R1, R2
        JZ    ec_skip
        JMP   ec_loop
ec_skip:
        ADDI  R4, 1
ec_loop:
        LOAD  R1, R4
        CMP   R1, R0
        JZ    ec_newline
        STORE R9, R1
        ADDI  R4, 1
        JMP   ec_loop
ec_newline:
        CALL  print_newline
        RET

cmd_mem:
        LOADI R1, 20
        CALL  parse_hex
        ADD   R4, R2, R0
        LOAD  R6, R4
        LOADI R1, ptr_0x
        LOAD  R1, R1
        CALL  print_string
        ADD   R1, R4, R0
        CALL  print_hex
        LOADI R1, ptr_col
        LOAD  R1, R1
        CALL  print_string
        ADD   R1, R6, R0
        CALL  print_hex
        CALL  print_newline
        RET

cmd_dump:
        LOADI R1, 21
        CALL  parse_hex
        ADD   R6, R2, R0
        CALL  dump_print_addr
        LOADI R2, 8
dump_row1:
        LOAD  R1, R6
        CALL  print_hex
        LOADI R1, 32
        STORE R9, R1
        ADDI  R6, 1
        ADDI  R2, -1
        CMP   R2, R0
        JZ    dump_row1_done
        JMP   dump_row1
dump_row1_done:
        CALL  print_newline
        CALL  dump_print_addr
        LOADI R2, 8
dump_row2:
        LOAD  R1, R6
        CALL  print_hex
        LOADI R1, 32
        STORE R9, R1
        ADDI  R6, 1
        ADDI  R2, -1
        CMP   R2, R0
        JZ    dump_row2_done
        JMP   dump_row2
dump_row2_done:
        CALL  print_newline
        RET
dump_print_addr:
        LOADI R1, 48
        STORE R9, R1
        LOADI R1, 120
        STORE R9, R1
        ADD   R1, R6, R0
        CALL  print_hex
        LOADI R1, 58
        STORE R9, R1
        LOADI R1, 32
        STORE R9, R1
        RET

cmd_write:
        LOADI R1, 22
        CALL  parse_hex_ptr
        ADD   R6, R2, R0
        CALL  parse_hex_ptr
        STORE R6, R2
        LOADI R1, 48
        STORE R9, R1
        LOADI R1, 120
        STORE R9, R1
        ADD   R1, R6, R0
        CALL  print_hex
        LOADI R1, 32
        STORE R9, R1
        LOADI R1, 61
        STORE R9, R1
        LOADI R1, 32
        STORE R9, R1
        LOAD  R3, R6
        ADD   R1, R3, R0
        CALL  print_hex
        CALL  print_newline
        RET

cmd_beep:
        LOADI R1, 21
        CALL  parse_hex
        LOADI R1, -6
        STORE R1, R2
        CALL  print_newline
        RET

; load <filename>
; 从缓冲区 +5 开始是文件名，读到 0x100 后面暂存
cmd_load:
        ; 把文件名从 buf+5 拷到 0x200 处
        LOADI R1, 21
        LOADI R6, 512
cl_loop:
        LOAD  R2, R1
        CMP   R2, R0
        JZ    cl_done
        STORE R6, R2
        ADDI  R1, 1
        ADDI  R6, 1
        JMP   cl_loop
cl_done:
        LOADI R2, 0
        STORE R6, R2

        ; 打开文件
        LOADI R1, 512
        LOADI R2, -7
        STORE R2, R1

        ; 检查状态
        LOADI R3, -9
        LOAD  R4, R3
        CMP   R4, R0
        JZ    cl_ok
        LOADI R1, ptr_load_err
        LOAD  R1, R1
        CALL  print_string
        RET

cl_ok:
        LOADI R6, 2048     ; 0x800
cl_read:
        LOADI R1, 0
        ADD   R1, R6, R0
        LOADI R2, -8
        STORE R2, R1

        LOADI R3, -9
        LOAD  R4, R3
        CMP   R4, R0
        JZ    cl_next
        JMP   cl_eof

cl_next:
        ADDI  R6, 1
        LOADI R5, 3072
        CMP   R6, R5
        JZ    cl_eof
        JMP   cl_read

cl_eof:
        ; R1 = 0x800（用移位合成，因为 2048 > 127）
        LOADI R1, 8
        LOADI R2, 8
        SHL   R1, R1, R2

        ; 存到 last_loaded
        LOADI R2, last_loaded
        STORE R2, R1

        LOADI R1, ptr_load_ok
        LOAD  R1, R1
        CALL  print_string
        RET

; run <addr>
cmd_run:
        ; 检查有没有参数
        LOADI R1, 20       ; buf[4]
        LOAD  R2, R1
        CMP   R2, R0
        JZ    run_noparam  ; buf[4] 是 \0，没参数

        ; 有参数：从 buf[4] 解析地址
        CALL  parse_hex
        ADD   R6, R2, R0
        CMP   R6, R0
        JZ    run_none     ; 解析出 0，当错误
        JMP   run_go

run_noparam:
        ; 从 last_loaded 读
        LOADI R1, last_loaded
        LOAD  R6, R1
        CMP   R6, R0
        JZ    run_none     ; 没加载过，显示 usage

run_go:
        ; 保存返回地址到 R14
        LOADI R5, ptr_main_addr
        LOAD  R14, R5

        ; 打印 "running..."
        LOADI R1, ptr_run_msg
        LOAD  R1, R1
        CALL  print_string

        ; 跳
        JMP   R6

run_none:
        LOADI R1, ptr_usage_run
        LOAD  R1, R1
        CALL  print_string
        RET
cmd_play:
        LOADI R1, melody
        CALL  play_melody
        CALL  print_newline
        RET

play_melody:
pm_loop:
        LOAD  R5, R1
        CMP   R5, R0
        JZ    pm_done
        LOADI R2, -6
        STORE R2, R5
        ADDI  R1, 1
        JMP   pm_loop
pm_done:
        RET