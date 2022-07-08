SHODAN_BOOT_ROM_SOURCE_DIR:=$(ROOTDIR)/sw/multihart_boot_rom
SHODAN_BOOT_ROM_BUILD_DIR:=$(OUT)/sparrow_boot_rom
SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT:=$(SHODAN_BOOT_ROM_BUILD_DIR)/build.ninja
SHODAN_BOOT_ROM_ELF:=multihart_boot_rom.elf

$(SHODAN_BOOT_ROM_BUILD_DIR):
	@mkdir -p "$(SHODAN_BOOT_ROM_BUILD_DIR)"

$(SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT): | $(SHODAN_BOOT_ROM_BUILD_DIR)
	cmake -B $(SHODAN_BOOT_ROM_BUILD_DIR) -G Ninja $(SHODAN_BOOT_ROM_SOURCE_DIR)

## Build the Sparrow boot ROM image
#
# This builds a simple multi-core boot ROM that can bootstrap the Sparrow system
# in simulation. Source is in sw/multihart_boot_rom, while output is placed in
# out/sparrow_boot_rom
multihart_boot_rom: $(SHODAN_BOOT_ROM_BUILD_NINJA_SCRIPT)
	cmake --build $(SHODAN_BOOT_ROM_BUILD_DIR) --target $(SHODAN_BOOT_ROM_ELF)

## Clean the Sparrow boot ROM build directory
multihart_boot_rom_clean:
	rm -rf $(SHODAN_BOOT_ROM_BUILD_DIR)


.PHONY:: multihart_boot_rom multihart_boot_rom_clean
