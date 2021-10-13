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
	if [[ -f "${TOOLCHAIN_BIN}" ]]; then \
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
		--with-arch=rv32imac \
		--with-abi=ilp32
	make -C $(TOOLCHAIN_BUILD_DIR) clean newlib
	make -C $(TOOLCHAIN_BUILD_DIR) clean

$(TOOLCHAINVP_BUILD_DIR):
	mkdir -p $(TOOLCHAINVP_BUILD_DIR)

toolchain_src_vp:
	if [[ -f "${TOOLCHAINVP_BIN}" ]]; then \
		echo "toolchain_vp exists, run 'm toolchain_vp_clean' if you really want to rebuild"; \
	else \
		$(ROOTDIR)/scripts/download-toolchain.sh $(TOOLCHAIN_SRC_DIR) "GCC" "RVV"; \
	fi

$(TOOLCHAINVP_BIN): | toolchain_src_vp $(TOOLCHAINVP_BUILD_DIR)
	cd $(TOOLCHAINVP_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAINVP_OUT_DIR) \
		--with-arch=rv32imv \
		--with-abi=ilp32
	make -C $(TOOLCHAINVP_BUILD_DIR) clean newlib
	make -C $(TOOLCHAINVP_BUILD_DIR) clean

$(OUT)/toolchain.tar.gz: $(TOOLCHAIN_BIN)
	cd $(CACHE) && tar -czf $(OUT)/toolchain.tar.gz toolchain
	cd $(OUT) && sha256sum toolchain.tar.gz > toolchain.tar.gz.sha256sum
	@echo "==========================================================="
	@echo "Toolchain tarball ready at $(OUT)/toolchain.tar.gz"
	@echo "==========================================================="

$(OUT)/toolchain_rvv.tar.gz: $(TOOLCHAINVP_BIN)
	cd $(CACHE) && tar -czf $(OUT)/toolchain_rvv.tar.gz toolchain_vp
	cd $(OUT) && sha256sum toolchain_rvv.tar.gz > toolchain_rvv.tar.gz.sha256sum
	@echo "==========================================================="
	@echo "GCC VP Toolchain tarball ready at $(OUT)/toolchain_rvv.tar.gz"
	@echo "==========================================================="

## Builds the GCC toolchain for the security core and SMC.
#
# Note: this actually builds from source, rather than fetching a release
# tarball, and is most likely not the target you actually want.
#
# This target can take hours to build, and results in a tarball and sha256sum
# called `out/toolchain.tar.gz` and `out/toolchain.tar.gz.sha256sum`, ready for
# upload.
toolchain: $(OUT)/toolchain.tar.gz

## Builds the GCC toolchain for the vector core.
#
# Note: this actually builds from source, rather than fetching a release
# tarball, and is most likely not the target you actually want. Additionally,
# GCC is not typically used for building vector core code -- we use LLVM,
# instead.
#
# This target can take hours to build, and results in a tarball and sha256sum
# called `out/toolchain_rvv.tar.gz` and `out/toolchain_rvv.tar.gz.sha256sum`,
# ready for upload.
toolchain_vp: $(OUT)/toolchain_rvv.tar.gz

toolchain_vp_clean:
	rm -rf $(OUT)/tmp $(CACHE)/toolchain_vp

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
# Prepare a newlib-nano directory for the default link of -lc, -lgloss, etc.
	mkdir -p "$(TOOLCHAINIREE_OUT_DIR)/riscv32-unknown-elf/lib/newlib-nano"
	cd "$(TOOLCHAINIREE_OUT_DIR)/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libc_nano.a libc.a
	cd "$(TOOLCHAINIREE_OUT_DIR)/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libg_nano.a libg.a
	cd "$(TOOLCHAINIREE_OUT_DIR)/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libm_nano.a libm.a
	cd "$(TOOLCHAINIREE_OUT_DIR)/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libgloss_nano.a libgloss.a

$(OUT)/toolchain_iree_rv32.tar.gz: $(TOOLCHAINLLVM_BIN)
	cd $(CACHE) && tar -czf $(OUT)/toolchain_iree_rv32.tar.gz toolchain_iree_rv32imf
	cd $(OUT) && sha256sum toolchain_iree_rv32.tar.gz > toolchain_iree_rv32.tar.gz.sha256sum
	@echo "==========================================================="
	@echo "Toolchain tarball ready at $(OUT)/toolchain_iree_rv32.tar.gz"
	@echo "==========================================================="

## Builds the LLVM toolchain for the vector core.
#
# Note: this actually builds from source, rather than fetching a release
# tarball, and is most likely not the target you actually want.
#
# This target can take hours to build, and results in a tarball and sha256sum
# called `out/toolchain_iree_rv32.tar.gz` and
# `out/toolchain_iree_rv32.tar.gz.sha256sum`, ready for upload.
toolchain_llvm: $(OUT)/toolchain_iree_rv32.tar.gz

## Removes the IREE RV32IMF toolchain from cache/, forcing a re-fetch if needed.
toolchain_llvm_clean:
	rm -rf $(TOOLCHAINIREE_OUT_DIR) $(OUT)/tmp/toolchain

.PHONY:: toolchain toolchain_llvm toolchain_vp toolchain_src toolchain_src_vp toolchain_src_llvm toolchain_vp_clean toolchain_llvm_clean
