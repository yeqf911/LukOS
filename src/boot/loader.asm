[org 0x8400]

dw 0x55aa

_entry:
    mov si, msg
    call print
    jmp entry_protect_mode

entry_protect_mode:
    cli ; 关闭中断

    ; 打开A20地址线
    mov dx, 0x92
    in al, dx
    or al, 0b10 ; 将第二位置1
    out dx, al 

    ; 打开PE位，启动保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax   

    ; 加载gdt表
    lgdt [gdt_ptr] 

    ; 用 jmp跳转来刷新缓存，启用保护模式
    jmp dword code_seg_selector:protected_mode

print:
.next:
    mov al, byte [si]
    inc si
    cmp al, 0
    je .done
    mov ah, 0x0e    ; 服务号，表示直接显示单个字符
    mov bl, 0x05    ; 字符的显示属性
    mov bh, 0
    int 0x10
    jmp .next
    .done:
        ret

msg db "Loading LukOS success!!!", 0x0a, 0x0d, 0x00

[bits 32]
protected_mode:
    ; 初始化段寄存器,初始化位数据段选择子
    mov ax, data_seg_selector
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
    xchg bx, bx
    mov esp, 0x10000    ; 修改栈顶
    mov byte [0xb8000], '@' ; 修改显存内容
    xchg bx, bx
    jmp 0xc020
    jmp $

code_seg_selector equ 1 << 3 ; 因为一个段的长度位8字节
data_seg_selector equ 2 << 3

segment_base_addr equ 0x0
segment_limit equ 0xffffffff    ; (2^32-1)*1B=4GB

gdt_ptr:
    dw (gdt_end - gdt_base) - 1
    dd gdt_base

gdt_base:
    dd 0, 0     ; null descriptor
gdt_code:
    dw segment_limit & 0xffff                   ; 段界限低16位
    dw segment_base_addr & 0xffff               ; 段基址 前16位
    db (segment_base_addr >> 16) & 0xff         ; 段基址 中8位
    ; P=1(存在),DPL=00(最高权限0),S=1(1表示代码段或数据段),TYPE(X=1(代码段：C=0(是否依从代码段),R(是否可读),A(是否被CPU访问))
    db 0b_1_00_1_1_0_1_0                        
    ; G=0(0表示单位1B,1表示4KB),D/B=1(32位操作数,0表示16位操作数),L=0(32位处理器,1表示64位处理器),AVL=0(送给操作系统)
    db 0b_0_1_0_0_0000 | ((segment_limit >> 16) & 0xf) ; G=0,D/B=1,L=1,AVL=0,段界限高四位
    db (segment_base_addr >> 24) & 0xff         ; 基地址后8位
gdt_data:
    dw segment_limit & 0xffff                   ; 段界限低16位
    dw segment_base_addr & 0xffff               ; 段基址 前16位
    db (segment_base_addr >> 16) & 0xff         ; 段基址 中8位
    ; P=1(存在),DPL=00(最高权限0),S=1(1表示代码段或数据段),TYPE(X=0(数据段：E=0(向上扩展,1表示向下扩展),W=1(可写),A(是否被CPU访问))
    db 0b_1_00_1_0_0_1_0                        
    ; G=0(0表示单位1B,1表示4KB),D/B=1(32位操作数,0表示16位操作数),L=0(32位处理器,1表示64位处理器),AVL=0(送给操作系统)
    db 0b_0_1_0_0_0000 | ((segment_limit >> 16) & 0xf) ; G=0,D/B=1,L=1,AVL=0,段界限高四位
    db (segment_base_addr >> 24) & 0xff         ; 基地址后8位
gdt_end: