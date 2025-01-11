extern void io_hlt();
extern void set_x();
extern void debug();

char message[] = "ZZ\0";
char buf[1024];

void kernel_init()
{
    char *video = (char *)0xb8000;

    video[0] = 'S';
    video[2] = 'B';
    video[4] = 'F';
    video[6] = 'G';
    set_x();
    while (1)
    {
        io_hlt();
    }
}