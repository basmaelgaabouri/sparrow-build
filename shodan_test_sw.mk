SHODAN_BUILD_DIR=$(OUT)/sparrow
SHODAN_BUILD_OUT_DIR=$(SHODAN_BUILD_DIR)/build-out
SHODAN_BUILD_NINJA_SCRIPT=$(SHODAN_BUILD_DIR)/build-out/build.ninja
SHODAN_BUILD_TOOLCHAIN_CONFIG=$(SHODAN_BUILD_DIR)/toolchain-configured.txt

$(SHODAN_BUILD_DIR):
	@mkdir -p "$(SHODAN_BUILD_DIR)"

$(SHODAN_BUILD_TOOLCHAIN_CONFIG): | $(SHODAN_BUILD_DIR)
	@echo "Setup toolchain configuration $(SHODAN_BUILD_TOOLCHAIN_CONFIG)"
	cd $(ROOTDIR)/hw/opentitan; \
	    cp toolchain.txt "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"
	cd $(ROOTDIR)/hw/opentitan; \
	    sed -i "s#/tools/riscv/bin#$(CACHE)/toolchain/bin#g" "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"; \
	    sed -i "s#rv32imc#rv32gc#g" "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"; \
	    sed -i "s#medany#medlow#g" "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"

$(SHODAN_BUILD_NINJA_SCRIPT): $(SHODAN_BUILD_TOOLCHAIN_CONFIG)
	@echo "Creating build directories $(SHODAN_BUILD_OUT_DIR)"
	cd $(ROOTDIR)/hw/opentitan; \
	    BUILD_ROOT=$(SHODAN_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)";

sparrow_test_sw_all: $(SHODAN_BUILD_NINJA_SCRIPT) $(SHODAN_BUILD_OUT_DIR)/sw_sparrow/device/rom_exts/manifest.h
	cd $(ROOTDIR)/hw/opentitan; \
		ninja -C $(SHODAN_BUILD_OUT_DIR) all

sparrow_test_sw_bootrom: $(SHODAN_BUILD_NINJA_SCRIPT) $(SHODAN_BUILD_OUT_DIR)/sw_sparrow/device/rom_exts/manifest.h
	ninja -C $(SHODAN_BUILD_OUT_DIR) \
		sw_sparrow/device/boot_rom/boot_rom_export_sim_verilator \
		sw_sparrow/device/boot_rom/boot_rom_export_sim_dv \
		sw_sparrow/device/boot_rom/boot_rom_export_fpga_nexysvideo

$(SHODAN_BUILD_OUT_DIR)/sw_sparrow/device/rom_exts/manifest.h: $(SHODAN_BUILD_NINJA_SCRIPT)
	ninja -C $(SHODAN_BUILD_OUT_DIR) \
		sw_sparrow/device/rom_exts/manifest.h \
		sw/device/rom_exts/manifest.h

sparrow_test_sw_ot_tests: $(SHODAN_BUILD_NINJA_SCRIPT) $(SHODAN_BUILD_OUT_DIR)/sw_sparrow/device/rom_exts/manifest.h
	ninja -C $(SHODAN_BUILD_OUT_DIR) test

sparrow_test_sw_clean:
	@echo "Remove sparrow software build directory $(SHODAN_BUILD_DIR)"
	@rm -rf $(SHODAN_BUILD_DIR)

.PHONY:: sparrow_test_sw_clean sparrow_test_sw_all sparrow_test_sw_bootrom
