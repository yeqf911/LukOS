; ams function
[bits 32]
section .text
global io_hlt
global set_x

io_hlt:
    hlt
    ret

set_x:
    mov byte [0xb8000], 'W'
    jmp $