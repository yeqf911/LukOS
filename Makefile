# 定义变量
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

# RUN
QEMU=qemu-system-i386
QEMU_OPS=-boot order=a -drive format=raw,file=$(IMG),if=floppy

# 编译器和链接器
NASM=nasm
LD=ld
DD=dd
MCOPY=mcopy
RM=rm -rf
GCC=gcc

# 编译选项
NASM_FLAGS=-f elf32 -D DEBUG -g -F dwarf
LD_FLAGS=-m elf_i386 -T $(SRC_DIR)/linker.ld
GCC_FLAGS=-m32 -fno-builtin -fno-stack-protector -fno-pie -nostdlib

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
	$(QEMU) $(QEMU_OPS)

debug: all
	$(QEMU) $(QEMU_OPS) -S -s

.PHONE: all clean prepare