        LOADI R9, -1        ; R9 = 0xFFF (GPIO)

        ; --- 手动初始化字符串 "Hi\0" ---
        LOADI R1, 0x20
        LOADI R2, 72        ; 'H'
        STORE R1, R2
        ADDI  R1, 1
        LOADI R2, 105       ; 'i'
        STORE R1, R2
        ADDI  R1, 1
        LOADI R2, 0         ; '\0'
        STORE R1, R2

        ; --- 调用打印函数 ---
        LOADI R1, 0x20      ; R1 = 字符串起始地址
        CALL  print_string
        HLT

; ============================================
; print_string:
;   输入：R1 = 字符串起始地址
;   输出：无（破坏 R1, R2）
; ============================================
print_string:
        LOAD  R2, R1        ; 读当前字符
        CMP   R2, R0        ; 是不是 '\0'
        JZ    ps_done       ; 是，结束
        STORE R9, R2        ; 不是，输出到 GPIO
        ADDI  R1, 1         ; 指针加一
        JMP   print_string  ; 继续读下一个
ps_done:
        RET