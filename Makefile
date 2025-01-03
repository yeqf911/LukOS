# 定义变量
UNAME=$(shell uname -s)
SRC_DIR=src
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj
BIN_DIR=$(BUILD_DIR)/bin

ASM_SRC_FILES=$(wildcard $(SRC_DIR)/*.asm)
ASM_OBJ_FILES=$(patsubst $(SRC_DIR)/%.asm, $(OBJ_DIR)/%.o, $(ASM_SRC_FILES))
BIN_FILES=$(patsubst $(SRC_DIR)/%.asm, $(BIN_DIR)/%.bin, $(ASM_SRC_FILES))

C_SRC_FILES=$(wildcard $(SRC_DIR)/*.c)
C_OBJ_FILES=$(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_SRC_FILES))

# OUTPUT
BOOT=$(BIN_DIR)/boot.bin
KERNEL=$(BIN_DIR)/kernel.bin
OS=$(BUILD_DIR)/kernel.sys
IMG=$(BUILD_DIR)/LukOS.img
SYMBOL=$(BUILD_DIR)/LukOS.elf

# 编译器和链接器
NASM=nasm
LD=
DD=dd
MCOPY=mcopy
RM=rm -rf
GCC=

# 编译选项
NASM_FLAGS=-D DEBUG -g -F dwarf
LD_FLAGS=-T linker.ld
GCC_FLAGS=-fno-builtin -fno-stack-protector -fno-pie -nostdlib

# debug
QEMU=qemu-system-i386
QEMU_OPS=-boot order=a -drive format=raw,file=$(IMG),if=floppy
BOCHS=bochs

ifeq ($(UNAME), Darwin)
	LD=x86_64-elf-ld
	GCC=x86_64-elf-gcc
	GCC_FLAGS += -m64
	NASM_FLAGS += -felf64
	LD_FLAGS += -m elf_x86_64
endif

ifeq ($(UNAME), Linux)
	LD=ld
	GCC=gcc
	GCC_FLAGS += -m32
	NASM_FLAGS += -felf32
	LD_FLAGS += -m elf_i386
endif

# RUN
ifeq ($(UNAME), Darwin)
	RUN=$(BOCHS) -f bochsrc -q
else
	RUN=$(QEMU) $(QEMU_OPS)
endif

# 默认目标
all: prepare $(SYMBOL) $(IMG)

$(SYMBOL): $(ASM_OBJ_FILES) $(C_OBJ_FILES)
	@echo "Linking kernal to binary..."
	$(LD) $(LD_FLAGS) -o $@ $^

$(IMG): $(BIN_FILES)
	@echo "Creating $< to $@ ..."
	$(DD) if=/dev/zero of=$@ bs=512 count=2880
	$(DD) if=$(BOOT) of=$@ bs=512 count=1 conv=notrunc
	$(DD) if=$(KERNEL) of=$(OS) bs=512 conv=sync
	$(MCOPY) -i $@ $(OS) ::

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
	@echo "Assembling $< to $@ ..."
	$(NASM) $(NASM_FLAGS) $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "Compile $< to $@ ..."
	$(GCC) $(GCC_FLAGS) -c $< -o $@

$(BIN_DIR)/%.bin: $(SRC_DIR)/%.asm
	@echo "Assembling $< to $@ ..."
	$(NASM) -f bin $< -o $@

prepare: $(BUILD_DIR) $(OBJ_DIR) $(BIN_DIR)

$(BUILD_DIR) $(OBJ_DIR) $(BIN_DIR):
	@mkdir -p $@
	@echo "Create direcotory: $@"

clean:
	@echo "Cleaning..."
	$(RM) $(BUILD_DIR)
	@echo "Build dir has been cleaned."

run: all
	$(RUN)

debug: all
	$(QEMU) $(QEMU_OPS) -S -s

.PHONE: all clean prepare