# 定义变量
UNAME = $(shell uname -s)

SRC_DIR = src
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
BIN_DIR = $(BUILD_DIR)/bin
MAP_DIR = $(BUILD_DIR)/map

ASM_SOURCES = $(wildcard $(SRC_DIR)/boot/*.asm)
BIN_TARGETS = $(patsubst $(SRC_DIR)/boot/%.asm, $(BIN_DIR)/%.bin, $(ASM_SOURCES))
MAP_FILES = $(patsubst $(SRC_DIR)/boot/%.asm, $(MAP_DIR)/%.map, $(ASM_SOURCES))

C_SOURCES = $(wildcard $(SRC_DIR)/*.c)
OBJ_TARGETS = $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_SOURCES))

# debug模式
DEBUG ?= on
# 启动方式 a:软盘，h硬盘
BOOT ?= a

# Target
BOOT_BIN = $(BIN_DIR)/boot.bin
LOADER_BIN = $(BIN_DIR)/loader.bin
KERNEL_SYS = $(BUILD_DIR)/kernel.sys
OS_IMG = $(BUILD_DIR)/LukOS.img

# 编译器和链接器
NASM = nasm
LD =
DD = dd
MCOPY = mcopy
GCC =

# 编译选项
NASM_FLAGS = -f bin
NASM_DEBUG_FLAGS = -g
LD_FLAGS = -T linker.ld
GCC_FLAGS = -fno-builtin -fno-stack-protector -fno-pie -nostdlib

ifeq ($(DEBUG),on)
	NASM_FLAGS += -l $(MAP_DIR)/$*.map
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

$(SYMBOL): $(OBJ_TARGETS)
	@echo "Linking kernal to binary..."
	$(LD) $(LD_FLAGS) -o $@ $^

# 生成软盘镜像文件
$(OS_IMG): $(BIN_TARGETS) $(OBJ_TARGETS) floppy
	@echo "Creating $< to $@ ..."
	$(DD) if=$(BOOT_BIN) of=$@ bs=1 count=1474560 skip=62 seek=62 conv=notrunc >/dev/null 2>&1
	$(DD) if=$(LOADER_BIN) of=$(KERNEL_SYS) bs=512 conv=sync >/dev/null 2>&1
	$(MCOPY) -i $@ $(KERNEL_SYS) ::

# c文件编译成obj文件
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@echo "Compile $< to $@ ..."
	$(GCC) $(GCC_FLAGS) -c $< -o $@

# asm文件编译成bin文件
$(BIN_DIR)/%.bin: $(SRC_DIR)/boot/%.asm | $(BIN_DIR) $(MAP_DIR)
	@echo "Assembling $< to $@ ..."
	$(NASM) $(NASM_FLAGS) -o $@ $<

$(BUILD_DIR) $(OBJ_DIR) $(BIN_DIR) $(MAP_DIR):
	@mkdir -p $@
	@echo "Create direcotory: $@"

# 创建FAT12格式软盘
floppy:
	$(DD) if=/dev/zero of=$(OS_IMG) bs=1024 count=1440 
	@mkfs.fat -F 12 -n "LUKOS" $(OS_IMG) >/dev/null 2>&1

clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)/**/*.bin
	@rm -rf $(BUILD_DIR)/**/*.map
	@rm -rf $(BUILD_DIR)/*.elf
	@rm -rf $(BUILD_DIR)/**/*.o
	@echo "Build dir has been cleaned."

run: all
	$(QEMU)
#	 $(BOCHS)

debug: all
#	$(QEMU) -S -s 
	$(BOCHS)

.PHONY: all clean