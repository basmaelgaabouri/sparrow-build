SHODAN_BOOT_ROM_BUILD_DIR=$(OUT)/sparrow_boot_rom
SHODAN_BUILD_OUT_DIR=$(SHODAN_BOOT_ROM_BUILD_DIR)/build-out
SHODAN_BUILD_NINJA_SCRIPT=$(SHODAN_BOOT_ROM_BUILD_DIR)/build-out/build.ninja
SHODAN_BUILD_TOOLCHAIN_CONFIG=$(SHODAN_BOOT_ROM_BUILD_DIR)/toolchain-configured.txt
SHODAN_MANIFEST=$(SHODAN_BUILD_OUT_DIR)/sw_sparrow/device/rom_exts/manifest.h
SHODAN_DEPS=$(SHODAN_MANIFEST) $(SHODAN_BUILD_NINJA_SCRIPT)

$(SHODAN_BOOT_ROM_BUILD_DIR):
	@mkdir -p "$(SHODAN_BOOT_ROM_BUILD_DIR)"

$(SHODAN_BUILD_TOOLCHAIN_CONFIG): | $(SHODAN_BOOT_ROM_BUILD_DIR)
	@echo "Setup toolchain configuration $(SHODAN_BUILD_TOOLCHAIN_CONFIG)"
	cd $(ROOTDIR)/hw/opentitan; \
	    cp toolchain.txt "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"
	cd $(ROOTDIR)/hw/opentitan; \
	    sed -i "s#/tools/riscv/bin#$(CACHE)/toolchain/bin#g;s#medany#medlow#g" "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"

$(SHODAN_BUILD_NINJA_SCRIPT): $(SHODAN_BUILD_TOOLCHAIN_CONFIG)
	@echo "Creating build directories $(SHODAN_BUILD_OUT_DIR)"
	cd $(ROOTDIR)/hw/opentitan; \
	    BUILD_ROOT=$(SHODAN_BOOT_ROM_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)";

$(SHODAN_MANIFEST): $(SHODAN_BUILD_NINJA_SCRIPT)
	cd $(ROOTDIR)/hw/opentitan; \
		ninja -C $(SHODAN_BUILD_OUT_DIR) \
			sw_sparrow/device/rom_exts/manifest.h \
			sw/device/rom_exts/manifest.h

multihart_boot_rom: $(SHODAN_DEPS)
	cd $(ROOTDIR)/sw/multihart_boot_rom; \
		BUILD_ROOT=$(SHODAN_BOOT_ROM_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"; \
		ninja -C $(SHODAN_BUILD_OUT_DIR) \
			multihart_boot_rom/multihart_boot_rom_export_sim_verilator;

multihart_boot_rom_clean:
	rm -rf $(SHODAN_BOOT_ROM_BUILD_DIR)


.PHONY:: multihart_boot_rom multihart_boot_rom_clean
