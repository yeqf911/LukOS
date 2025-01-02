; LukOS
; TAB=4
bits 16

; section .data
    CYLS    equ 0x0ff0
    LEDS    equ 0x0ff1
    VMODE   equ 0x0ff2
    SCRNX   equ 0x0ff4
    SCRNY   equ 0x0ff6
    VRAM    equ 0x0ff8

%ifndef DEBUG
    org 0xc200  ;0x8000 + 0x4200
%endif

; entry:
    mov al, 0x13
flag1:
    mov ah, 0x00
    int 0x10
    mov byte [VMODE], 8         ; 记录画面模式
    mov word [SCRNX], 320       
    mov word [SCRNY], 200
    mov dword [VRAM], 0x000a0000

    ; 用bios取得键盘上的各种LED指示灯的状态
    mov ah, 0x02
    int 0x16                    ; 键盘bios中断
    mov [LEDS], al

    ; mov si, msg
    ; call print

.loop:
    hlt
    jmp .loop

print:
    mov al, byte [si]
    inc si
    cmp al, 0
    je .done
    mov ah, 0x0e    ; 服务号，表示直接显示单个字符
    mov bl, 0x04    ; 字符的显示属性
    mov bh, 0
    int 0x10
    jmp print
    .done:
        ret

msg db "load error!", 0x0d, 0x0a, 0x00