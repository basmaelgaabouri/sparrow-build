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

## Removes only the Renode build artifacts from out/
renode_clean:
	@rm -rf $(RENODE_OUT_DIR)

VERILATOR_SRC_DIR   := $(ROOTDIR)/sim/verilator
VERILATOR_BUILD_DIR := $(OUT)/tmp/verilator
VERILATOR_OUT_DIR   := $(OUT)/host/verilator
VERILATOR_BIN       := $(VERILATOR_OUT_DIR)/bin/verilator_bin

$(VERILATOR_BUILD_DIR):
	mkdir -p $(VERILATOR_BUILD_DIR)

$(VERILATOR_BIN): | $(VERILATOR_SRC_DIR) $(VERILATOR_BUILD_DIR)
	cd $(VERILATOR_BUILD_DIR) > /dev/null; \
		autoconf -o $(VERILATOR_BUILD_DIR)/configure $(VERILATOR_SRC_DIR)/configure.ac
	cd $(VERILATOR_BUILD_DIR) > /dev/null; sh configure \
		--srcdir=$(VERILATOR_SRC_DIR) \
		--prefix=$(VERILATOR_OUT_DIR)
	make -j$(shell nproc) -C $(VERILATOR_BUILD_DIR)
	make -C $(VERILATOR_BUILD_DIR) install

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

sim_configs:
	$(RENODE_SIM_GENERATOR_SCRIPT)

clean_sim_configs:
	@rm -rf $(OUT)/renode_configs

SMC_ELF=$(OUT)/kata/kernel/kernel.elf
SMC_ROOTSERVER=$(OUT)/kata/capdl-loader

$(OUT)/ext_flash_debug.tar: $(MATCHA_TOCK_BUNDLE_DEBUG) $(SMC_ELF) $(SMC_ROOTSERVER)
	ln -sf $(MATCHA_TOCK_BUNDLE_DEBUG) $(OUT)/tmp/matcha-tock-bundle
	ln -sf $(SMC_ELF) $(OUT)/tmp/kernel
	ln -sf $(SMC_ROOTSERVER) $(OUT)/tmp/capdl-loader
	tar -C $(OUT)/tmp -cvhf $(OUT)/ext_flash_debug.tar matcha-tock-bundle kernel capdl-loader

$(OUT)/ext_flash_release.tar: $(MATCHA_TOCK_BUNDLE_RELEASE) $(SMC_ELF) $(SMC_ROOTSERVER)
	ln -sf $(MATCHA_TOCK_BUNDLE_RELEASE) $(OUT)/tmp/matcha-tock-bundle
	ln -sf $(SMC_ELF) $(OUT)/tmp/kernel
	ln -sf $(SMC_ROOTSERVER) $(OUT)/tmp/capdl-loader
	tar -C $(OUT)/tmp -cvhf $(OUT)/ext_flash_release.tar matcha-tock-bundle kernel capdl-loader

## Launches an end-to-end build of the Sparrow system and starts Renode
#
# This top-level target triggers the `matcha_tock_release`, `kata`, `renode`,
# `multihart_boot_rom`, and `iree` targets to build the entire system and then
# finally starts the Renode simulator.
#
# This is the default target for the build system, and is generally what you
# need for day-to-day work on the software side of Sparrow.
simulate: renode multihart_boot_rom $(OUT)/ext_flash_release.tar iree
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/ext_flash_release.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

## Debug version of the `simulate` target
#
# This top-level target does the same job as `simulate`, but instead of
# unhalting the CPUs and starting the system, this alternate target only unhalts
# cpu0, and uses the debug build of TockOS from the `matcha_tock_debug` target.
simulate-debug: renode multihart_boot_rom $(OUT)/ext_flash_debug.tar iree
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/ext_flash_debug.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; start"

## Debug version of the `simulate` target
#
# This top-level target does the same job as `simulate-debug`, but instead of
# unhalting the CPUs and starting the system, this alternate target starts
# renode with no CPUs unhalted, allowing for GDB to be used for early system
# start.
debug-simulation: renode multihart_boot_rom $(OUT)/ext_flash_debug.tar iree
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/ext_flash_debug.tar; i @sim/config/sparrow_all.resc; start"

test_sc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow_all.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_sc.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

test_mc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow_all.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_mc.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

tereturnst_vc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow_all.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_vc.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

.PHONY:: renode verilator sim_configs clean_sim_configs
