RENODE_SRC_DIR := $(ROOTDIR)/sim/renode
RENODE_OUT_DIR := $(OUT)/host/renode

$(RENODE_OUT_DIR): | $(RENODE_SRC_DIR)
	pushd $(ROOTDIR); mkdir -p $(RENODE_OUT_DIR);
	pushd $(RENODE_SRC_DIR); \
	    sed -i '/git submodule update/d' build.sh; \
	    ./build.sh; \
	    cp -rf output/bin/Release/* $(RENODE_OUT_DIR); \
	    cp -rf scripts $(RENODE_OUT_DIR); \
	    cp -rf platforms $(RENODE_OUT_DIR); \
	    git checkout build.sh;\
	popd

renode: $(RENODE_OUT_DIR)

VERILATOR_SRC_DIR   := $(ROOTDIR)/sim/verilator
VERILATOR_BUILD_DIR := $(OUT)/tmp/verilator
VERILATOR_OUT_DIR   := $(OUT)/host/verilator

$(VERILATOR_OUT_DIR): | $(ROOTDIR)/sim/verilator
	pushd $(ROOTDIR); mkdir -p $(VERILATOR_BUILD_DIR);
	pushd $(VERILATOR_BUILD_DIR); autoconf -o $(VERILATOR_BUILD_DIR)/configure $(VERILATOR_SRC_DIR)/configure.ac
	pushd $(VERILATOR_BUILD_DIR); sh configure \
		--srcdir=$(VERILATOR_SRC_DIR) \
		--prefix=$(VERILATOR_OUT_DIR)
	pushd $(VERILATOR_BUILD_DIR); make -j$(shell nproc)
	pushd $(VERILATOR_BUILD_DIR); make install

verilator_clean:
	pushd $(VERILATOR_BUILD_DIR); make clean;

verilator: $(VERILATOR_OUT_DIR)

.PHONY:: renode verilator
