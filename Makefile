# 定义变量
UNAME = $(shell uname -s)

SRC_DIR = src
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
BIN_DIR = $(BUILD_DIR)/bin
MAP_DIR = $(BUILD_DIR)/map

# ASM source
ASM_SOURCES = $(wildcard $(SRC_DIR)/boot/*.asm)
BIN_TARGETS = $(patsubst $(SRC_DIR)/%.asm, $(BIN_DIR)/%.bin, $(ASM_SOURCES))
MAP_FILES = $(patsubst $(SRC_DIR)/%.asm, $(MAP_DIR)/%.map, $(ASM_SOURCES))
ASM_OBJECTS = $(patsubst $(SRC_DIR)/%.asm, $(OBJ_DIR)/%.o, $(wildcard $(SRC_DIR)/kernel/*.asm))

# C source
C_SOURCES = $(wildcard $(SRC_DIR)/**/*.c)
C_OBJECTS = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_SOURCES))

OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

# debug模式
DEBUG ?= on
# 启动方式 a:软盘，h硬盘
BOOT ?= a

# Target
BOOT_BIN = $(BIN_DIR)/boot/boot.bin
LOADER_BIN = $(BIN_DIR)/boot/loader.bin
KERNEL_ELF = $(BUILD_DIR)/kernel.elf
KERNEL_SYS = $(BUILD_DIR)/kernel.sys
OS_IMG = $(BUILD_DIR)/LukOS.img

# 编译器和链接器
NASM = nasm
LD =
DD = dd
MCOPY = mcopy
GCC =

# 编译选项
LD_FLAGS = -T linker.ld
NASM_FLAGS =

GCC_FLAGS := -fno-builtin
GCC_FLAGS += -fno-stack-protector
GCC_FLAGS += -fno-pic
GCC_FLAGS += -fno-pie
GCC_FLAGS += -nostdlib
GCC_FLAGS += -nostdinc

ifeq ($(DEBUG),on)
	NASM_FLAGS += -g
endif

# Run
QEMU = qemu-system-i386 -boot order=a -drive format=raw,file=$(OS_IMG),if=floppy
BOCHS = bochs -f bochsrc -q

ifeq ($(UNAME), Darwin)
	LD = x86_64-elf-ld
	GCC = x86_64-elf-gcc
	GCC_FLAGS += -m64
	LD_FLAGS += -m elf_x86_64
endif

ifeq ($(UNAME), Linux)
	LD = ld
	GCC = gcc
	GCC_FLAGS += -m32
	LD_FLAGS += -m elf_i386
endif

# 默认目标
all: $(OS_IMG)

# 生成软盘镜像文件
$(OS_IMG): $(BIN_TARGETS) $(KERNEL_ELF) $(OBJECTS)
	@echo "Creating floppy image..."  
	$(DD) if=/dev/zero of=$(OS_IMG) bs=512 count=2880
	@mkfs.fat -F 12 -n "LUKOS" $(OS_IMG) >/dev/null 2>&1
	@echo "Creating $< to $@ ..."
	$(DD) if=$(BOOT_BIN) of=$@ bs=1 count=512 skip=62 seek=62 conv=notrunc >/dev/null 2>&1
	$(DD) if=$(LOADER_BIN) of=$@ bs=512 count=1 seek=2 conv=notrunc >/dev/null 2>&1
#	$(DD) if=$(KERNEL_ELF) of=$(KERNEL_SYS) bs=512 conv=sync >/dev/null 2>&1
	@objcopy -O binary $(KERNEL_ELF) $(KERNEL_SYS)
	MTOOLS_SKIP_CHECK=1 $(MCOPY) -i $@ $(KERNEL_SYS) ::
#	@echo "Creating bootable floppy image..."
#    # 写入引导扇区
#	$(DD) if=$(BOOT_BIN) of=$@ bs=1 count=512 skip=62 seek=62 conv=notrunc
#    # 写入加载器
#	$(DD) if=$(LOADER_BIN) of=$@ bs=512 count=1 seek=2 conv=notrunc
#    # 转换内核文件
#	$(DD) if=$(KERNEL_ELF) of=$(KERNEL_SYS) bs=512 conv=sync
#    # 复制内核文件到软盘镜像
#	MTOOLS_SKIP_CHECK=1 $(MCOPY) -i $@ $(KERNEL_SYS) ::

# asm文件编译成bin文件
$(BIN_DIR)/%.bin $(BIN_DIR)/%.map: $(SRC_DIR)/%.asm
	@mkdir -p $(dir $(BIN_DIR)/$*.bin) $(dir $(MAP_DIR)/$*.map)
	@echo "Assembling $< to $@ ..."
	$(NASM) $(NASM_FLAGS) -f bin -o $(BIN_DIR)/$*.bin -l $(MAP_DIR)/$*.map $<

# asm文件编译为obj文件
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
	@mkdir -p $(dir $(OBJ_DIR)/$*.o) $(dir $(MAP_DIR)/$*.map)
	@echo "Compile $< to $@ ..."
	$(NASM) $(NASM_FLAGS) -f elf32 -o $(OBJ_DIR)/$*.o -l $(MAP_DIR)/$*.map $<

# c文件编译成obj文件
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	@echo "Compile $< to $@ ..."
	$(GCC) $(GCC_FLAGS) -c $< -o $@

$(KERNEL_ELF): $(OBJECTS)
	@echo "link all the obj to elf..."
	$(info OBJECTS is: $(OBJECTS))
	ld -m elf_i386 -static $^ -o $@ -Ttext 0xc200

clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)/*
	@echo "Build dir has been cleaned."

run: all
	$(QEMU)
#	 $(BOCHS)

debug: all
#	$(QEMU) -S -s 
	$(BOCHS)

show:
	$(info ASM_SOURCES is: $(ASM_SOURCES))
	$(info BIN_TARGETS is: $(BIN_TARGETS))
	$(info MAP_FILES is: $(MAP_FILES))
	$(info ASM_OBJECTS is: $(ASM_OBJECTS))
	$(info C_SOURCES ie: $(C_SOURCES))
	$(info C_OBJECTS is: $(C_OBJECTS))
	$(info OBJECTS is: $(OBJECTS))

.PHONY: all clean