# Copyright 2020 Google LLC
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

SHELL := $(shell which /bin/bash)

ifeq ($(ROOTDIR),)
$(error $$ROOTDIR IS NOT DEFINED -- don\'t forget to source setup.sh)
endif

.DEFAULT_GOAL := simulate

include $(ROOTDIR)/build/preamble.mk

## Installs build prerequisites
#
# This installs a series of typical Linux tools needed to build the whole of the
# sparrow system.
prereqs: $(ROOTDIR)/scripts/install-prereqs.sh \
         $(ROOTDIR)/hw/opentitan-upstream/python-requirements.txt \
         $(ROOTDIR)/hw/opentitan-upstream/apt-requirements.txt
	$(ROOTDIR)/scripts/install-prereqs.sh \
		-p "$(ROOTDIR)/hw/opentitan-upstream/python-requirements.txt" \
		-a "$(ROOTDIR)/hw/opentitan-upstream/apt-requirements.txt"


include $(ROOTDIR)/build/toolchain.mk
include $(ROOTDIR)/build/kata.mk
include $(ROOTDIR)/build/tock.mk
include $(ROOTDIR)/build/opentitan_sw.mk
include $(ROOTDIR)/build/springbok.mk

include $(ROOTDIR)/build/iree.mk
include $(ROOTDIR)/build/sparrow_boot_rom.mk
include $(ROOTDIR)/build/riscv_toolchain.mk
include $(ROOTDIR)/build/renode.mk
include $(ROOTDIR)/build/verilator.mk

# Must be after other makefiles so that we pick up various $(TARGETS)
include $(ROOTDIR)/build/sim.mk

$(OUT):
	@mkdir -p $(OUT)

## Installs the RISCV compiler and emulator tooling
#
# This includes Rust, GCC, CLANG, verilator, qemu, and renode.
#
# Output is placed in cache/ and out/host.
tools: toolchain_rust install_gcc install_llvm verilator renode qemu

## Cleans the entire system
#
# This amounts to an `rm -rf out/` and removes all build artifacts.
clean::
	rm -rf $(OUT)

.PHONY:: prereqs clean kata simulate tools
