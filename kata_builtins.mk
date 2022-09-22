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

KATA_APPS_RELEASE   := $(KATA_OUT_C_APP_RELEASE)/hello/hello.app \
                       $(KATA_OUT_RUST_APP_RELEASE)/fibonacci/fibonacci.app \
                       $(KATA_OUT_RUST_APP_RELEASE)/keyval/keyval.app \
                       $(KATA_OUT_RUST_APP_RELEASE)/panic/panic.app \
                       $(KATA_OUT_C_APP_RELEASE)/suicide/suicide.app
KATA_MODEL_RELEASE  := $(OUT)/springbok_iree/quant_models/mobilenet_v1_emitc_static.model

KATA_APPS_DEBUG     := $(KATA_OUT_C_APP_DEBUG)/hello/hello.app \
                       $(KATA_OUT_RUST_APP_DEBUG)/fibonacci/fibonacci.app \
                       $(KATA_OUT_RUST_APP_DEBUG)/keyval/keyval.app \
                       $(KATA_OUT_RUST_APP_RELEASE)/panic/panic.app \
                       $(KATA_OUT_C_APP_DEBUG)/suicide/suicide.app
KATA_MODEL_DEBUG    := $(OUT)/springbok_iree/quant_models/mobilenet_v1_emitc_static.model

CPIO := cpio
BUILTINS_CPIO_OPTS := -H newc -L --no-absolute-filenames --reproducible --owner=root:root

# HACK(jtgans): Fix the IREE targets to explicitly list the files it generates.
$(patsubst %.model,%,$(KATA_MODEL_RELEASE)): iree_model_builtins
$(patsubst %.model,%,$(KATA_MODEL_DEBUG)): iree_model_builtins

$(OUT)/kata/builtins/release: $(KATA_APPS_RELEASE) $(KATA_MODEL_RELEASE)
	rm -rf $@
	mkdir -p $@
	cp $(KATA_APPS_RELEASE) $(KATA_MODEL_RELEASE) $@

$(OUT)/kata/builtins/debug: $(KATA_APPS_DEBUG) $(KATA_MODEL_DEBUG)
	rm -rf $@
	mkdir -p $@
	cp $(KATA_APPS_DEBUG) $(KATA_MODEL_DEBUG) $@

$(OUT)/ext_builtins_release.cpio: $(OUT)/kata/builtins/release
	ls -1 $(OUT)/kata/builtins/release \
        | $(CPIO) -o -D $(OUT)/kata/builtins/release $(BUILTINS_CPIO_OPTS) -O "$@"

$(OUT)/ext_builtins_debug.cpio: $(OUT)/kata/builtins/debug
	ls -1 $(OUT)/kata/builtins/debug \
        | $(CPIO) -o -D $(OUT)/kata/builtins/debug $(BUILTINS_CPIO_OPTS) -O "$@"

## Generates cpio archive of Kata builtins with debugging suport
kata-builtins-debug: $(OUT)/ext_builtins_debug.cpio
## Generates cpio archive of Kata builtins for release
kata-builtins-release: $(OUT)/ext_builtins_release.cpio
## Generates both debug & release cpio archives of Kata builtins
kata-builtins: kata-builtins-debug kata-builtins-release

kata-builtins-clean:
	rm -rf $(OUT)/kata/builtins
	rm -f $(OUT)/ext_builtins_release.cpio
	rm -f $(OUT)/ext_builtins_debug.cpio

.PHONY:: kata-builtins-debug
.PHONY:: kata-builtins-release
.PHONY:: kata-builtins
.PHONY:: kata-builtins-clean

# Enforce rebuilding of the builtins directory each time
.PHONY:: $(OUT)/builtins/release $(OUT)/builtins/debug
