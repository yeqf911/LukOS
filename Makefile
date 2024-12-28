# 定义变量
SRC_DIR=src
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj
BIN_DIR=$(BUILD_DIR)/bin

ASM_SRC_FILES=$(wildcard $(SRC_DIR)/*.asm)
OBJ_FILES=$(patsubst $(SRC_DIR)/%.asm, $(OBJ_DIR)/%.o, $(ASM_SRC_FILES))
BIN_FILES=$(patsubst $(SRC_DIR)/%.asm, $(BIN_DIR)/%.bin, $(ASM_SRC_FILES))

# OUTPUT
BIN=$(BIN_DIR)/boot.bin
IMG=$(BUILD_DIR)/LukOS.img
SYMBOL=$(BUILD_DIR)/boot.elf

# RUN
QEMU=qemu-system-i386
QEMU_OPS=-drive format=raw,file=$(IMG)

# 编译器和链接器
NASM=nasm
LD=ld

# 编译选项
NASM_FLAGS=-f elf32 -D DEBUG -g -F dwarf
LD_FLAGS=-m elf_i386

# 默认目标
all: prepare $(BIN) $(SYMBOL) $(IMG)

$(SYMBOL): $(OBJ_FILES)
	@echo "Linking kernal to binary..."
	$(LD) $(LD_FLAGS) -Ttext 0x7C00 -o $@ $^

$(BIN): $(ASM_SRC_FILES)
	@echo "Assembling $< to $@ ..."
	$(NASM) -f bin $< -o $@

$(IMG): $(BIN)
	@echo "Creating $< to $@ ..."
	@dd if=$< of=$@ bs=512 count=1

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
	@echo "Assembling $< to $@ ..."
	$(NASM) $(NASM_FLAGS) $< -o $@

prepare: $(BUILD_DIR) $(OBJ_DIR) $(BIN_DIR)

$(BUILD_DIR) $(OBJ_DIR) $(BIN_DIR):
	@mkdir -p $@
	@echo "Create direcotory: $@"

clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	@echo "Build dir has been cleaned."

run: all
	$(QEMU) $(QEMU_OPS)

debug: all
	$(QEMU) $(QEMU_OPS) -S -s

.PHONE: all clean prepare

# 编译规则
# %.o: %.asm
# 	$(NASM) $(NASM_DEBUG) $(NASM_FLAGS) $< -o $@

# %.bin: %.asm
# 	$(NASM) -f bin $< -o $@

# clean:
# 	rm -f $(TARGET) $(OBJECTS)
# $(info SRC_FILES: $(SRC_FILES))  

# compile:
# 	mkdir -p ../build/image
# 	nasm -f bin boot.asm -o ../build/image/boot.bin
# 	nasm -f elf32 -D DEBUG -g -F dwarf boot.asm -o ../build/image/boot.o
# 	ld -m elf_i386 -Ttext 0x7C00 -e _start -o ../build/image/boot.elf ../build/image/boot.o

# install: compile
# 	dd if=../build/image/boot.bin of=../build/image/boot.img bs=512 count=1

# run: install
# 	qemu-system-i386 -drive format=raw,file=../build/image/boot.img -vga std

# debug: install
# 	qemu-system-i386 -drive format=raw,file=../build/image/boot.img -vga std -S -s

# cleans:
# 	rm -rf ../build/image