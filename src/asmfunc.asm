; ams function
    section .text
    bits 32
    global io_hlt

io_hlt:
    hlt
    ret