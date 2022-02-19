QEMU_SRC_DIR          := $(ROOTDIR)/toolchain/riscv-qemu
QEMU_OUT_DIR          := $(OUT)/host/qemu
QEMU_BINARY           := $(QEMU_OUT_DIR)/riscv32-softmmu/qemu-system-riscv32

KATA_RUST_TOOLCHAIN   := ${RUSTDIR}/toolchains/$(KATA_RUST_VERSION)-x86_64-unknown-linux-gnu

## Installs the rust toolchains for kata and matcha_tock to cache/.
toolchain_rust:  kata_toolchain matcha_toolchain

## Installs the kata rust toolchain and elf2tab to cache/.
kata_toolchain: $(KATA_RUST_TOOLCHAIN) $(RUSTDIR)/bin/elf2tab

$(KATA_RUST_TOOLCHAIN):
	./scripts/install-rust-toolchain.sh "$(RUSTDIR)" "$(KATA_RUST_VERSION)" riscv32imac-unknown-none-elf

$(RUSTDIR)/bin/elf2tab: $(RUSTDIR)/bin/rustc
	cargo install elf2tab --version 0.6.0

QEMU_DEPS=$(wildcard $(QEMU_SRC_DIR)/**/*.[ch])

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu,riscv32-linux-user
	$(MAKE) -C $(QEMU_OUT_DIR)

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

.PHONY:: qemu toolchain_clean qemu_clean install_llvm install_gcc kata_toolchain
