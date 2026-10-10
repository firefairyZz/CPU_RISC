.text

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
        LOADI R2, 109
        CMP   R1, R2
        JZ    try_mem
        LOADI R2, 100
        CMP   R1, R2
        JZ    try_dump
        LOADI R2, 119
        CMP   R1, R2
        JZ    try_write
        LOADI R2, 98
        CMP   R1, R2
        JZ    try_beep
        LOADI R2, 112
        CMP   R1, R2
        JZ    try_play
        LOADI R2, 108      ; 'l' → load
        CMP   R1, R2
        JZ    try_load
        LOADI R2, 114      ; 'r' → run
        CMP   R1, R2
        JZ    try_run
        JMP   cmd_unknown

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
        JZ    cmd_help
        JMP   cmd_unknown

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
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_clear
        JMP   cmd_unknown

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
        JZ    echo4
        JMP   cmd_unknown
echo4:  ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    echo_usage
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_echo
        JMP   cmd_unknown
echo_usage:
        LOADI R1, ptr_usage_echo
        LOAD  R1, R1
        CALL  print_string
        RET

try_mem:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 101
        CMP   R1, R2
        JZ    mem2
        JMP   cmd_unknown
mem2:   ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 109
        CMP   R1, R2
        JZ    mem3
        JMP   cmd_unknown
mem3:   ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    mem_usage
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_mem
        JMP   cmd_unknown
mem_usage:
        LOADI R1, ptr_usage_mem
        LOAD  R1, R1
        CALL  print_string
        RET

try_dump:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 117
        CMP   R1, R2
        JZ    dump2
        JMP   cmd_unknown
dump2:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 109
        CMP   R1, R2
        JZ    dump3
        JMP   cmd_unknown
dump3:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 112
        CMP   R1, R2
        JZ    dump4
        JMP   cmd_unknown
dump4:  ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    dump_usage
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_dump
        JMP   cmd_unknown
dump_usage:
        LOADI R1, ptr_usage_dump
        LOAD  R1, R1
        CALL  print_string
        RET

try_write:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 114
        CMP   R1, R2
        JZ    write2
        JMP   cmd_unknown
write2: ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 105
        CMP   R1, R2
        JZ    write3
        JMP   cmd_unknown
write3: ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 116
        CMP   R1, R2
        JZ    write4
        JMP   cmd_unknown
write4: ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 101
        CMP   R1, R2
        JZ    write5
        JMP   cmd_unknown
write5: ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    write_usage
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_write
        JMP   cmd_unknown
write_usage:
        LOADI R1, ptr_usage_write
        LOAD  R1, R1
        CALL  print_string
        RET

try_beep:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 101
        CMP   R1, R2
        JZ    beep2
        JMP   cmd_unknown
beep2:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 101
        CMP   R1, R2
        JZ    beep3
        JMP   cmd_unknown
beep3:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 112
        CMP   R1, R2
        JZ    beep4
        JMP   cmd_unknown
beep4:  ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    beep_usage
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_beep
        JMP   cmd_unknown
beep_usage:
        LOADI R1, ptr_usage_beep
        LOAD  R1, R1
        CALL  print_string
        RET

try_play:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 108
        CMP   R1, R2
        JZ    play2
        JMP   cmd_unknown
play2:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 97
        CMP   R1, R2
        JZ    play3
        JMP   cmd_unknown
play3:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 121
        CMP   R1, R2
        JZ    play4
        JMP   cmd_unknown
play4:  ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    cmd_play
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_play
        JMP   cmd_unknown

try_load:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 111      ; 'o'
        CMP   R1, R2
        JZ    load2
        JMP   cmd_unknown
load2:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 97       ; 'a'
        CMP   R1, R2
        JZ    load3
        JMP   cmd_unknown
load3:  ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 100      ; 'd'
        CMP   R1, R2
        JZ    load4
        JMP   cmd_unknown
load4:  ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    load_usage
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_load
        JMP   cmd_unknown
load_usage:
        LOADI R1, ptr_usage_load
        LOAD  R1, R1
        CALL  print_string
        RET

try_run:
        LOADI R5, 1
        ADD   R5, R4, R5
        LOAD  R1, R5
        LOADI R2, 117      ; 'u'
        CMP   R1, R2
        JZ    run2
        JMP   cmd_unknown
run2:   ADDI  R5, 1
        LOAD  R1, R5
        LOADI R2, 110      ; 'n'
        CMP   R1, R2
        JZ    run3
        JMP   cmd_unknown
run3:   ADDI  R5, 1
        LOAD  R1, R5
        CMP   R1, R0
        JZ    cmd_run
        LOADI R2, 32
        CMP   R1, R2
        JZ    cmd_run
        JMP   cmd_unknown
run_usage:
        LOADI R1, ptr_usage_run
        LOAD  R1, R1
        CALL  print_string
        RET