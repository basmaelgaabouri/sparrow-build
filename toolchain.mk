
TOOLCHAIN_SRC_DIR   := $(ROOTDIR)/toolchain
TOOLCHAIN_BUILD_DIR := $(OUT)/tmp/toolchain
TOOLCHAIN_OUT_DIR   := $(OUT)/host/toolchain

$(TOOLCHAIN_OUT_DIR): | $(ROOTDIR)/toolchain
	# Apply Python 3.7+ Patch
	pushd $(TOOLCHAIN_SRC_DIR)/riscv-gdb/; git reset --hard
	pushd $(TOOLCHAIN_SRC_DIR)/riscv-gdb/; patch -p1 < \
		$(ROOTDIR)/build/patches/riscv-binutils-gdb/0001-Fix-build-issue-with-Python-3.7.patch
	# Configure and build
	pushd $(ROOTDIR); mkdir -p $(TOOLCHAIN_BUILD_DIR)
	pushd $(TOOLCHAIN_BUILD_DIR); $(TOOLCHAIN_SRC_DIR)/configure \
		--prefix=$(TOOLCHAIN_OUT_DIR) \
		--with-arch=rv32gc \
		--with-abi=ilp32
	pushd $(TOOLCHAIN_BUILD_DIR); make clean
	pushd $(TOOLCHAIN_BUILD_DIR); make -j$(shell nproc) newlib

toolchain: $(TOOLCHAIN_OUT_DIR)

TOOLCHAINVP_SRC_DIR   := $(ROOTDIR)/toolchain_vp
TOOLCHAINVP_BUILD_DIR := $(OUT)/tmp/toolchain_vp
TOOLCHAINVP_OUT_DIR   := $(OUT)/host/toolchain_vp

$(TOOLCHAINVP_OUT_DIR): | $(ROOTDIR)/toolchain_vp
	pushd $(ROOTDIR); mkdir -p $(TOOLCHAINVP_BUILD_DIR);
	pushd $(TOOLCHAINVP_BUILD_DIR); $(TOOLCHAINVP_SRC_DIR)/configure \
		--prefix=$(TOOLCHAINVP_OUT_DIR) \
		--with-arch=rv32iv \
		--with-abi=ilp32
	pushd $(TOOLCHAINVP_BUILD_DIR); make clean
	pushd $(TOOLCHAINVP_BUILD_DIR); make -j$(shell nproc) newlib

toolchain_vp: $(TOOLCHAINVP_OUT_DIR)

.PHONY:: toolchain toolchain_vp
