RENODE_SRC_DIR := $(ROOTDIR)/sim/renode
RENODE_OUT_DIR := $(OUT)/host/renode
RENODE_BIN     := $(RENODE_OUT_DIR)/Renode.exe

$(RENODE_OUT_DIR):
	mkdir -p $(RENODE_OUT_DIR)

$(RENODE_BIN): | $(RENODE_SRC_DIR) $(RENODE_OUT_DIR)
	pushd $(RENODE_SRC_DIR) > /dev/null; \
	    ./build.sh -S; \
	    cp -rf output/bin/Release/* $(RENODE_OUT_DIR); \
	    cp -rf scripts $(RENODE_OUT_DIR); \
	    cp -rf platforms $(RENODE_OUT_DIR); \

# To rebuild the phony target, romove $(RENODE_BIN) to trigger the rebuild.
renode: $(RENODE_BIN)

renode_clean:
	@rm -rf $(RENODE_OUT_DIR)

VERILATOR_SRC_DIR   := $(ROOTDIR)/sim/verilator
VERILATOR_BUILD_DIR := $(OUT)/tmp/verilator
VERILATOR_OUT_DIR   := $(OUT)/host/verilator
VERILATOR_BIN       := $(VERILATOR_OUT_DIR)/bin/verilator_bin

$(VERILATOR_BUILD_DIR):
	mkdir -p $(VERILATOR_BUILD_DIR)

$(VERILATOR_BIN): | $(VERILATOR_SRC_DIR) $(VERILATOR_BUILD_DIR)
	autoconf -o $(VERILATOR_BUILD_DIR)/configure $(VERILATOR_SRC_DIR)/configure.ac
	pushd $(VERILATOR_BUILD_DIR) > /dev/null; sh configure \
		--srcdir=$(VERILATOR_SRC_DIR) \
		--prefix=$(VERILATOR_OUT_DIR)
	make -j$(shell nproc) -C $(VERILATOR_BUILD_DIR)
	make -C $(VERILATOR_BUILD_DIR) install

verilator_clean:
	rm -rf $(VERILATOR_BUILD_DIR) $(VERILATOR_OUT_DIR)

# To rebuild the phony target, romove $(VERILATOR_BIN) to trigger the rebuild.
verilator: $(VERILATOR_BIN)

.PHONY:: renode verilator
