ENTRY(_start)
SECTIONS
{
    . = 0xc200;
    .text : {
        *(.text)
    }
    .data : {
        *(.data)
    }
    .bss : {
        *(.bss)
    }
    .rodata : {
        *(.rodata*)
    }
}