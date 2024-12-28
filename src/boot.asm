bits 16
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
    mov AH, 0x00
    mov AL, 0x13
    int 0x10

    mov AX, 0xA000
    mov ES, AX
    xor DI, DI
draw_upper:
    mov byte [ES:DI], 0x15
    inc DI
    cmp DI, 32000
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
    db 0x20                                  ; 文件属性  
    times 10 db 0                         ; 保留位置填充  
    dw 0                                  ; 创建时间  
    dw 0                                  ; 创建日期  
    dw 2                                  ; 首簇号（此文件从数据区域开始的第一个簇）  
    dd 19                                 ; 文件大小（12 字节）  

    times 32 * 224 - 32 db 0x00           ; 填充根目录剩余扇区（224 条目，共 14 扇区）  

; --- 数据区域（Data Area） ---  
DataArea:  
    ; 数据区域，存储文件内容  
    db "Hello yeqianfeng!", 0x0D, 0x0A     ; HELLO.TXT 的内容  
    times 512*2847 - ($ - $$) db 0x00     ; 填充剩余数据区域内容为空 