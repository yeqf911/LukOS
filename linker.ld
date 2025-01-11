OUTPUT_FORMAT("elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)
SECTIONS
{
    . = 0xc200;
    .text : {
        *(.text)
    } : code
    .data : {
        *(.data)
    } : data
    .bss : {
        *(.bss)
    } : data
    .rodata : {
        *(.rodata*)
    } : rodata
}

PHDRS
{
    code PT_LOAD FLAGS(5);
    rodata PT_LOAD FLAGS(4);
    data PT_LOAD FLAGS(6);
}