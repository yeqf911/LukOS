bits 16

CYLS    EQU     10
%ifndef DEBUG
    org 0x7C00
%endif

global _start

    jmp short _start
    nop

    ; --- BPB（BIOS Parameter Block） ---  
    OEMLabel db "MYFAT12 "       ; OEM 标识符（8字节）  
    BytesPerSector dw 512        ; 每扇区字节数（通常为 512）  
    SectorsPerCluster db 1       ; 每簇占用扇区数（通常为 1）  
    ReservedSectors dw 1         ; 保留扇区数量（Boot 扇区占用 1）  
    NumberOfFATs db 2            ; FAT 表数量（通常为 2）  
    RootDirEntries dw 224        ; 根目录条目数（224 个，每条 32 字节）  
    TotalSectors dw 2880         ; 总扇区数（1.44 MB 软盘：2880 扇区）  
    MediaDescriptor db 0xF0      ; 媒体描述符（0xF0 用于软盘）  
    SectorsPerFAT dw 9           ; 每个 FAT 表的扇区数（9 扇区）  
    SectorsPerTrack dw 18        ; 每磁道的扇区数（通常为 18）  
    NumberOfHeads dw 2           ; 磁头数（通常为 2）  
    HiddenSectors dd 0           ; 隐藏扇区数（通常为 0）  
    TotalSectorsBig dd 0         ; 大扇区数（如果超过 65535，需要用此字段存储）  

    ; --- 可用空间（扩展 BPB） ---  
    DriveNumber db 0             ; 驱动器编号（软盘为 0）  
    Reserved db 0                ; 保留字节  
    BootSignature db 0x29        ; 扩展引导记录标志（标准为 0x29）  
    VolumeID dd 0x12345678       ; 卷序列号（随机值）  
    VolumeLabel db "NO NAME    " ; 卷标（11字节）  
    FileSystemType db "FAT12   " ; 文件系统类型标识符

_start:
    nop
read_sector:
    mov AX, 0x0820  ; 
    mov ES, AX      ; 段地址，表示从 0x0820 * 16 开始
    mov CH, 0       ; 柱面号
    mov DH, 0       ; 磁头号
    mov CL, 2       ; 扇区号

readloop:
    mov SI, 0       ; 记录失败次数
retry:
    mov AH, 0x02    ; 读盘
    mov AL, 1       ; 读取的扇区数
    mov BX, 0       ; 保留
    mov DL, 0       ; 驱动器A
    int 0x13        ; 磁盘中断
    jnc next        ; 检查错误，CF=1则发生错误，CF=0正常
    inc SI
    cmp SI, 5       ; 最大重试5次
    jge error       ; SI >= 5，jump to error

check_err:
    mov AH, 0x01
    int 0x13

reset_disk:
    mov AH, 0x00    ; 复位磁盘系统（置磁盘控制器，清理操作状态）
    mov DL, 0       ; 驱动器A
    int 0x13
    jnc retry

next:
    mov AX, ES      ; 从ES段寄存器读出当前段地址
    add AX, 0x0020  ; 加上0x0020, 实际上是加0x0200=512
    mov ES, AX      ; 重新赋值ES
    add CL, 1       ; 扇区号+1
    cmp CL, 18
    jle readloop    ; 一直读到18扇区

    mov CL, 1
    add DH, 1
    cmp DH, 2
    jl readloop

    mov DH, 0
    mov CL, 1
    add CH, 1
    cmp CH, CYLS
    jl readloop
    mov si, message
    call print_err
flag:
    mov al, 0
    jmp 0xc200

; loop:
;     cli
;     hlt
;     jmp loop

error:
    mov SI, message

print_err:
    mov AL, byte [SI]
    inc SI
    cmp AL, 0
    je .done
    mov AH, 0x0E    ; 服务号，表示直接显示单个字符
    mov BL, 0x04    ; 字符的显示属性
    mov BH, 0
    int 0x10
    jmp print_err
    .done:
        ret

message db "load error!", 0x0d, 0x0a, 0x00

_boot_flag:
    times 510-($-$$) DB 0x00
    DW 0xAA55

; Now start the FAT table definitions.  
; --- FAT 表 (File Allocation Table) ---  
FAT1:  
    db 0xF0, 0xFF, 0xFF                   ; FAT1 开头标记（媒体描述符 + 结束标记）  
    db 0xFF, 0xFF
    times 512*9 - 5 db 0x00               ; 填充其余 9 扇区  

FAT2:  
    db 0xF0, 0xFF, 0xFF                   ; FAT2 开头标记（与 FAT1 相同）  
    db 0xFF, 0xFF
    times 512*9 - 5 db 0x00               ; 填充其余 9 扇区  

; --- 根目录（Root Directory） ---  
RootDir:  
    ; 文件条目 1: 一个简单的文本文件 "HELLO.TXT"  
    db "HELLO   "                         ; 文件名（8 字节）  
    db "TXT"                              ; 文件扩展名（3 字节）  
    db 0x20                               ; 文件属性  
    times 10 db 0                         ; 保留位置填充  
    dw 0                                  ; 创建时间  
    dw 0                                  ; 创建日期  
    dw 2                                  ; 首簇号（此文件从数据区域开始的第一个簇）  
    dd 19                                 ; 文件大小（"Hello yeqianfeng!\回车\换行" 19 字节）  

    times 32 * 224 - 32 db 0x00           ; 填充根目录剩余扇区（224 条目，共 14 扇区）  

; --- 数据区域（Data Area） ---  
DataArea:  
    ; 数据区域，存储文件内容  
    db "Hello yeqianfeng!", 0x0D, 0x0A     ; HELLO.TXT 的内容  
    times 512*2880 - ($ - $$) db 0x00     ; 填充剩余数据区域内容为空 