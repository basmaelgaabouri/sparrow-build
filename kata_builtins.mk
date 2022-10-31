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

CANTRIP_APPS_RELEASE   := $(CANTRIP_OUT_C_APP_RELEASE)/hello/hello.app \
                       $(CANTRIP_OUT_RUST_APP_RELEASE)/fibonacci/fibonacci.app \
                       $(CANTRIP_OUT_RUST_APP_RELEASE)/keyval/keyval.app \
                       $(CANTRIP_OUT_RUST_APP_RELEASE)/logtest/logtest.app \
                       $(CANTRIP_OUT_RUST_APP_RELEASE)/panic/panic.app \
                       $(CANTRIP_OUT_C_APP_RELEASE)/suicide/suicide.app
CANTRIP_MODEL_RELEASE  := $(OUT)/springbok_iree/quant_models/mobilenet_v1_emitc_static.model

CANTRIP_APPS_DEBUG     := $(CANTRIP_OUT_C_APP_DEBUG)/hello/hello.app \
                       $(CANTRIP_OUT_RUST_APP_DEBUG)/fibonacci/fibonacci.app \
                       $(CANTRIP_OUT_RUST_APP_DEBUG)/keyval/keyval.app \
                       $(CANTRIP_OUT_RUST_APP_DEBUG)/logtest/logtest.app \
                       $(CANTRIP_OUT_RUST_APP_RELEASE)/panic/panic.app \
                       $(CANTRIP_OUT_C_APP_DEBUG)/suicide/suicide.app
CANTRIP_MODEL_DEBUG    := $(OUT)/springbok_iree/quant_models/mobilenet_v1_emitc_static.model

CANTRIP_SCRIPTS        := ${CANTRIP_SRC_DIR}/apps/repl/autostart.repl

CPIO := cpio
BUILTINS_CPIO_OPTS := -H newc -L --no-absolute-filenames --reproducible --owner=root:root

# HACK(jtgans): Fix the IREE targets to explicitly list the files it generates.
$(patsubst %.model,%,$(CANTRIP_MODEL_RELEASE)): iree_model_builtins
$(patsubst %.model,%,$(CANTRIP_MODEL_DEBUG)): iree_model_builtins

$(OUT)/cantrip/builtins/release: $(CANTRIP_APPS_RELEASE) $(CANTRIP_MODEL_RELEASE)
	rm -rf $@
	mkdir -p $@
	cp $(CANTRIP_APPS_RELEASE) $(CANTRIP_MODEL_RELEASE) ${CANTRIP_SCRIPTS} $@

$(OUT)/cantrip/builtins/debug: $(CANTRIP_APPS_DEBUG) $(CANTRIP_MODEL_DEBUG)
	rm -rf $@
	mkdir -p $@
	cp $(CANTRIP_APPS_DEBUG) $(CANTRIP_MODEL_DEBUG) ${CANTRIP_SCRIPTS} $@

$(OUT)/ext_builtins_release.cpio: $(OUT)/cantrip/builtins/release
	ls -1 $(OUT)/cantrip/builtins/release \
        | $(CPIO) -o -D $(OUT)/cantrip/builtins/release $(BUILTINS_CPIO_OPTS) -O "$@"

$(OUT)/ext_builtins_debug.cpio: $(OUT)/cantrip/builtins/debug
	ls -1 $(OUT)/cantrip/builtins/debug \
        | $(CPIO) -o -D $(OUT)/cantrip/builtins/debug $(BUILTINS_CPIO_OPTS) -O "$@"

## Generates cpio archive of Cantrip builtins with debugging suport
cantrip-builtins-debug: $(OUT)/ext_builtins_debug.cpio
## Generates cpio archive of Cantrip builtins for release
cantrip-builtins-release: $(OUT)/ext_builtins_release.cpio
## Generates both debug & release cpio archives of Cantrip builtins
cantrip-builtins: cantrip-builtins-debug cantrip-builtins-release

cantrip-builtins-clean:
	rm -rf $(OUT)/cantrip/builtins
	rm -f $(OUT)/ext_builtins_release.cpio
	rm -f $(OUT)/ext_builtins_debug.cpio

.PHONY:: cantrip-builtins-debug
.PHONY:: cantrip-builtins-release
.PHONY:: cantrip-builtins
.PHONY:: cantrip-builtins-clean

# Enforce rebuilding of the builtins directory each time
.PHONY:: $(OUT)/builtins/release $(OUT)/builtins/debug
