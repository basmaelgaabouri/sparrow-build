TOOLCHAIN_SRC_DIR   := $(OUT)/tmp/toolchain/riscv-gnu-toolchain
TOOLCHAIN_BUILD_DIR := $(OUT)/tmp/toolchain/build_toolchain
TOOLCHAIN_OUT_DIR   := $(CACHE)/toolchain
TOOLCHAIN_BIN       := $(TOOLCHAIN_OUT_DIR)/bin/riscv32-unknown-elf-gcc

TOOLCHAINVP_BUILD_DIR := $(OUT)/tmp/toolchain/build_toolchain_vp
TOOLCHAINVP_OUT_DIR   := $(CACHE)/toolchain_vp
TOOLCHAINVP_BIN       := $(TOOLCHAINVP_OUT_DIR)/bin/riscv32-unknown-elf-gcc

# TODO(hcindyl): Use toolchain_vp when 32-bit baremetal target is ready
TOOLCHAINIREE_SRC_DIR   := $(OUT)/tmp/toolchain/riscv-gnu-toolchain_iree
TOOLCHAINIREE_BUILD_DIR  := $(OUT)/tmp/toolchain/build_toolchain_iree
TOOLCHAINIREE_OUT_DIR    := $(CACHE)/toolchain_iree_rv32imf
TOOLCHAINIREE_BIN        := $(TOOLCHAINIREE_OUT_DIR)/bin/riscv32-unknown-elf-gdb
TOOLCHAINLLVM_SRC_DIR    := $(OUT)//tmp/toolchain/llvm-project
TOOLCHAINLLVM_BUILD_DIR  := $(OUT)/tmp/toolchain/build_toolchain_llvm
TOOLCHAINLLVM_BIN        := $(TOOLCHAINIREE_OUT_DIR)/bin/clang


toolchain_src:
	if [[ -f "${TOOLCHAINVP_BIN}" ]]; then \
		echo "Toolchain exists, run 'm toolchain_clean' if you really want to rebuild"; \
	else \
		$(ROOTDIR)/scripts/download-toolchain.sh $(TOOLCHAIN_SRC_DIR); \
	fi

$(TOOLCHAIN_BUILD_DIR):
	mkdir -p $(TOOLCHAIN_BUILD_DIR)

$(TOOLCHAIN_BIN): | toolchain_src $(TOOLCHAIN_BUILD_DIR)
	cd $(TOOLCHAIN_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAIN_OUT_DIR) \
		--with-arch=rv32gc \
		--with-abi=ilp32
	make -C $(TOOLCHAIN_BUILD_DIR) clean newlib
	make -C $(TOOLCHAIN_BUILD_DIR) clean

$(TOOLCHAINVP_BUILD_DIR):
	mkdir -p $(TOOLCHAINVP_BUILD_DIR)

$(TOOLCHAINVP_BIN): $(TOOLCHAIN_BIN) | $(TOOLCHAINVP_BUILD_DIR)
	cd $(TOOLCHAINVP_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAINVP_OUT_DIR) \
		--with-arch=rv32imv \
		--with-abi=ilp32
	make -C $(TOOLCHAINVP_BUILD_DIR) clean newlib
	make -C $(TOOLCHAINVP_BUILD_DIR) clean

$(OUT)/toolchain_rvv-intrinsic.tar.gz: $(TOOLCHAINVP_BIN)
	cd $(CACHE) && tar -czf $(OUT)/toolchain_rvv-intrinsic.tar.gz toolchain toolchain_vp
	@echo "==========================================================="
	@echo "Toolchain tarball ready at $(OUT)/toolchain_rvv-intrinsic.tar.gz"
	@echo "==========================================================="

toolchain: $(OUT)/toolchain_rvv-intrinsic.tar.gz

toolchain_src_llvm:
	if [[ -f "${TOOLCHAINLLVM_BIN}" ]]; then \
		echo "Toolchain for LLVM exists, run 'm toolchain_llvm_clean' if you really want to rebuild"; \
	else \
		$(ROOTDIR)/scripts/download-toolchain.sh $(TOOLCHAINIREE_SRC_DIR) "LLVM"; \
	fi

# IREE toolchain
# TODO(hcindyl): This will eventually be combined with toolchain_vp
$(TOOLCHAINIREE_BUILD_DIR):
	mkdir -p $(TOOLCHAINIREE_BUILD_DIR)

$(TOOLCHAINIREE_BIN): | toolchain_src_llvm $(TOOLCHAINIREE_BUILD_DIR)
	cd $(TOOLCHAINIREE_BUILD_DIR) && $(TOOLCHAINIREE_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAINIREE_SRC_DIR) \
		--prefix=$(TOOLCHAINIREE_OUT_DIR) \
		--with-arch=rv32imf \
		--with-abi=ilp32 \
		--with-cmodel=medany
	make -C $(TOOLCHAINIREE_BUILD_DIR) clean newlib
	make -C $(TOOLCHAINIREE_BUILD_DIR) clean

# Build with 32-bit baremetal config.
$(TOOLCHAINLLVM_BIN): $(TOOLCHAINIREE_BIN)
	cmake -B $(TOOLCHAINLLVM_BUILD_DIR) \
		-DCMAKE_INSTALL_PREFIX=$(TOOLCHAINIREE_OUT_DIR) \
		-DCMAKE_C_COMPILER=clang  -DCMAKE_CXX_COMPILER=clang++ \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD="RISCV" \
		-DLLVM_ENABLE_PROJECTS="clang;lld"  \
		-DLLVM_DEFAULT_TARGET_TRIPLE="riscv32-unknown-elf" \
		-DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
		-DDEFAULT_SYSROOT=../riscv32-unknown-elf \
		-G Ninja \
		$(TOOLCHAINLLVM_SRC_DIR)/llvm
	cmake --build $(TOOLCHAINLLVM_BUILD_DIR) --target install
	cmake --build $(TOOLCHAINLLVM_BUILD_DIR) --target clean

$(OUT)/toolchain_iree_rv32.tar.gz: $(TOOLCHAINLLVM_BIN)
	cd $(CACHE) && tar -czf $(OUT)/toolchain_iree_rv32.tar.gz toolchain_iree_rv32imf
	@echo "==========================================================="
	@echo "Toolchain tarball ready at $(OUT)/toolchain_iree_rv32.tar.gz"
	@echo "==========================================================="

toolchain_llvm: $(OUT)/toolchain_iree_rv32.tar.gz

toolchain_llvm_clean:
	rm -rf $(TOOLCHAINIREE_OUT_DIR) $(OUT)/tmp/toolchain

.PHONY:: toolchain toolchain_llvm
