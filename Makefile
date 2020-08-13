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

include $(ROOTDIR)/build/preamble.mk

prereqs: $(ROOTDIR)/scripts/install-prereqs.sh
	sudo $(ROOTDIR)/scripts/install-prereqs.sh

KATA_CMAKE_ARGS := -DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- \
                   -DCMAKE_BUILD_TYPE=Release \
                   -DCMAKE_TOOLCHAIN_FILE=$(ROOTDIR)/kata/kernel/gcc.cmake \
                   -DSEL4_CACHE_DIR=$(OUT)/kata/sel4_cache \
                   -G Ninja

kata: $(ROOTDIR)/kata | out-dir
	@mkdir -p $(OUT)/kata
	pushd $(OUT)/kata; cmake $(KATA_CMAKE_ARGS) $(ROOTDIR)/kata; ninja

out-dir:
	@mkdir -p $(OUT)

clean::
	rm -rf $(OUT)

.PHONY:: prereqs clean kata
