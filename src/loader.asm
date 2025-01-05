[org 0xc200]

dw 0x55aa

mov al, 0x13
mov ah, 0x00
int 0x10

mov si, msg
call print

_loop:
    hlt
    jmp _loop

print:
    mov al, byte [si]
    inc si
    cmp al, 0
    je .done
    mov ah, 0x0e    ; 服务号，表示直接显示单个字符
    mov bl, 0x05    ; 字符的显示属性
    mov bh, 0
    int 0x10
    jmp print
    .done:
        ret

msg db "Loading LukOS success!!!", 0x0a, 0x0d, 0x00