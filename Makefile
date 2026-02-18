QEMU := qemu-system-i386

BUILD_DIR := build
VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//'; echo "0.0.0")
IMG := $(BUILD_DIR)/bum-$(VERSION).img

STAGE_ONE := $(BUILD_DIR)/stage_one.bin
STAGE_TWO := $(BUILD_DIR)/stage_two.bin
KERNEL := $(BUILD_DIR)/kernel

all: $(IMG)

# Build the bootloader
boot: $(BUILD_DIR)
	nasm -f bin bootloader/stage_one.asm -o $(STAGE_ONE)
	nasm -f bin bootloader/stage_two.asm -o $(STAGE_TWO)

# Test the bootloader without the kernel
test-boot: boot
	dd if=/dev/zero of=$(BUILD_DIR)/boot.img bs=512 count=2880
	dd if=$(STAGE_ONE) of=$(BUILD_DIR)/boot.img conv=notrunc
	dd if=$(STAGE_TWO) of=$(BUILD_DIR)/boot.img bs=512 seek=1 conv=notrunc
	$(QEMU) -fda $(BUILD_DIR)/boot.img -boot a


# Build the kernel
kernel: $(BUILD_DIR)
	@cd kernel && \
	cargo +nightly build \
		--target x86_64-unknown-none.json \
		--target-dir ../$(KERNEL)

# Build and write the image
$(IMG): boot kernel
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(STAGE_ONE) of=$@ conv=notrunc
	dd if=$(STAGE_TWO) of=$@ bs=512 seek=1 conv=notrunc
	KERNEL=$(KERNEL)/debug/kernel; \
	STAGE2_SECTORS=$$(($(shell stat -c%s $(STAGE_TWO))/512 + 1)); \
	KERNEL_SECTORS=$$(($(shell stat -c%s $$KERNEL)/512 + 1)); \
	dd if=$$KERNEL of=$@ bs=512 seek=$$((1 + $$STAGE2_SECTORS)) conv=notrunc count=$$KERNEL_SECTORS

# Run the image in Qemu
run: $(IMG)
	$(QEMU) -fda $< -boot a -m 512M

# Clean the build folder, cargo, and image
clean:
	rm -f $(STAGE_ONE) $(IMG)
	cargo clean --manifest-path kernel/Cargo.toml

# Create the build directory if it does not exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all boot kernel run clean
