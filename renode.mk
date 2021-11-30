RENODE_SRC_DIR := $(ROOTDIR)/sim/renode
RENODE_OUT_DIR := $(OUT)/host/renode
RENODE_BIN     := $(RENODE_OUT_DIR)/Renode.exe
RENODE_CMD     := cd $(ROOTDIR) && mono $(RENODE_BIN) --disable-xwt

RENODE_SIM_GENERATOR_SCRIPT := $(ROOTDIR)/scripts/generate_renode_configs.sh

$(RENODE_OUT_DIR):
	mkdir -p $(RENODE_OUT_DIR)

$(RENODE_BIN): | $(RENODE_SRC_DIR) $(RENODE_OUT_DIR)
	cd $(RENODE_SRC_DIR) > /dev/null; \
		./build.sh -d --skip-fetch; \
		cp -rf output/bin/Debug/* $(RENODE_OUT_DIR); \
		cp -rf scripts $(RENODE_OUT_DIR); \
		cp -rf platforms $(RENODE_OUT_DIR)

## Builds the Renode system simulator
#
# Using sources in sim/renode, this target builds Renode from source and stores
# its output in out/host/renode.
#
# To rebuild this target, remove $(RENODE_BIN) and re-run.
renode: $(RENODE_BIN)

## Removes Renode build artifacts from sim/renode and out/
renode_clean:
	@rm -rf $(RENODE_OUT_DIR)
	@rm -rf $(RENODE_SRC_DIR)/output
	@cd $(RENODE_SRC_DIR); find . -type d -name bin | xargs rm -rf
	@cd $(RENODE_SRC_DIR); find . -type d -name obj | xargs rm -rf

.PHONY:: renode renode_clean
