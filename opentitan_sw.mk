OPENTITAN_SRC_DIR             := $(ROOTDIR)/hw/opentitan-upstream
OPENTITAN_BUILD_DIR           := $(OUT)/opentitan/sw
OPENTITAN_BUILD_OUT_DIR       := $(OPENTITAN_BUILD_DIR)/build-out
OPENTITAN_BUILD_NINJA         := $(OPENTITAN_BUILD_OUT_DIR)/build.ninja
OPENTITAN_BUILD_SW_DEVICE_DIR := $(OPENTITAN_BUILD_DIR)/build-bin/sw/device

$(OPENTITAN_BUILD_OUT_DIR):
	@echo "Creating output directory $(OPENTITAN_BUILD_DIR)"
	@mkdir -p "$(OPENTITAN_BUILD_DIR)"

$(OPENTITAN_BUILD_NINJA): | $(OPENTITAN_BUILD_OUT_DIR)
	cd $(OPENTITAN_SRC_DIR); \
		TOOLCHAIN_PATH=$(CACHE)/toolchain \
		BUILD_ROOT=$(OPENTITAN_BUILD_DIR) \
		CC_FOR_BUILD=gcc-10 \
		CXX_FOR_BUILD=g++-10 ./meson_init.sh -f;

## Builds the hardware testing binaries from OpenTitan in hw/opentitan-upstream
# The output is stored at out/opentitan/sw/build-bin
opentitan_sw_all: $(OPENTITAN_BUILD_NINJA)
	ninja -C $(OPENTITAN_BUILD_OUT_DIR) all

## Build the sw helloworld ELF from hw/opentitan-upstream
# The output is stored at out/opentitan/sw/build-bin/sw/device/examples/hello_world
opentitan_sw_helloworld: $(OPENTITAN_BUILD_NINJA)
	ninja -C $(OPENTITAN_BUILD_OUT_DIR) \
		sw/device/examples/hello_world/hello_world_export_sim_verilator

## Build the Verilator sim SW for Open Titan from hw/opentitan-upstream
# The artifacts include boot_rom, hello_world ELF, and otp image. The artifacts
# are stored at out/opentitan/sw/build-bin
opentitan_sw_verilator_sim: $(OPENTITAN_BUILD_NINJA)
	ninja -C $(OPENTITAN_BUILD_OUT_DIR) \
		sw/device/examples/hello_world/hello_world_export_sim_verilator \
		sw/device/boot_rom/boot_rom_export_sim_verilator \
		sw/device/otp_img/otp_img_export_sim_verilator

## Build the boot rom artifacts for Open Titan from hw/opentitan-upstream
# The artifacts are stored at out/opentitan/sw/build-bin/sw/device/boot_rom
opentitan_sw_bootrom: $(OPENTITAN_BUILD_NINJA)
	ninja -C $(OPENTITAN_BUILD_OUT_DIR) \
		sw/device/boot_rom/boot_rom_export_sim_verilator \
		sw/device/boot_rom/boot_rom_export_sim_dv \
		sw/device/boot_rom/boot_rom_export_fpga_nexysvideo

## Build and run host based opentitan unittests
# The artifacts are stored at out/opentitan/sw/build-bin/
opentitan_sw_test: $(OPENTITAN_BUILD_NINJA)
	ninja -C $(OPENTITAN_BUILD_OUT_DIR) test

## Removes only the OpenTitan build artifacts from out/opentitan/sw
opentitan_sw_clean:
	rm -rf $(OPENTITAN_BUILD_DIR)

.PHONY:: opentitan_sw_clean opentitan_sw_helloworld opentitan_sw_all opentitan_sw_bootrom opentitan_sw_test opentitan_sw_verilator_sim
