QEMU_SRC_DIR          := $(ROOTDIR)/toolchain/riscv-qemu
QEMU_OUT_DIR          := $(OUT)/host/qemu
QEMU_BINARY           := $(QEMU_OUT_DIR)/riscv32-softmmu/qemu-system-riscv32

## Installs the rust toolchain to cache/, including rustc and elf2tab.
toolchain_rust: $(RUSTDIR)/bin/rustc $(RUSTDIR)/bin/elf2tab

$(RUST_OUT_DIR):
	mkdir -p $(RUSTDIR)

$(RUSTDIR)/bin/rustup: | $(RUST_OUT_DIR)
	bash -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path'

$(RUSTDIR)/bin/rustc: | $(RUST_OUT_DIR) $(RUSTDIR)/bin/rustup
	$(RUSTDIR)/bin/rustup +$(KATA_RUST_VERSION) target add riscv32imac-unknown-none-elf

$(RUSTDIR)/bin/elf2tab: $(RUSTDIR)/bin/rustc
	cargo install elf2tab --version 0.6.0

QEMU_DEPS=$(wildcard $(QEMU_SRC_DIR)/**/*.[ch])

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu,riscv32-linux-user
	make -C $(QEMU_OUT_DIR) -j$(nproc --ignore 2)

## Builds and installs the QEMU RISCV32 simulator.
#
# Sources are in toolchain/riscv-qemu, while outputs are stored in
# out/host/qemu.
qemu: $(QEMU_BINARY)

$(OUT)/tmp: | $(OUT)
	mkdir -p $(OUT)/tmp

$(CACHE):
	mkdir -p $(CACHE)

$(CACHE)/toolchain: | $(CACHE)
	./scripts/install-toolchain.sh gcc

$(CACHE)/toolchain_iree_rv32imf: | $(CACHE)
	./scripts/install-toolchain.sh llvm

## Installs the GCC compiler for rv32imac
#
# Requires network access. This fetches the toolchain from the GCP archive and
# extracts it locally to the cache/.
install_gcc: $(CACHE)/toolchain

## Installs the LLVM compiler for rv32imf
#
# Requires network access. This fetches the toolchain from the GCP archive and
# extracts it locally to the cache/.
install_llvm: $(CACHE)/toolchain_iree_rv32imf

## Cleans up the toolchain from the cache directory
#
# Generally not needed to be run unless something has changed or broken in the
# caching mechanisms built into the build system.
toolchain_clean:
	rm -rf $(OUT)/tmp $(CACHE)/toolchain

## Removes only the QEMU build artifacts from out/
qemu_clean:
	rm -rf $(QEMU_OUT_DIR)

.PHONY:: qemu toolchain_clean qemu_clean install_llvm install_gcc
