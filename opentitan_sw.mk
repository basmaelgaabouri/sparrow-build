
OPENTITAN_BUILD_DIR=$(OUT)/opentitan
OPENTITAN_BUILD_OUT_DIR=$(OPENTITAN_BUILD_DIR)/build-out

$(OPENTITAN_BUILD_OUT_DIR):
	@echo "Creating output directory $(OPENTITAN_BUILD_DIR)"
	@mkdir -p "$(OPENTITAN_BUILD_DIR)"
	cd $(ROOTDIR)/hw/opentitan; \
	    TOOLCHAIN_PATH=$(CACHE)/toolchain BUILD_ROOT=$(OPENTITAN_BUILD_DIR) ./meson_init.sh -f;

## Builds the hardware testing binaries from OpenTitan in hw/opentitan
opentitan_sw_all: $(OPENTITAN_BUILD_OUT_DIR)
	cd $(ROOTDIR)/hw/opentitan; \
	    ninja -C $(OPENTITAN_BUILD_OUT_DIR) all

opentitan_sw_helloworld: $(OPENTITAN_BUILD_OUT_DIR)
	cd $(ROOTDIR)/hw/opentitan; \
	    ninja -C $(OPENTITAN_BUILD_OUT_DIR) sw/device/examples/hello_world/hello_world_export_sim_verilator;

opentitan_sw_bootrom: $(OPENTITAN_BUILD_OUT_DIR)
	cd $(ROOTDIR)/hw/opentitan; \
	ninja -C $(OPENTITAN_BUILD_OUT_DIR) \
		sw/device/boot_rom/boot_rom_export_sim_verilator \
		sw/device/boot_rom/boot_rom_export_sim_dv \
		sw/device/boot_rom/boot_rom_export_fpga_nexysvideo

## Removes only the OpenTitan build artifacts from out/
opentitan_sw_clean:
	rm -rf $(OPENTITAN_BUILD_DIR)

.PHONY:: opentitan_sw_clean opentitan_sw_helloworld opentitan_sw_all opentitan_sw_bootrom
