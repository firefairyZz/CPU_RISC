.text

read_line:
        LOADI R6, 16
        LOADI R5, 0

rl_loop:
        LOAD  R1, R7
        CMP   R1, R0
        JZ    rl_loop

        LOAD  R2, R8

        LOADI R3, 8
        CMP   R2, R3
        JZ    rl_back

        LOADI R3, 21
        CMP   R2, R3
        JZ    rl_kill

        LOADI R3, 3
        CMP   R2, R3
        JZ    rl_abort

        LOADI R3, 12
        CMP   R2, R3
        JZ    rl_cls

        LOADI R3, 13
        CMP   R2, R3
        JZ    rl_done

        LOADI R3, -4
        LOADI R1, 3
        STORE R3, R1
        STORE R9, R2

        LOADI R1, 0
        STORE R3, R1

        LOADI R3, 15
        CMP   R5, R3
        JZ    rl_loop

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

rl_abort:
        CMP   R5, R0
        JZ    abort_done
abort_loop:
        LOADI R3, 8
        STORE R9, R3
        LOADI R3, 32
        STORE R9, R3
        LOADI R3, 8
        STORE R9, R3
        ADDI  R5, -1
        CMP   R5, R0
        JZ    abort_done
        JMP   abort_loop
abort_done:
        LOADI R6, 16
        LOADI R5, 0
        JMP   rl_done

rl_cls:
        LOADI R1, -5
        LOADI R2, 0
        STORE R1, R2

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

        LOADI R6, 16
        LOADI R5, 0
        JMP   rl_loop

rl_kill:
        CMP   R5, R0
        JZ    kill_done
kill_loop:
        LOADI R3, 8
        STORE R9, R3
        LOADI R3, 32
        STORE R9, R3
        LOADI R3, 8
        STORE R9, R3
        ADDI  R5, -1
        CMP   R5, R0
        JZ    kill_done
        JMP   kill_loop
kill_done:
        LOADI R6, 16
        LOADI R5, 0
        JMP   rl_loop

rl_done:
        LOADI R3, 0
        STORE R6, R3
        ADDI  R6, 1
        STORE R6, R3
        CALL  print_newline
        RET