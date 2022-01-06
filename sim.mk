sim_configs:
	$(RENODE_SIM_GENERATOR_SCRIPT)

clean_sim_configs:
	@rm -rf $(OUT)/renode_configs

SMC_ELF=$(OUT)/kata/kernel/kernel.elf
SMC_ROOTSERVER=$(OUT)/kata/capdl-loader

$(OUT)/ext_flash_debug.tar: $(MATCHA_BUNDLE_DEBUG) $(SMC_ELF) $(SMC_ROOTSERVER) | $(OUT)/tmp
	ln -sf $(MATCHA_BUNDLE_DEBUG) $(OUT)/tmp/matcha-tock-bundle
	ln -sf $(SMC_ELF) $(OUT)/tmp/kernel
	ln -sf $(SMC_ROOTSERVER) $(OUT)/tmp/capdl-loader
	tar -C $(OUT)/tmp -cvhf $(OUT)/ext_flash_debug.tar matcha-tock-bundle kernel capdl-loader

$(OUT)/ext_flash_release.tar: $(MATCHA_BUNDLE_RELEASE) $(SMC_ELF) $(SMC_ROOTSERVER) | $(OUT)/tmp
	ln -sf $(MATCHA_BUNDLE_RELEASE) $(OUT)/tmp/matcha-tock-bundle
	ln -sf $(SMC_ELF) $(OUT)/tmp/kernel
	ln -sf $(SMC_ROOTSERVER) $(OUT)/tmp/capdl-loader
	tar -C $(OUT)/tmp -cvhf $(OUT)/ext_flash_release.tar matcha-tock-bundle kernel capdl-loader

# Renode commands to issue before the initial start of a simulation.
# This pauses all cores and then sets cpu0 (SC) & cpu1 (SMC) running.
RENODE_PRESTART_CMDS=pause; cpu0 IsHalted false;

## Launches an end-to-end build of the Sparrow system and starts Renode
#
# This top-level target triggers the `matcha_tock_release`, `kata`, `renode`,
# `multihart_boot_rom`, and `iree` targets to build the entire system and then
# finally starts the Renode simulator.
#
# This is the default target for the build system, and is generally what you
# need for day-to-day work on the software side of Sparrow.
simulate: renode multihart_boot_rom $(OUT)/ext_flash_release.tar iree
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/ext_flash_release.tar; i @sim/config/sparrow.resc; $(RENODE_PRESTART_CMDS); start"

## Debug version of the `simulate` target
#
# This top-level target does the same job as `simulate`, but instead of
# unhalting the CPUs and starting the system, this alternate target only unhalts
# cpu0, and uses the debug build of TockOS from the `matcha_tock_debug` target.
simulate-debug: renode multihart_boot_rom $(OUT)/ext_flash_debug.tar iree
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/ext_flash_debug.tar; i @sim/config/sparrow.resc; $(RENODE_PRESTART_CMDS); start"

## Debug version of the `simulate` target
#
# This top-level target does the same job as `simulate-debug`, but instead of
# unhalting the CPUs and starting the system, this alternate target starts
# renode with no CPUs unhalted, allowing for GDB to be used for early system
# start.
debug-simulation: renode multihart_boot_rom $(OUT)/ext_flash_debug.tar iree
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/ext_flash_debug.tar; i @sim/config/sparrow.resc; start"

test_sc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_sc.tar; i @sim/config/sparrow.resc; $(RENODE_PRESTART_CMDS); start"

test_mc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_mc.tar; i @sim/config/sparrow.resc; $(RENODE_PRESTART_CMDS); start"

test_vc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_vc.tar; i @sim/config/sparrow.resc; $(RENODE_PRESTART_CMDS); start"

.PHONY:: sim_configs clean_sim_configs simulate simulate-debug debug-simulation
.PHONY:: test_sc test_mc test_vc

