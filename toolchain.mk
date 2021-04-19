QEMU_SRC_DIR          := $(ROOTDIR)/toolchain/riscv-qemu
QEMU_OUT_DIR          := $(OUT)/host/qemu
QEMU_BINARY           := $(QEMU_OUT_DIR)/riscv32-softmmu/qemu-system-riscv32

toolchain_rust: $(RUSTDIR)/bin/rustc $(RUSTDIR)/bin/elf2tab

$(RUST_OUT_DIR):
	mkdir -p $(RUSTDIR)

$(RUSTDIR)/bin/rustup: | $(RUST_OUT_DIR)
	bash -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path'

$(RUSTDIR)/bin/rustc: | $(RUST_OUT_DIR) $(RUSTDIR)/bin/rustup
	$(RUSTDIR)/bin/rustup +nightly target add riscv32imc-unknown-none-elf

$(RUSTDIR)/bin/elf2tab: $(RUSTDIR)/bin/rustc
	cargo install elf2tab --version 0.6.0

QEMU_DEPS=$(wildcard $(QEMU_SRC_DIR)/**/*.[ch])

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu,riscv64-linux-user
	make -C $(QEMU_OUT_DIR) -j$(nproc --ignore 2)

qemu: $(QEMU_BINARY)

$(OUT)/tmp: | $(OUT)
	mkdir -p $(OUT)/tmp

$(CACHE):
	mkdir -p $(CACHE)

$(OUT)/tmp/toolchain_rvv-intrinsic.tar.gz: | $(OUT)/tmp
	fileutil cp /x20/teams/cerebra-hw/sparrow/toolchain_cache/toolchain_rvv-intrinsic.tar.gz $(OUT)/tmp

$(ROOTDIR)/cache/toolchain: | $(OUT)/tmp/toolchain_rvv-intrinsic.tar.gz $(CACHE)
	tar -C $(ROOTDIR)/cache -xf $(OUT)/tmp/toolchain_rvv-intrinsic.tar.gz

$(OUT)/tmp/toolchain_iree_rvv-intrinsic.tar.gz: | $(OUT)/tmp
	fileutil cp /x20/teams/cerebra-hw/sparrow/toolchain_cache/toolchain_iree_rvv-intrinsic.tar.gz $(OUT)/tmp

$(CACHE)/toolchain_iree: | $(OUT)/tmp/toolchain_iree_rvv-intrinsic.tar.gz $(CACHE)
	tar -C $(CACHE) -xf $(OUT)/tmp/toolchain_iree_rvv-intrinsic.tar.gz

install_llvm: $(CACHE)/toolchain_iree

toolchain_clean:
	rm -rf $(OUT)/tmp $(CACHE)/toolchain $(CACHE)/toolchain_vp

qemu_clean:
	rm -rf $(QEMU_OUT_DIR)

.PHONY:: qemu toolchain_clean qemu_clean install_llvm
