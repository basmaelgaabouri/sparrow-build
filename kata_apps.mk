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

# KataOS Test Applications

KATA_SRC_C_APP := $(KATA_SRC_DIR)/apps/c
KATA_SRC_RUST_APP := $(KATA_SRC_DIR)/apps/rust

# NB: this assumes you won't have C & Rust apps w/ the same name
KATA_OUT_APP_DEBUG := $(KATA_OUT_DEBUG)/apps
KATA_OUT_APP_RELEASE := $(KATA_OUT_RELEASE)/apps

$(KATA_OUT_APP_DEBUG)/%.elf: $(KATA_SRC_C_APP)/%.c $(KATA_KERNEL_DEBUG)
	$(MAKE) -C $(dir $<) \
        SRC_LIBSEL4=$(SEL4_KERNEL_DIR)/libsel4 \
        OUT_KATA=$(KATA_OUT_DEBUG) \
        OUT_TMP=$(dir $@)
.PRECIOUS:: $(KATA_OUT_APP_DEBUG)/%.elf

$(KATA_OUT_APP_RELEASE)/%.elf: $(KATA_SRC_C_APP)/%.c $(KATA_KERNEL_RELEASE)
	$(MAKE) -C $(dir $<) \
        SRC_LIBSEL4=$(SEL4_KERNEL_DIR)/libsel4 \
        OUT_KATA=$(KATA_OUT_RELEASE) \
        OUT_TMP=$(dir $@)
.PRECIOUS:: $(KATA_OUT_APP_RELEASE)/%.elf

## Build the hello-world C application in debug mode.
hello_debug: $(KATA_OUT_APP_DEBUG)/hello/hello.app
## Build the hello-world C application in release mode.
hello_release: $(KATA_OUT_APP_RELEASE)/hello/hello.app

## Build the fibonacci C application in debug mode.
fibonacci_debug: $(KATA_OUT_APP_DEBUG)/fibonacci/fibonacci.app
## Build the fibonacci C application in release mode.
fibonacci_release: $(KATA_OUT_APP_RELEASE)/fibonacci/fibonacci.app

## Build the suicide C application in debug mode.
suicide_debug: $(KATA_OUT_APP_DEBUG)/suicide/suicide.app
## Build the suicide C application in release mode.
suicide_release: $(KATA_OUT_APP_RELEASE)/suicide/suicide.app

.PHONY:: hello_debug hello_release
.PHONY:: fibonacci_debug fibonacci_release
.PHONY:: suicide_debug suicide_release
