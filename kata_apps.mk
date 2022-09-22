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

# C apps

KATA_SRC_C_APP := $(KATA_SRC_DIR)/apps/c
KATA_OUT_C_APP_DEBUG := $(KATA_OUT_DEBUG)/apps/c
KATA_OUT_C_APP_RELEASE := $(KATA_OUT_RELEASE)/apps/c

$(KATA_OUT_C_APP_DEBUG)/%.elf: $(KATA_SRC_C_APP)/%.c $(KATA_KERNEL_DEBUG)
	$(MAKE) -C $(dir $<) \
        LIBSEL4_SRC=$(SEL4_KERNEL_DIR)/libsel4 \
        OUT_KATA=$(KATA_OUT_DEBUG) \
		BUILD_ROOT=$(KATA_OUT_C_APP_DEBUG) \
		BUILD_TYPE=debug
.PRECIOUS:: $(KATA_OUT_C_APP_DEBUG)/%.elf

$(KATA_OUT_C_APP_RELEASE)/%.elf: $(KATA_SRC_C_APP)/%.c $(KATA_KERNEL_RELEASE)
	$(MAKE) -C $(dir $<) \
        LIBSEL4_SRC=$(SEL4_KERNEL_DIR)/libsel4 \
        OUT_KATA=$(KATA_OUT_RELEASE) \
		BUILD_ROOT=$(KATA_OUT_C_APP_RELEASE) \
		BUILD_TYPE=release
.PRECIOUS:: $(KATA_OUT_C_APP_RELEASE)/%.elf

# Rust apps

KATA_SRC_RUST_APP := $(KATA_SRC_DIR)/apps/rust
KATA_OUT_RUST_APP_DEBUG := $(KATA_OUT_DEBUG)/apps/rust
KATA_OUT_RUST_APP_RELEASE := $(KATA_OUT_RELEASE)/apps/rust

$(KATA_OUT_RUST_APP_DEBUG)/%.elf: $(KATA_SRC_RUST_APP)/%.rs $(KATA_KERNEL_DEBUG)
	$(MAKE) -C $(dir $<) \
        OUT_KATA=$(KATA_OUT_DEBUG) \
		BUILD_ROOT=$(KATA_OUT_RUST_APP_DEBUG) \
		BUILD_TYPE=debug
.PRECIOUS:: $(KATA_OUT_RUST_APP_DEBUG)/%.elf

$(KATA_OUT_RUST_APP_RELEASE)/%.elf: $(KATA_SRC_RUST_APP)/%.rs $(KATA_KERNEL_RELEASE)
	$(MAKE) -C $(dir $<) \
        OUT_KATA=$(KATA_OUT_RELEASE) \
		BUILD_ROOT=$(KATA_OUT_RUST_APP_RELEASE) \
		BUILD_TYPE=release
.PRECIOUS:: $(KATA_OUT_RUST_APP_RELEASE)/%.elf

## Build the hello-world C application in debug mode.
hello_debug: $(KATA_OUT_C_APP_DEBUG)/hello/hello.app
## Build the hello-world C application in release mode.
hello_release: $(KATA_OUT_RUST_APP_RELEASE)/hello/hello.app

## Build the fibonacci C application in debug mode.
fibonacci_debug: $(KATA_OUT_C_APP_DEBUG)/fibonacci/fibonacci.app
## Build the fibonacci C application in release mode.
fibonacci_release: $(KATA_OUT_RUST_APP_RELEASE)/fibonacci/fibonacci.app

## Build the keyval Rust application in debug mode.
keyval_debug: $(KATA_OUT_RUST_APP_DEBUG)/keyval/keyval.app
## Build the keyval Rust application in release mode.
keyval_release: $(KATA_OUT_RUST_APP_RELEASE)/keyval/keyval.app

## Build the panic Rust application in debug mode.
panic_debug: $(KATA_OUT_RUST_APP_DEBUG)/panic/panic.app
## Build the panic Rust application in release mode.
panic_release: $(KATA_OUT_RUST_APP_RELEASE)/panic/panic.app

## Build the suicide C application in debug mode.
suicide_debug: $(KATA_OUT_C APP_DEBUG)/suicide/suicide.app
## Build the suicide C application in release mode.
suicide_release: $(KATA_OUT_C APP_RELEASE)/suicide/suicide.app

.PHONY:: hello_debug hello_release
.PHONY:: fibonacci_debug fibonacci_release
.PHONY:: keyval_debug keyval_release
.PHONY:: panic_debug panic_release
.PHONY:: suicide_debug suicide_release
