# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

MATCHA_SRC_DIR             := $(ROOTDIR)/hw/matcha
OPENTITAN_HW_DIR           := $(OPENTITAN_SRC_DIR)/hw
MATCHA_OUT_DIR             := $(OUT)/matcha/hw
MATCHA_OUT_ROM_SPLICES_DIR := $(MATCHA_OUT_DIR)/rom_splices
MATCHA_VERILATOR_TB        := $(MATCHA_OUT_DIR)/sim-verilator/Vchip_sim_tb
MATCHA_HW_TEST_OUT         := $(MATCHA_OUT_DIR)/sw/hw_tests
MATCHA_SMC_BUILD_DIR       := $(MATCHA_OUT_DIR)/sw/smc
MATCHA_SW_DEVICE_DIR       := $(MATCHA_OUT_DIR)/sw/device
MATCHA_TESTLOG_DIR         := $(MATCHA_OUT_DIR)/test-log
ISP_SRC_DIR                := $(ROOTDIR)/hw/ip/isp

$(MATCHA_OUT_DIR):
	mkdir -p $(MATCHA_OUT_DIR)

## Regenerate Matcha HW files frop IPs and top_matcha definition.
# This target uses Open Titan's autogen tools as well as the HW IPs to generate
# the system verilog files as well as the DV register definition cores and
# system verilog files. The source code is from both hw/opentitan-upstream and
# hw/matcha/, while the output is stored at out/matcha/hw.
#
# This is a dev-only target (not for CI), as it modifies the hw/matcha source
# tree with generated code.
matcha_hw_generate_all: | $(MATCHA_OUT_DIR)
	$(MAKE) -C "$(MATCHA_SRC_DIR)/hw" all

## Build Matcha verilator testbench.
# This target builds the verilator testbench binary from hw/matcha using
# hw/opentitan-upstream as the library. The output is stored in
# out/matcha/hw/.
# This target is compute-intensive. Make sure you have a powerful enough machine
# to build it.
matcha_hw_verilator_sim: $(MATCHA_VERILATOR_TB)

# TODO(ykwang): Copy only needed files into matcha output directory.
# TODO(ykwang): Revise the structure of matcha output directory.
$(MATCHA_VERILATOR_TB): $(MATCHA_OUT_DIR) verilator
	cd $(MATCHA_SRC_DIR) && \
		bazel build //hw:verilator
	cd $(MATCHA_SRC_DIR) && \
		cp -rf --no-preserve=mode bazel-bin/hw/build.verilator/* "$(MATCHA_OUT_DIR)" && \
		chmod +x "$(MATCHA_OUT_DIR)/sim-verilator/Vchip_sim_tb"

$(MATCHA_OUT_ROM_SPLICES_DIR):
	@mkdir -p $(MATCHA_OUT_ROM_SPLICES_DIR)

##Build ROM splices to be included in the Nexus bitstream.
# This target is a requirement for matcha_hw_fpga_nexus and matcha_hw_fpga_v6.
matcha_hw_rom_splices: | $(MATCHA_OUT_ROM_SPLICES_DIR)
	@cd $(OPENTITAN_SRC_DIR) && \
		bazel build //sw/device/lib/testing/test_rom:test_rom_fpga_cw310_scr_vmem && \
		find "bazel-out/" -name "test_rom_fpga_cw310.scr.39.vmem" \
			-exec cp -f '{}' "$(MATCHA_OUT_ROM_SPLICES_DIR)/test_rom_fpga_nexus.scr.39.vmem" \;
	@cd $(OPENTITAN_SRC_DIR) && \
		bazel build //hw/ip/otp_ctrl/data:img_rma && \
		find "bazel-out/" -name "img_rma.24.vmem" \
			-exec cp -f '{}' "$(MATCHA_OUT_ROM_SPLICES_DIR)/otp_img_fpga_nexus.vmem" \;

## Build Matcha FPGA Target for Nexus Board.
# This target builds the FPGA bit file from hw/matcha using
# hw/opentitan-upstream as the library. The output is stored in
# out/matcha/hw/.
# This target is compute-intensive. Make sure you have a powerful enough machine
# and Vivado suporting the latest UltraScale+ device to build it.
# Move the $(MATCH_SRC_DIR) to the last, so some of prim_xilinx IPs will override the
# default one from $(OPENTITAN_HW_DIR)/ip.
matcha_hw_fpga_nexus: matcha_hw_rom_splices
	fusesoc --cores-root $(OPENTITAN_HW_DIR)/dv \
		--cores-root $(OPENTITAN_HW_DIR)/ip \
		--cores-root $(OPENTITAN_HW_DIR)/lint \
		--cores-root $(OPENTITAN_HW_DIR)/vendor \
		--cores-root $(MATCHA_SRC_DIR) \
		--cores-root $(ISP_SRC_DIR) \
		run \
		--flag=fileset_top --target=synth --setup \
		--build-root $(MATCHA_OUT_DIR) \
		--build google:systems:chip_matcha_nexus

## Build Matcha FPGA Target for  V6 Board.
# This target builds the FPGA bit file from hw/matcha using
# hw/opentitan-upstream as the library. The output is stored in
# out/matcha/hw/.
# This target is compute-intensive. Make sure you have a powerful enough machine
# and Vivado suporting the latest UltraScale device to build it.
# Move the $(MATCH_SRC_DIR) to the last, so some of prim_xilinx IPs will override the
# default one from $(OPENTITAN_HW_DIR)/ip.
matcha_hw_fpga_v6: matcha_hw_rom_splices
	fusesoc --cores-root $(OPENTITAN_HW_DIR)/dv \
		--cores-root $(OPENTITAN_HW_DIR)/ip \
		--cores-root $(OPENTITAN_HW_DIR)/lint \
		--cores-root $(OPENTITAN_HW_DIR)/vendor \
		--cores-root $(MATCHA_SRC_DIR) \
		--cores-root $(ISP_SRC_DIR) \
		run \
		--flag=fileset_top --target=synth --setup \
		--build-root $(MATCHA_OUT_DIR) \
		--build google:systems:chip_matcha_v6


## Run Matcha verilator simulation.
# This target runs the testbench with SW hello_world artifacts.
#
# This is a dev-only target (not for CI).
# TODO(hoangm): Change binary of SMC once multi-hart bootrom integration occurs.
matcha_hw_verilator_sim_run: matcha_smc_sram_img verilator \
		opentitan_sw_verilator_sim matcha_hw_verilator_sim matcha_sw_helloworld
	./scripts/run-chip-verilator-sim.sh $(MATCHA_VERILATOR_TB) \
		$(OPENTITAN_BUILD_SW_DEVICE_DIR)/boot_rom/boot_rom_sim_verilator.scr.39.vmem \
		$(OPENTITAN_BUILD_SW_DEVICE_DIR)/examples/hello_world/hello_world_sim_verilator.elf \
		$(OPENTITAN_BUILD_SW_DEVICE_DIR)/otp_img/otp_img_sim_verilator.vmem \
		$(MATCHA_SMC_BUILD_DIR)/matcha_smc_test.elf

$(MATCHA_HW_TEST_OUT):
	mkdir -p $(MATCHA_HW_TEST_OUT)
$(MATCHA_SW_DEVICE_DIR)/examples/hello_world: | $(MATCH_OUT_DIR)
	@mkdir -p "$(MATCHA_SW_DEVICE_DIR)/examples/hello_world"
$(MATCHA_SW_DEVICE_DIR)/tests: | $(MATCH_OUT_DIR)
	@mkdir -p "$(MATCHA_SW_DEVICE_DIR)/tests"
$(MATCHA_TESTLOG_DIR):
	mkdir -p $(MATCHA_TESTLOG_DIR)

$(MATCHA_HW_TEST_OUT)/matcha_hw_test.elf: | $(MATCHA_HW_TEST_OUT)
	# TODO(ykwang): Change target name to build all peripheral test elfs.
	cd $(MATCHA_SRC_DIR); \
	bazel build --cpu=riscv32 --crosstool_top=@toolchain//:cc-compiler-suite //sw/hw_tests:matcha_hw_test.elf
	cp -f $(MATCHA_SRC_DIR)/bazel-out/riscv32-fastbuild/bin/sw/hw_tests/*.elf $(MATCHA_HW_TEST_OUT)

## Build the ported helloworld test from opentitan.
# The output is stored at out/matcha/hw/sw/device/examples/hello_world
matcha_sw_helloworld: | $(MATCHA_SW_DEVICE_DIR)/examples/hello_world
	cd $(MATCHA_SRC_DIR) && \
		bazel build //sw/device/examples/hello_world:hello_world
	cd $(MATCHA_SRC_DIR) && \
		find "bazel-out/" -name "hello_world*.elf" \
		-exec cp -f '{}' "$(MATCHA_SW_DEVICE_DIR)/examples/hello_world" \;

## Build and run matcha verilator test suite
#
matcha_hw_verilator_tests: verilator | $(MATCHA_TESTLOG_DIR)
	cd $(MATCHA_SRC_DIR) && \
		bazel test --test_output=streamed //sw/device/tests:verilator_test_suite
	cd $(MATCHA_SRC_DIR) && cp -rf "bazel-testlogs/sw" "$(MATCHA_TESTLOG_DIR)"

$(MATCHA_SMC_BUILD_DIR):
	mkdir -p $(MATCHA_SMC_BUILD_DIR)

## Build Matcha SMC image artifact
#  TODO(hoangm): Move to matcha_sw.mk once more matcha binaries are ready
matcha_smc_sram_img: | $(MATCHA_SMC_BUILD_DIR)
	@cd $(MATCHA_SRC_DIR)/hw/top_matcha/ip/smc/examples/sw/simple_system/hello_test && \
		make && \
		cp hello_test.elf $(MATCHA_SMC_BUILD_DIR)/matcha_smc_test.elf


## Clean Matcha HW artifact
matcha_hw_clean:
	rm -rf $(MATCHA_OUT_DIR)

.PHONY:: matcha_hw_verilator_sim matcha_hw_verilator_sim_run  matcha_hw_clean
.PHONY:: matcha_hw_rom_splices matcha_smc_sram_img
.PHONY:: matcha_hw_verilator_tests
