%ifndef DEBUG
    org 0x0820 + 0x4200
%endif

    ; mov AL, 0x13
    ; mov AH, 0x00
    ; int 0x10

loop:
    hlt
    jmp loop