; ams function
[bits 32]
section .text
global io_hlt
global set_x

io_hlt:
    hlt
    ret
    mov byte [0xb8000], 'Q' ; 此处多一行，内核的地址会发生变化,对应的 0xc010也需要改为0xc020

set_x:
    mov byte [0xb8000], 'W'
    jmp $