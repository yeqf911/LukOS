bits 16
%ifndef DEBUG
org 0x7C00
%endif

global _start

_start:
    mov AH, 0x00
    mov AL, 0x13
    int 0x10

    mov AX, 0xA000
    mov ES, AX
    xor DI, DI
draw_upper:
    mov byte [ES:DI], 0x15
    inc DI
    cmp DI, 32001
    jl draw_upper

wait_keyboard:
    mov AH, 0x00
    int 0x16

draw_lower:
    mov byte [ES:EDI], 0x04
    inc EDI
    cmp EDI, 64000
    jl draw_lower

done:
    cli
    hlt
    jmp done

times 510-($-$$) DB 0
DW 0xAA55