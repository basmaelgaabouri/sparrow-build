RENODE_SRC_DIR := $(ROOTDIR)/sim/renode
RENODE_OUT_DIR := $(OUT)/host/renode
RENODE_BIN     := $(RENODE_OUT_DIR)/renode.sh
RENODE_PORT    ?= 1234
RENODE_CMD     := cd $(ROOTDIR) && $(RENODE_BIN) --disable-xwt --port $(RENODE_PORT)
RENODE_COMMIT  := $(shell git -C $(RENODE_SRC_DIR) rev-parse  --short=8 HEAD)
RENODE_SIM_GENERATOR_SCRIPT := $(ROOTDIR)/scripts/generate_renode_configs.sh

$(RENODE_OUT_DIR):
	mkdir -p $(RENODE_OUT_DIR)

$(RENODE_BIN): | $(RENODE_SRC_DIR) $(RENODE_OUT_DIR)
	cd $(RENODE_SRC_DIR); \
		./build.sh -d -o $(RENODE_OUT_DIR)
	echo -e "built_from_src\ncommit_sha: $(RENODE_COMMIT)\n" > $(RENODE_OUT_DIR)/tag

## Builds the Renode system simulator
#
# Using sources in sim/renode, this target builds Renode from source and stores
# its output in out/host/renode.
#
# To rebuild this target, run `m renode_clean` and re-run.
#
# This is for debug purpose only. You probably want to use `m renode` target.
renode_src: $(RENODE_BIN)

## Download and install the nightly release Renode system simulator
#
# From AntMicro's release. If there is a local build from `m renode_src` with
# the same commit sha as the release build, it will be treated as up-to-date.
renode: | $(RENODE_OUT_DIR)
	./scripts/download_renode.py --renode_dir $(RENODE_OUT_DIR)


## Removes Renode build artifacts from sim/renode and out/
renode_clean:
	@rm -rf $(RENODE_OUT_DIR)
	@rm -rf $(RENODE_SRC_DIR)/output
	@cd $(RENODE_SRC_DIR); find . -type d -name bin | xargs rm -rf
	@cd $(RENODE_SRC_DIR); find . -type d -name obj | xargs rm -rf

clean:: renode_clean

.PHONY:: renode renode_src renode_clean
