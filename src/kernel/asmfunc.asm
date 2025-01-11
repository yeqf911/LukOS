; ams function
[bits 32]
section .text
global io_hlt
global set_x
global debug

io_hlt:
    hlt
    ret

debug:
    xchg bx, bx
    ret

set_x:
    mov byte [0xb8000], 'W'