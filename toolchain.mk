
TOOLCHAIN_SRC_DIR   := $(ROOTDIR)/toolchain/riscv-gnu-toolchain
TOOLCHAIN_BUILD_DIR := $(OUT)/tmp/toolchain
TOOLCHAIN_OUT_DIR   := $(CACHE)/toolchain

TOOLCHAINVP_BUILD_DIR := $(OUT)/tmp/toolchain_vp
TOOLCHAINVP_OUT_DIR   := $(CACHE)/toolchain_vp

# TODO(hcindyl): Use toolchain_vp when 32-bit baremetal target is ready
TOOLCHAINIREE_BUILD_DIR  := $(OUT)/tmp/toolchain_iree
TOOLCHAINIREE_OUT_DIR    := $(CACHE)/toolchain_iree

TOOLCHAINLLVM_SRC_DIR        := $(ROOTDIR)/toolchain/llvm-project
TOOLCHAINLLVM_BUILD_DIR      := $(OUT)/tmp/toolchain_llvm


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
		--with-arch=rv32gcv \
		--with-abi=ilp32d
	make -C $(TOOLCHAINVP_BUILD_DIR) clean newlib

toolchain_vp: $(TOOLCHAINVP_OUT_DIR)

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

QEMU_DEPS=$(shell find $(QEMU_SRC_DIR) \( -name '*.c' -o -name '*.h' \) -printf "%p ")

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu,riscv64-linux-user
	make -C $(QEMU_OUT_DIR) -j$(nproc --ignore 2)

qemu: $(QEMU_BINARY)

toolchain_clean:
	rm -rf $(TOOLCHAIN_OUT_DIR) $(TOOLCHAINVP_OUT_DIR) $(OUT)/tmp

qemu_clean:
	rm -rf $(QEMU_OUT_DIR)

.PHONY:: toolchain toolchain_vp qemu toolchain_clean qemu_clean toolchain_llvm
