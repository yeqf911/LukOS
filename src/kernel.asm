; LukOS
; TAB=4
[bits 16]

CYLS    equ 0x0ff0
LEDS    equ 0x0ff1
VMODE   equ 0x0ff2
SCRNX   equ 0x0ff4
SCRNY   equ 0x0ff6
VRAM    equ 0x0ff8

[org 0xc200]  ;0x8000 + 0x4200

entry:
    mov ax, 0x03
    int 0x10
    mov ax, 0xb800
    mov ds, ax
    mov byte [0], 'H'

wait_kb:
    xor al, al
    mov ah, 0x00
    int 0x16

    mov si, msg
    call print
    hlt
    jmp $

fresh_screen:
    mov al, 0x13
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

    ; 进入保护模式
    cli     ; 禁止中断

    ; 启用A20地址线
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 加载GDT
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:protected_mode
; GDT定义
gdt_start:
    dq 0            ; 空描述符

gdt_code:
    dw 0xffff       ; Limit[0:15]   段界限（低16位）
    dw 0            ; Base[0:15]    基地址（低16位）
    db 0            ; Base[23:16]   基地址（中8位）
    db 10011010b    ; Access Byte   访问权限字节
    db 11001111b    ; Flags + Limit[19:16] 标志位和段界限(高4位)
    db 0            ; Base[31:24]   基地址（高8位）

gdt_data:
    dw 0xffff
    dw 0
    db 0
    db 10011010b
    db 11001111b
    db 0

gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; GDT大小
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

[bits 32]
protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov esp, 0x90000
    mov dword [0xb8000], 0x0f500f48 ;
    mov si, msg
    call print

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