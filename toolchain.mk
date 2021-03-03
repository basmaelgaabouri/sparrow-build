
TOOLCHAIN_SRC_DIR   := $(ROOTDIR)/toolchain
TOOLCHAIN_BUILD_DIR := $(OUT)/tmp/toolchain
TOOLCHAIN_OUT_DIR   := $(OUT)/host/toolchain

TOOLCHAINVP_BUILD_DIR := $(OUT)/tmp/toolchain_vp
TOOLCHAINVP_OUT_DIR   := $(OUT)/host/toolchain_vp

QEMU_SRC_DIR          := $(TOOLCHAIN_SRC_DIR)/riscv-qemu
QEMU_OUT_DIR          := $(OUT)/host/qemu
QEMU_BINARY           := $(QEMU_OUT_DIR)/riscv32-softmmu/qemu-system-riscv32

$(TOOLCHAIN_OUT_DIR): | $(TOOLCHAIN_SRC_DIR)
	mkdir -p $(TOOLCHAIN_BUILD_DIR)
	cd $(TOOLCHAIN_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAIN_OUT_DIR) \
		--with-arch=rv32gc \
		--with-abi=ilp32
	make -C $(TOOLCHAIN_BUILD_DIR) clean newlib

toolchain: $(TOOLCHAIN_OUT_DIR)

$(TOOLCHAINVP_OUT_DIR): | $(TOOLCHAIN_SRC_DIR)
	mkdir -p $(TOOLCHAINVP_BUILD_DIR);
	cd $(TOOLCHAINVP_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAINVP_OUT_DIR) \
		--with-arch=rv32iv \
		--with-abi=ilp32
	make -C $(TOOLCHAINVP_BUILD_DIR) clean newlib

toolchain_vp: $(TOOLCHAINVP_OUT_DIR)

QEMU_DEPS=$(shell find $(QEMU_SRC_DIR) \( -name '*.c' -o -name '*.h' \) -printf "%p ")

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu
	make -C $(QEMU_OUT_DIR) -j$(nproc)

qemu: $(QEMU_BINARY)

.PHONY:: toolchain toolchain_vp qemu
