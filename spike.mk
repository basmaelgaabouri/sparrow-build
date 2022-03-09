SPIKE_SRC_DIR := $(ROOTDIR)/toolchain/spike
SPIKE_BUILD_DIR := $(OUT)/tmp/spike
SPIKE_INSTALL_DIR := $(OUT)/host/spike

$(SPIKE_BUILD_DIR):
	mkdir -p $(SPIKE_BUILD_DIR)

$(SPIKE_INSTALL_DIR):
	mkdir -p $(SPIKE_INSTALL_DIR)

$(SPIKE_INSTALL_DIR)/bin/spike: $(SPIKE_SRC_DIR) | $(SPIKE_BUILD_DIR) $(SPIKE_INSTALL_DIR)
	cd $(SPIKE_BUILD_DIR) && $(SPIKE_SRC_DIR)/configure --prefix=$(SPIKE_INSTALL_DIR) \
		--with-isa=rv32imafcv1p0_xspringbok --with-target=riscv32-unknown-elf \
		--enable-commitlog
	$(MAKE) -C $(SPIKE_BUILD_DIR) install

## Build spike RISCV ISA simulator
#
# Using sources in toolchain/spike, this target builds spike from source and stores
# its output in out/host/spike.
#
# You may want to build with `m -j64 spike` to enable parallel build.
#
# To rebuild this target, run `m spike_clean` and re-run.
spike: $(SPIKE_INSTALL_DIR)/bin/spike

spike_clean:
	rm -r $(SPIKE_BUILD_DIR) $(SPIKE_INSTALL_DIR)

.PHONY:: spike spike_clean
