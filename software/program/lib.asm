.text

print_string:
        LOAD  R2, R1
        CMP   R2, R0
        JZ    ps_done
        STORE R9, R2
        ADDI  R1, 1
        JMP   print_string
ps_done:
        RET

print_newline:
        LOADI R1, 10
        STORE R9, R1
        RET

; parse_hex：支持 0x 前缀、大写 A-F、小写 a-f
parse_hex:
        LOADI R2, 0
ph_loop:
        LOAD  R3, R1
        CMP   R3, R0
        JZ    ph_done

        LOADI R4, 48
        CMP   R3, R4
        JN    ph_skip

        LOADI R4, 58
        CMP   R3, R4
        JN    ph_digit

        LOADI R4, 65
        CMP   R3, R4
        JN    ph_skip
        LOADI R4, 71
        CMP   R3, R4
        JN    ph_upper

        LOADI R4, 97
        CMP   R3, R4
        JN    ph_skip
        LOADI R4, 103
        CMP   R3, R4
        JN    ph_lower
        JMP   ph_skip

ph_digit:
        ADDI  R3, -48
        JMP   ph_acc
ph_upper:
        ADDI  R3, -55
        JMP   ph_acc
ph_lower:
        ADDI  R3, -87
ph_acc:
        LOADI R4, 4
        SHL   R2, R2, R4
        ADD   R2, R2, R3
ph_skip:
        ADDI  R1, 1
        JMP   ph_loop
ph_done:
        RET

; parse_hex_ptr：解析一个十六进制数，遇到空格跳过连续空格后返回
parse_hex_ptr:
        LOADI R2, 0
php_loop:
        LOAD  R3, R1
        CMP   R3, R0
        JZ    php_done

        LOADI R4, 32
        CMP   R3, R4
        JZ    php_spaces

        LOADI R4, 48
        CMP   R3, R4
        JN    php_skip

        LOADI R4, 58
        CMP   R3, R4
        JN    php_digit

        LOADI R4, 65
        CMP   R3, R4
        JN    php_skip
        LOADI R4, 71
        CMP   R3, R4
        JN    php_upper

        LOADI R4, 97
        CMP   R3, R4
        JN    php_skip
        LOADI R4, 103
        CMP   R3, R4
        JN    php_lower
        JMP   php_skip

php_digit:
        ADDI  R3, -48
        JMP   php_acc
php_upper:
        ADDI  R3, -55
        JMP   php_acc
php_lower:
        ADDI  R3, -87
php_acc:
        LOADI R4, 4
        SHL   R2, R2, R4
        ADD   R2, R2, R3
php_skip:
        ADDI  R1, 1
        JMP   php_loop

php_spaces:
        ADDI  R1, 1
        LOAD  R3, R1
        LOADI R4, 32
        CMP   R3, R4
        JZ    php_spaces
php_done:
        RET

print_hex:
        ADD   R4, R1, R0
        LOADI R5, 4
phx_loop:
        LOADI R3, 12
        SHR   R1, R4, R3
        LOADI R3, 15
        AND   R1, R1, R3
        LOADI R3, 10
        CMP   R1, R3
        JN    phx_digit
        ADDI  R1, 87
        JMP   phx_emit
phx_digit:
        ADDI  R1, 48
phx_emit:
        STORE R9, R1
        LOADI R3, 4
        SHL   R4, R4, R3
        ADDI  R5, -1
        CMP   R5, R0
        JZ    phx_done
        JMP   phx_loop
phx_done:
        RET