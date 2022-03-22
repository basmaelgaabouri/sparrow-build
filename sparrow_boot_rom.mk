SHODAN_BOOT_ROM_BUILD_DIR=$(OUT)/sparrow_boot_rom
SHODAN_BOOT_ROM_BUILD_OUT_DIR=$(SHODAN_BOOT_ROM_BUILD_DIR)/build-out
SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT=$(SHODAN_BOOT_ROM_BUILD_OUT_DIR)/build.ninja
SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG=$(SHODAN_BOOT_ROM_BUILD_DIR)/toolchain-configured.txt
SHODAN_BOOT_ROM_MANIFEST=$(SHODAN_BOOT_ROM_BUILD_OUT_DIR)/sw_sparrow/device/rom_exts/manifest.h
SHODAN_BOOT_ROM_DEPS=$(SHODAN_BOOT_ROM_MANIFEST) $(SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT)

$(SHODAN_BOOT_ROM_BUILD_DIR):
	@mkdir -p "$(SHODAN_BOOT_ROM_BUILD_DIR)"

$(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG): | $(SHODAN_BOOT_ROM_BUILD_DIR)
	@echo "Setup toolchain configuration $(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG)"
	cp "$(ROOTDIR)/hw/opentitan/toolchain.txt" "$(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG)"
	sed -i "s#/tools/riscv/bin#$(CACHE)/toolchain/bin#g;" "$(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG)";
	sed -i "s#medany#medlow#g" "$(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG)"

$(SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT): $(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG)
	@echo "Creating build directories $(SHODAN_BOOT_ROM_BUILD_OUT_DIR)"
	cd $(ROOTDIR)/sw/multihart_boot_rom; \
	    BUILD_ROOT=$(SHODAN_BOOT_ROM_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_BOOT_ROM_BUILD_TOOLCHAIN_CONFIG)";

$(SHODAN_BOOT_ROM_MANIFEST): $(SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT)
	ninja -C $(SHODAN_BOOT_ROM_BUILD_OUT_DIR) \
		sw_sparrow/device/rom_exts/manifest.h \
		sw/device/rom_exts/manifest.h

## Builds the Sparrow boot ROM image
#
# This builds a simple multi-core boot ROM that can bootstrap the Sparrow system
# in simulation. Source is in sw/multihart_boot_rom, while output is placed in
# out/sparrow_boot_rom
multihart_boot_rom: $(SHODAN_BOOT_ROM_DEPS) | rust_presence_check
	ninja -C $(SHODAN_BOOT_ROM_BUILD_OUT_DIR) \
		multihart_boot_rom/multihart_boot_rom_export_sim_verilator;

multihart_boot_rom_clean:
	rm -rf $(SHODAN_BOOT_ROM_BUILD_DIR)


.PHONY:: multihart_boot_rom multihart_boot_rom_clean
