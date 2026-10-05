        LOADI R9, -1
        LOADI R2, 0x41
        CALL  print
        LOADI R2, 0x42
        CALL  print
        LOADI R2, 0x43
        CALL  print
        HLT

print:  STORE R9, R2
        RET