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

SYSTEMC_SRC_DIR     := $(ROOTDIR)/sim/systemc
SYSTEMC_BUILD_DIR   := $(OUT)/systemc
SYSTEMC_INSTALL_DIR := $(OUT)/host/systemc

$(SYSTEMC_BUILD_DIR):
	mkdir -p $(SYSTEMC_BUILD_DIR)

## Builds the System C Libraries
#
# Using sources in sim/systemc, this target builds systemc from source and stores
# its output in out/host/systemc.
#
# To rebuild this target, run `m systemc_clean` and re-run.
#
systemc: | $(SYSTEMC_BUILD_DIR)
	cmake -B $(SYSTEMC_BUILD_DIR) \
		-DCMAKE_INSTALL_PREFIX=$(SYSTEMC_INSTALL_DIR) \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=False \
		-DCMAKE_CXX_STANDARD=17 \
		-G Ninja \
		$(SYSTEMC_SRC_DIR)
	cmake --build $(SYSTEMC_BUILD_DIR) --target install

## Removes systemc build artifacts and install from out/
systemc_clean:
	@rm -rf $(SYSTEMC_BUILD_DIR)
	@rm -rf $(SYSTEMC_INSTALL_DIR)

SYSTEMCV_SRC_DIR     := $(ROOTDIR)/sim/systemcv
SYSTEMCV_BUILD_DIR   := $(OUT)/systemcv
SYSTEMCV_INSTALL_DIR := $(OUT)/host/systemcv

$(SYSTEMCV_BUILD_DIR):
	mkdir -p $(SYSTEMCV_BUILD_DIR)

## Builds the System C Verification Libraries
#
# Using sources in sim/systemcv, this target builds systemcv from source and stores
# its output in out/host/systemcv.
#
# To rebuild this target, run `m systemcv_clean` and re-run.
#

systemcv: systemc | $(SYSTEMCV_BUILD_DIR)
	cd $(SYSTEMCV_BUILD_DIR) && \
		rsync -avHx --exclude=.git $(SYSTEMCV_SRC_DIR)/ $(SYSTEMCV_BUILD_DIR)
	cd $(SYSTEMCV_BUILD_DIR) && \
		./config/bootstrap
	cd $(SYSTEMCV_BUILD_DIR) && $(SYSTEMCV_BUILD_DIR)/configure \
		--srcdir=$(SYSTEMCV_BUILD_DIR) \
		--prefix=$(SYSTEMCV_INSTALL_DIR) \
		--with-systemc=$(SYSTEMC_INSTALL_DIR) \
		--enable-static=yes \
		--enable-shared=no
	$(MAKE) -C $(SYSTEMCV_BUILD_DIR)
	$(MAKE) -C $(SYSTEMCV_BUILD_DIR) install


## Removes systemc verification build artifacts and install from out/
systemcv_clean:
	@rm -rf $(SYSTEMCV_BUILD_DIR)
	@rm -rf $(SYSTEMCV_INSTALL_DIR)

clean:: systemc_clean systemcv_clean

.PHONY:: systemc systemc_clean systemcv systemcv_clean
