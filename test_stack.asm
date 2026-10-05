        LOADI R9, -1
        LOADI R2, 0x41
        CALL  level1
        LOADI R2, 0x5A
        STORE R9, R2
        HLT

level1: STORE R9, R2
        ADDI  R2, 1
        CALL  level2
        RET

level2: STORE R9, R2
        ADDI  R2, 1
        CALL  level3
        RET

level3: STORE R9, R2
        RET