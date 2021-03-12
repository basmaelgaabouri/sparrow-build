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
	$(ROOTDIR)/scripts/install-prereqs.sh

include $(ROOTDIR)/build/toolchain.mk
include $(ROOTDIR)/build/kata.mk
include $(ROOTDIR)/build/sim.mk
include $(ROOTDIR)/build/opentitan_sw.mk
include $(ROOTDIR)/build/sparrow_test_sw.mk
include $(ROOTDIR)/build/tock.mk

$(OUT):
	@mkdir -p $(OUT)

tools: toolchain_rust toolchain toolchain_vp verilator renode

clean::
	rm -rf $(OUT)

.PHONY:: prereqs clean kata simulate-kata tools
