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

# To rebuild the phony target, remove $(RENODE_BIN) to trigger the rebuild.
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
	cd $(VERILATOR_BUILD_DIR) > /dev/null; \
		autoconf -o $(VERILATOR_BUILD_DIR)/configure $(VERILATOR_SRC_DIR)/configure.ac
	cd $(VERILATOR_BUILD_DIR) > /dev/null; sh configure \
		--srcdir=$(VERILATOR_SRC_DIR) \
		--prefix=$(VERILATOR_OUT_DIR)
	make -j$(shell nproc) -C $(VERILATOR_BUILD_DIR)
	make -C $(VERILATOR_BUILD_DIR) install

verilator_clean:
	rm -rf $(VERILATOR_BUILD_DIR) $(VERILATOR_OUT_DIR)

# To rebuild the phony target, romove $(VERILATOR_BIN) to trigger the rebuild.
verilator: $(VERILATOR_BIN)

sim_configs:
	$(RENODE_SIM_GENERATOR_SCRIPT)

clean_sim_configs:
	@rm -rf $(OUT)/renode_configs

$(OUT)/ext_flash.tar: $(OUT)/tock/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf \
  $(OUT)/kata/kernel/kernel.elf
	tar -C $(OUT) -cvf $(OUT)/ext_flash.tar \
		tock/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf \
		kata/kernel/kernel.elf \
		kata/capdl-loader

sim_deps: renode multihart_boot_rom $(OUT)/ext_flash.tar iree

simulate: sim_deps
	$(RENODE_CMD) -e "i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

debug-simulation: sim_deps
	$(RENODE_CMD) -e "i @sim/config/sparrow_all.resc; start"

test_sc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow_all.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_sc.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

test_mc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow_all.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_mc.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

tereturnst_vc: renode multihart_boot_rom $(ROOTDIR)/sim/config/sparrow_all.resc
	$(RENODE_CMD) -e "\$$tar = @$(ROOTDIR)/out/test_vc.tar; i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start"

.PHONY:: renode verilator sim_configs clean_sim_configs
