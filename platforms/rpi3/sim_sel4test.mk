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

# sel4test simulation support; this is meant to be included from sim.mk

# NB: default is to use debug builds for compat with upstream.

## Launches an end-to-end debug build of the sel4test system. The result
## is run under qemu.
sel4test: ${SEL4TEST_OUT_DEBUG}/capdl-loader-image | qemu_presence_check
	$(QEMU_CMD) -kernel ${SEL4TEST_OUT_DEBUG}/capdl-loader-image
sel4test-debug: sel4test

$(SEL4TEST_OUT_DEBUG)/capdl-loader-image: $(SEL4TEST_KERNEL_DEBUG) \
		$(SEL4TEST_ROOTSERVER_DEBUG) ${SEL4TEST_OUT_DEBUG}/elfloader/elfloader
	${C_PREFIX}objcopy -O binary ${SEL4TEST_OUT_DEBUG}/elfloader/elfloader $@

## Launches a version of the sel4test target that uses the sel4-sys Rust
## crate wrapped with C shims. The result is run under qemu.
sel4test+wrapper: ${SEL4TEST_WRAPPER_OUT_DEBUG}/capdl-loader-image | qemu_presence_check
	$(QEMU_CMD) -kernel ${SEL4TEST_WRAPPER_OUT_DEBUG}/capdl-loader-image

$(SEL4TEST_WRAPPER_OUT_DEBUG)/capdl-loader-image: $(SEL4TEST_KERNEL_DEBUG) \
		$(SEL4TEST_WRAPPER_ROOTSERVER_DEBUG) ${SEL4TEST_WRAPPER_OUT_DEBUG}/elfloader/elfloader
	${C_PREFIX}objcopy -O binary ${SEL4TEST_WRAPPER_OUT_DEBUG}/elfloader/elfloader $@

.PHONY:: sel4test
.PHONY:: sel4test-debug
.PHONY:: sel4test+wrapper
