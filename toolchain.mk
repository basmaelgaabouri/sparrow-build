QEMU_SRC_DIR          := $(ROOTDIR)/toolchain/riscv-qemu
QEMU_OUT_DIR          := $(OUT)/host/qemu
QEMU_BINARY           := $(QEMU_OUT_DIR)/riscv32-softmmu/qemu-system-riscv32

toolchain_rust: $(RUSTDIR)/bin/rustc

$(RUST_OUT_DIR):
	mkdir -p $(RUSTDIR)

$(RUSTDIR)/bin/rustup: | $(RUST_OUT_DIR)
	bash -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path'

$(RUSTDIR)/bin/rustc: | $(RUST_OUT_DIR) $(RUSTDIR)/bin/rustup
	$(RUSTDIR)/bin/rustup +nightly target add riscv32imc-unknown-none-elf

# IREE toolchain
# TODO(hcindyl): This will eventually be combined with toolchain_vp
$(TOOLCHAINIREE_OUT_DIR): | $(TOOLCHAIN_SRC_DIR)
	mkdir -p $(TOOLCHAINIREE_BUILD_DIR);
	cd $(TOOLCHAINIREE_BUILD_DIR) && $(TOOLCHAIN_SRC_DIR)/configure \
		--srcdir=$(TOOLCHAIN_SRC_DIR) \
		--prefix=$(TOOLCHAINIREE_OUT_DIR) \
		--with-arch=rv64gc \
		--with-abi=lp64d \
		--with-cmodel=medany
	make -C $(TOOLCHAINIREE_BUILD_DIR) clean linux

toolchain_iree: $(TOOLCHAINIREE_OUT_DIR)

# Build with 64-bit linux config.
# TODO(hcindyl): Move to 32-bit baremetal config
$(TOOLCHAINLLVM_BUILD_DIR): | $(TOOLCHAINIREE_OUT_DIR)
	cmake -B $(TOOLCHAINLLVM_BUILD_DIR) \
		-DCMAKE_INSTALL_PREFIX=$(TOOLCHAINIREE_OUT_DIR) \
		-DCMAKE_C_COMPILER=clang  -DCMAKE_CXX_COMPILER=clang++ \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD="RISCV" \
		-DLLVM_ENABLE_PROJECTS="clang"  \
		-DLLVM_DEFAULT_TARGET_TRIPLE="riscv64-unknown-linux-gnu" \
		-DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
		-DDEFAULT_SYSROOT=../sysroot \
		-G Ninja \
		$(TOOLCHAINLLVM_SRC_DIR)/llvm
	cmake --build $(TOOLCHAINLLVM_BUILD_DIR) --target install

toolchain_llvm: $(TOOLCHAINLLVM_BUILD_DIR)

toolchain_llvm_clean:
	rm -rf $(TOOLCHAINLLVM_BUILD_DIR) $(TOOLCHAINIREE_BUILD_DIR) $(TOOLCHAINIREE_OUT_DIR)

QEMU_DEPS=$(wildcard $(QEMU_SRC_DIR)/**/*.[ch])
$(warning QEMU_DEPS is $(QEMU_DEPS))

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu,riscv64-linux-user
	make -C $(QEMU_OUT_DIR) -j$(nproc --ignore 2)

qemu: $(QEMU_BINARY)

$(OUT)/tmp: | $(OUT)
	mkdir -p $(OUT)/tmp

$(OUT)/tmp/toolchain_rvv-intrinsic.tar.gz: | $(OUT)/tmp
	fileutil cp /x20/teams/cerebra-hw/sparrow/toolchain_cache/toolchain_rvv-intrinsic.tar.gz $(OUT)

$(ROOTDIR)/cache/toolchain: $(OUT)/toolchain_rvv-intrinsic.tar.gz
	tar -C $(ROOTDIR)/cache -xf $(OUT)/toolchain_rvv-intrinsic.tar.gz

toolchain_clean:
	rm -rf $(OUT)/tmp $(CACHE)/toolchain $(CACHE)/toolchain_vp

qemu_clean:
	rm -rf $(QEMU_OUT_DIR)

.PHONY:: qemu toolchain_clean qemu_clean toolchain_llvm
