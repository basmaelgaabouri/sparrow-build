
TOOLCHAIN_SRC_DIR   := $(ROOTDIR)/toolchain
TOOLCHAIN_BUILD_DIR := $(OUT)/tmp/toolchain
TOOLCHAIN_OUT_DIR   := $(OUT)/host/toolchain

TOOLCHAINVP_BUILD_DIR := $(OUT)/tmp/toolchain_vp
TOOLCHAINVP_OUT_DIR   := $(OUT)/host/toolchain_vp

$(TOOLCHAIN_OUT_DIR): | $(ROOTDIR)/toolchain
	mkdir -p $(TOOLCHAIN_BUILD_DIR)
	cd $(TOOLCHAIN_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAIN_OUT_DIR) \
		--with-arch=rv32gc \
		--with-abi=ilp32
	make -C $(TOOLCHAIN_BUILD_DIR) clean newlib

toolchain: $(TOOLCHAIN_OUT_DIR)

$(TOOLCHAINVP_OUT_DIR): | $(ROOTDIR)/toolchain
	mkdir -p $(TOOLCHAINVP_BUILD_DIR);
	cd $(TOOLCHAINVP_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAINVP_OUT_DIR) \
		--with-arch=rv32iv \
		--with-abi=ilp32
	make -C $(TOOLCHAINVP_BUILD_DIR) clean newlib

toolchain_vp: $(TOOLCHAINVP_OUT_DIR)

.PHONY:: toolchain toolchain_vp
