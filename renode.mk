RENODE_SRC_DIR := $(ROOTDIR)/sim/renode
RENODE_OUT_DIR := $(OUT)/host/renode
RENODE_BIN     := $(RENODE_OUT_DIR)/renode.sh
RENODE_CMD     := cd $(ROOTDIR) && $(RENODE_BIN) --disable-xwt

RENODE_SIM_GENERATOR_SCRIPT := $(ROOTDIR)/scripts/generate_renode_configs.sh

$(RENODE_OUT_DIR):
	mkdir -p $(RENODE_OUT_DIR)

$(RENODE_BIN): | $(RENODE_SRC_DIR) $(RENODE_OUT_DIR)
	cd $(RENODE_SRC_DIR); \
		./build.sh -d --skip-fetch -o $(RENODE_OUT_DIR)

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

clean:: renode_clean

.PHONY:: renode renode_clean
