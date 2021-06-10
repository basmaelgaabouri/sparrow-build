RENODE_SRC_DIR := $(ROOTDIR)/sim/renode
RENODE_OUT_DIR := $(OUT)/host/renode
RENODE_BIN     := $(RENODE_OUT_DIR)/Renode.exe

RENODE_SIM_GENERATOR_SCRIPT := $(ROOTDIR)/scripts/generate_renode_configs.sh

$(RENODE_OUT_DIR):
	mkdir -p $(RENODE_OUT_DIR)

$(RENODE_BIN): | $(RENODE_SRC_DIR) $(RENODE_OUT_DIR)
	pushd $(RENODE_SRC_DIR) > /dev/null; \
	    ./build.sh --skip-fetch; \
	    cp -rf output/bin/Release/* $(RENODE_OUT_DIR); \
	    cp -rf scripts $(RENODE_OUT_DIR); \
	    cp -rf platforms $(RENODE_OUT_DIR)

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
	pushd $(VERILATOR_BUILD_DIR) > /dev/null; \
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

sim_configs:
	$(RENODE_SIM_GENERATOR_SCRIPT)

simulate_qemu_vector_tests: qemu vector_sw_all opentitan_sw_bootrom
	for elf in $(shell find $(ROOTDIR)/out/sparrow_vector_tests/build-bin -name '*vector*tests_fpga_nexysvideo.elf') ; do \
		python3 $(ROOTDIR)/scripts/run-vector-simulation.py \
			--boot-elf-path $(OPENTITAN_BUILD_DIR)/build-bin/sw/device/boot_rom/boot_rom_fpga_nexysvideo.elf \
			--vector-elf-path $$elf \
			--simulator qemu \
			--simulator-path $(QEMU_BINARY); \
	done

clean_sim_configs:
	@rm -rf $(OUT)/renode_configs

$(OUT)/sparrow.dtb: $(ROOTDIR)/sim/config/devicetree/sparrow.dts
	dtc -I dts -O dtb $< > $@

$(OUT)/ext_flash.tar: $(OUT)/tock/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf \
                      $(OUT)/kata/bbl/bbl \
                      $(OUT)/sparrow.dtb
	tar -cvf $(OUT)/ext_flash.tar \
		$(OUT)/tock/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf \
		$(OUT)/kata/bbl/bbl \
		$(OUT)/sparrow.dtb

simulate: renode multihart_boot_rom libtockrs_helloworld kata $(OUT)/ext_flash.tar $(ROOTDIR)/sim/config/sparrow_all.resc
	$(ROOTDIR)/sim/renode/renode -e "i @sim/config/sparrow_all.resc; pause; cpu0 IsHalted false; cpu1 IsHalted false; start" --disable-xwt

debug-simulation: renode multihart_boot_rom libtockrs_helloworld kata $(OUT)/ext_flash.tar $(ROOTDIR)/sim/config/sparrow_all.resc
	$(ROOTDIR)/sim/renode/renode -e "i @sim/config/sparrow_all.resc; start" --disable-xwt

.PHONY:: renode verilator sim_configs clean_sim_configs
