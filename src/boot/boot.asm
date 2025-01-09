[bits 16]
[org 0x7c00]

section .text
global _start
    jmp short _start
    nop

; skip floppy BPB（BIOS Parameter Block） ---  
times 62 -($-$$) db 0

_start:
    ; 设置屏幕为文本模式,清除屏幕
    mov ax, 3
    int 0x10

    ; 初始化寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00 
    mov si, booting_msg
    call print

    xor bx, bx
    mov ax, 0x0800
    call read_chs
    xchg bx, bx
    cmp word [0x8400], 0x55aa
    je 0x8400
    mov si, loading_error
    call print

_loop:
    hlt
    jmp _loop

; CHS模式读盘
read_chs:
    mov es, ax
    mov dl, 0
    mov ch, 0
    call read_cylinder
    ret

; 读柱面
read_cylinder:
    ; 从1号扇区读，读一个扇区
    ; 读取磁头0
    mov cl, 1
    mov dh, 0
    call read_sector
    ; 读取磁头1
    mov cl, 1
    mov dh, 1
    call read_sector
    cmp ch, 10
    je .done
    add ch, 1
    call read_cylinder
    .done:
        ret

; 读扇区
read_sector:
    mov ah, 0x02
    mov al, 1
    int 0x13
    jc read_error
    cmp cl, 18
    je .done
    mov ax, es
    add ax, 0x0020
    mov es, ax
    add cl, 1
    call read_sector
    .done:
        ret

check_err:
    mov ah, 0x01
    int 0x13
    cmp ah, 0x09
    je .set_msg
    jmp .done
    .set_msg:
        mov si, .msg
    .done:
        call print
        ret
    .msg db "DMA 64kb limit!!!", 13, 10, 0

reset_disk:
    mov ah, 0x00    ; 复位磁盘系统（置磁盘控制器，清理操作状态）
    mov dl, 0       ; 驱动器A
    int 0x13
    ret

read_error:
    call check_err
    call reset_disk
    mov si, .err_msg
    call print
    .err_msg db "read disk error!", 0x0a, 0x0d, 0
    ret
    
print:
    mov ah, 0x0e
.next:
    mov al, byte [si]
    inc si
    cmp al, 0
    je .done
    mov bl, 0x04    ; 字符的显示属性
    mov bh, 0x17
    int 0x10
    jmp .next
.done:
    ret

booting_msg db "Hello LukOS!!!", 0x0a, 0x0d, 0
loading_error db "Loading error!", 13, 10, 0

times 510 - ($-$$) db 0
dw 0xaa55