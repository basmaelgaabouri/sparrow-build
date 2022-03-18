VERILATOR_SRC_DIR   := $(ROOTDIR)/sim/verilator
VERILATOR_BUILD_DIR := $(OUT)/tmp/verilator
VERILATOR_OUT_DIR   := $(OUT)/host/verilator
VERILATOR_BIN       := $(VERILATOR_OUT_DIR)/bin/verilator_bin

$(VERILATOR_BUILD_DIR):
	mkdir -p $(VERILATOR_BUILD_DIR)

$(VERILATOR_BIN): | $(VERILATOR_SRC_DIR) $(VERILATOR_BUILD_DIR)
	cd $(VERILATOR_BUILD_DIR) && \
		autoconf -o $(VERILATOR_BUILD_DIR)/configure $(VERILATOR_SRC_DIR)/configure.ac
	cd $(VERILATOR_BUILD_DIR) && sh configure \
		--srcdir=$(VERILATOR_SRC_DIR) \
		--prefix=$(VERILATOR_OUT_DIR)
	$(MAKE) -C $(VERILATOR_BUILD_DIR)
	$(MAKE) -C $(VERILATOR_BUILD_DIR) install

## Removes only the Verilator build artifacts from out/
verilator_clean:
	rm -rf $(VERILATOR_BUILD_DIR) $(VERILATOR_OUT_DIR)

## Builds the Verilator verilog simulation tool.
#
# Using sources in sim/verilator, builds the Verilator tooling and places its
# output in out/host/verilator.
#
# To rebuild this target, remove $(VERILATOR_BIN) and re-run.
verilator: $(VERILATOR_BIN)

.PHONY:: verilator verilator_clean
