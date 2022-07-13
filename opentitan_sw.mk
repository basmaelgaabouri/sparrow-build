OPENTITAN_SRC_DIR             := $(ROOTDIR)/hw/opentitan-upstream
OPENTITAN_BUILD_DIR           := $(OUT)/opentitan/sw
OPENTITAN_BUILD_OUT_DIR       := $(OPENTITAN_BUILD_DIR)/build-out
OPENTITAN_BUILD_SW_DEVICE_DIR := $(OPENTITAN_BUILD_DIR)/build-bin/sw/device

OPENTITAN_BAZEL_BIN_PATH := `cd $(OPENTITAN_SRC_DIR) && bazel info bazel-bin`
OPENTITAN_BAZEL_OUTPUT_PATH := `cd $(OPENTITAN_SRC_DIR) && bazel info output_path`
OPENTITAN_BAZEL_GENFILES_PATH := `cd $(OPENTITAN_SRC_DIR) && bazel info bazel-genfiles`

$(OPENTITAN_BUILD_OUT_DIR):
	@echo "Creating output directory $(OPENTITAN_BUILD_DIR)"
	@mkdir -p "$(OPENTITAN_BUILD_DIR)"

## Builds the hardware testing binaries from OpenTitan in hw/opentitan-upstream
# The output is stored at out/opentitan/sw/build-bin
opentitan_sw_all: | $(OPENTITAN_BUILD_OUT_DIR) \
                  opentitan_sw_verilator_sim \
                  # opentitan_sw_test #TODO(ykwang): avoid building sw tests and add it back later.

## Build the sw helloworld ELF from hw/opentitan-upstream
# The output is stored at out/opentitan/sw/build-bin/sw/device/examples/hello_world
opentitan_sw_helloworld: $(OPENTITAN_BUILD_SW_DEVICE_DIR)/examples/hello_world
$(OPENTITAN_BUILD_SW_DEVICE_DIR)/examples/hello_world: | $(OPENTITAN_BUILD_OUT_DIR)
	cd $(OPENTITAN_SRC_DIR) && \
		bazel build //sw/device/examples/hello_world:hello_world
	mkdir -p "${OPENTITAN_BUILD_SW_DEVICE_DIR}/examples/hello_world"
	find ${OPENTITAN_BAZEL_OUTPUT_PATH} -name "hello_world*.elf" \
		-exec cp -f '{}' "${OPENTITAN_BUILD_SW_DEVICE_DIR}/examples/hello_world" \;

## Build the boot rom artifacts for Open Titan from hw/opentitan-upstream
# The artifacts are stored at out/opentitan/sw/build-bin/sw/device/boot_rom
# TODO(ykwang): revise boot_rom to test_rom.
opentitan_sw_bootrom: $(OPENTITAN_BUILD_SW_DEVICE_DIR)/boot_rom/boot_rom_sim_verilator.scr.39.vmem
$(OPENTITAN_BUILD_SW_DEVICE_DIR)/boot_rom/boot_rom_sim_verilator.scr.39.vmem: | $(OPENTITAN_BUILD_OUT_DIR)
	cd $(OPENTITAN_SRC_DIR) && \
		bazel build //sw/device/lib/testing/test_rom:test_rom
	mkdir -p "${OPENTITAN_BUILD_SW_DEVICE_DIR}/boot_rom"
	find ${OPENTITAN_BAZEL_OUTPUT_PATH} -name "test_rom_sim_verilator.scr.39.vmem" \
		-exec cp -f '{}' "${OPENTITAN_BUILD_SW_DEVICE_DIR}/boot_rom/boot_rom_sim_verilator.scr.39.vmem" \;

## Build the opt image for Open Titan from hw/opentitan-upstream
# The artifacts are stored at out/opentitan/sw/build-bin/sw/device/otp_img/otp_img_sim_verilator.vmem
opentitan_opt_img: $(OPENTITAN_BUILD_SW_DEVICE_DIR)/otp_img/otp_img_sim_verilator.vmem
$(OPENTITAN_BUILD_SW_DEVICE_DIR)/otp_img/otp_img_sim_verilator.vmem: | $(OPENTITAN_BUILD_OUT_DIR)
	cd $(OPENTITAN_SRC_DIR) && \
		bazel build //hw/ip/otp_ctrl/data:img_dev
	mkdir -p "${OPENTITAN_BUILD_SW_DEVICE_DIR}/otp_img"
	find ${OPENTITAN_BAZEL_BIN_PATH} -name "img_dev.vmem" \
		-exec cp -f '{}' "${OPENTITAN_BUILD_SW_DEVICE_DIR}/otp_img/otp_img_sim_verilator.vmem" \;

## Build the Verilator sim SW for Open Titan from hw/opentitan-upstream
# The artifacts include boot_rom, hello_world ELF, and otp image. The artifacts
# are stored at out/opentitan/sw/build-bin
opentitan_sw_verilator_sim: | $(OPENTITAN_BUILD_OUT_DIR) \
                              opentitan_sw_helloworld \
                              opentitan_sw_bootrom \
                              opentitan_opt_img

## Build and run host based opentitan unittests
# The artifacts are stored at out/opentitan/sw/build-bin/
opentitan_sw_test: | $(OPENTITAN_BUILD_OUT_DIR)
	cd $(OPENTITAN_SRC_DIR) && \
	bazel build //sw/device/tests:all && \
	cp -rf "`bazel info bazel-bin`/sw/device/tests" "${OPENTITAN_BUILD_SW_DEVICE_DIR}"


## Removes only the OpenTitan build artifacts from out/opentitan/sw
opentitan_sw_clean:
	rm -rf $(OPENTITAN_BUILD_DIR)

.PHONY:: opentitan_sw_all opentitan_sw_clean opentitan_sw_verilator_sim opentitan_sw_test
.PHONY:: $(OPENTITAN_BUILD_SW_DEVICE_DIR)/examples/hello_world
.PHONY:: $(OPENTITAN_BUILD_SW_DEVICE_DIR)/boot_rom/boot_rom_sim_verilator.scr.39.vmem
.PHONY:: $(OPENTITAN_BUILD_SW_DEVICE_DIR)/otp_img/otp_img_sim_verilator.vmem
