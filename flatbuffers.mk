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

FLATBUFFERS_SRC_DIR     := $(ROOTDIR)/sw/flatbuffers
FLATBUFFERS_BUILD_DIR   := $(OUT)/flatbuffers
FLATBUFFERS_INSTALL_DIR := $(OUT)/host/flatbuffers
FLATBUFFERS_FLATC       := $(OUT)/host/flatbuffers/bin/flatc

# NB: We only need to depend on some of the files in the host source tree from
# the flatbuffers repo, so a simple single directory wildcard should suffice for
# determining when we need to rebuild this target.
FLATBUFFERS_SRCS := $(wildcard $(FLATBUFFERS_SRC_DIR)/src/*)

$(FLATBUFFERS_BUILD_DIR):
	mkdir -p $(FLATBUFFERS_BUILD_DIR)

$(FLATBUFFERS_FLATC): $(FLATBUFFERS_SRCS) | $(FLATBUFFERS_BUILD_DIR)
	cmake -S $(FLATBUFFERS_SRC_DIR) -B $(FLATBUFFERS_BUILD_DIR) -G Ninja \
		-DCMAKE_INSTALL_PREFIX=$(FLATBUFFERS_INSTALL_DIR)
	ninja -C $(OUT)/flatbuffers install

## Builds and installs the flatbuffers host tooling
#
# Output is placed in the out/host/flatbuffers tree.
flatbuffers: $(FLATBUFFERS_FLATC)

## Cleans up the flatbuffers binaries
flatbuffers-clean:
	rm -rf $(FLATBUFFERS_BUILD_DIR) $(FLATBUFFERS_INSTALL_DIR)

.PHONY:: flatbuffers
