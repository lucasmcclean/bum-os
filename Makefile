QEMU := qemu-system-i386

BUILD := build
VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//'; echo "0.0.0")
IMG := $(BUILD)/bum-$(VERSION).img

STAGE_ONE := $(BUILD)/stage_one.bin
KERNEL := $(BUILD)/kernel

all: $(IMG)

# Build the bootloader
boot: $(BUILD)
	nasm -f bin bootloader/stage_one.asm -o $(STAGE_ONE)

# Build the kernel
kernel: $(BUILD)
	cargo build --manifest-path kernel/Cargo.toml --target-dir $(KERNEL)

# Build and write the image
$(IMG): boot kernel
	dd if=/dev/zero of=$@ bs=512 count=2880
	dd if=$(STAGE_ONE) of=$@ conv=notrunc
	KERNEL=$(KERNEL)/debug/bum_os_kernel; \
	SECTORS=$$(($(shell stat -c%s $$KERNEL)/512 + 1)); \
	dd if=$$KERNEL of=$@ bs=512 seek=1 conv=notrunc count=$$SECTORS

# Run the image in Qemu
run: $(IMG)
	$(QEMU) -fda $< -boot a -m 512M

# Clean the build folder, cargo, and image
clean:
	rm -f $(STAGE_ONE) $(IMG)
	cargo clean --manifest-path kernel/Cargo.toml

# Create the build directory if it does not exist
$(BUILD):
	mkdir -p $(BUILD)

.PHONY: all boot kernel run clean
