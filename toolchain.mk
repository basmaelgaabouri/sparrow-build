QEMU_SRC_DIR          := $(ROOTDIR)/toolchain/riscv-qemu
QEMU_OUT_DIR          := $(OUT)/host/qemu
QEMU_BINARY           := $(QEMU_OUT_DIR)/riscv32-softmmu/qemu-system-riscv32

toolchain_rust: $(RUSTDIR)/bin/rustc $(RUSTDIR)/bin/elf2tab

$(RUST_OUT_DIR):
	mkdir -p $(RUSTDIR)

$(RUSTDIR)/bin/rustup: | $(RUST_OUT_DIR)
	bash -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path'

$(RUSTDIR)/bin/rustc: | $(RUST_OUT_DIR) $(RUSTDIR)/bin/rustup
	$(RUSTDIR)/bin/rustup +nightly-2021-08-05 target add riscv32imac-unknown-none-elf

$(RUSTDIR)/bin/elf2tab: $(RUSTDIR)/bin/rustc
	cargo install elf2tab --version 0.6.0

QEMU_DEPS=$(wildcard $(QEMU_SRC_DIR)/**/*.[ch])

$(QEMU_OUT_DIR): | $(QEMU_SRC_DIR)
	mkdir -p $(QEMU_OUT_DIR);

$(QEMU_BINARY): $(QEMU_DEPS) | $(QEMU_OUT_DIR)
	cd $(QEMU_OUT_DIR) && $(QEMU_SRC_DIR)/configure \
		--target-list=riscv32-softmmu,riscv32-linux-user
	make -C $(QEMU_OUT_DIR) -j$(nproc --ignore 2)

qemu: $(QEMU_BINARY)

$(OUT)/tmp: | $(OUT)
	mkdir -p $(OUT)/tmp

$(CACHE):
	mkdir -p $(CACHE)

# TODO: Use publically accessible URLs for toolchain tarballs.
$(OUT)/tmp/toolchain.tar.gz: | $(OUT)/tmp
	fileutil cp /x20/teams/cerebra-hw/sparrow/toolchain_cache/toolchain.tar.gz $(OUT)/tmp

$(ROOTDIR)/cache/toolchain: | $(OUT)/tmp/toolchain.tar.gz $(CACHE)
	tar -C $(ROOTDIR)/cache -xf $(OUT)/tmp/toolchain.tar.gz

$(OUT)/tmp/toolchain_iree_rv32.tar.gz: | $(OUT)/tmp
	wget -P $(OUT)/tmp https://storage.googleapis.com/iree-shared-files/toolchain_iree_rv32.tar.gz

# Prepare a newlib-nano directory for the default link of -lc, -lgloss, etc.
# TODO(hcindyl): Remove the duped symlink creation once we switched to a toolchain from CI.
$(CACHE)/toolchain_iree_rv32imf: | $(OUT)/tmp/toolchain_iree_rv32.tar.gz $(CACHE)
	tar -C $(CACHE) -xf $(OUT)/tmp/toolchain_iree_rv32.tar.gz
	mkdir -p "$(CACHE)/toolchain_iree_rv32imf/riscv32-unknown-elf/lib/newlib-nano"
	cd "$(CACHE)/toolchain_iree_rv32imf/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libc_nano.a libc.a
	cd "$(CACHE)/toolchain_iree_rv32imf/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libg_nano.a libg.a
	cd "$(CACHE)/toolchain_iree_rv32imf/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libm_nano.a libm.a
	cd "$(CACHE)/toolchain_iree_rv32imf/riscv32-unknown-elf/lib/newlib-nano" && ln -sf ../libgloss_nano.a libgloss.a

install_llvm: $(CACHE)/toolchain_iree_rv32imf

toolchain_clean:
	rm -rf $(OUT)/tmp $(CACHE)/toolchain

qemu_clean:
	rm -rf $(QEMU_OUT_DIR)

.PHONY:: qemu toolchain_clean qemu_clean install_llvm
