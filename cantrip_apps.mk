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

# CantripOS Test Applications

# NB: these are platform-specific
RUST_TARGET     := unknown
CANTRIP_APP_ARCH   := unknown

# TODO(jtgans): should include from platforms/${PLATFORM}/platform.mk
include $(ROOTDIR)/build/platforms/$(PLATFORM)/cantrip_apps.mk

# C apps

CANTRIP_SRC_C_APP := $(CANTRIP_SRC_DIR)/apps/c
CANTRIP_OUT_C_APP_DEBUG := $(CANTRIP_OUT_DEBUG)/apps/c
CANTRIP_OUT_C_APP_RELEASE := $(CANTRIP_OUT_RELEASE)/apps/c

$(CANTRIP_OUT_C_APP_DEBUG)/%.elf: $(CANTRIP_SRC_C_APP)/%.c $(CANTRIP_KERNEL_DEBUG)
	$(MAKE) -C $(dir $<) \
        LIBSEL4_SRC=$(SEL4_KERNEL_DIR)/libsel4 \
        OUT_CANTRIP=$(CANTRIP_OUT_DEBUG) \
        BUILD_ARCH=${CANTRIP_APP_ARCH} \
        BUILD_ROOT=$(CANTRIP_OUT_C_APP_DEBUG) \
        RUST_TARGET=${RUST_TARGET} \
        BUILD_TYPE=debug
.PRECIOUS:: $(CANTRIP_OUT_C_APP_DEBUG)/%.elf

$(CANTRIP_OUT_C_APP_RELEASE)/%.elf: $(CANTRIP_SRC_C_APP)/%.c $(CANTRIP_KERNEL_RELEASE)
	$(MAKE) -C $(dir $<) \
        LIBSEL4_SRC=$(SEL4_KERNEL_DIR)/libsel4 \
        OUT_CANTRIP=$(CANTRIP_OUT_RELEASE) \
        BUILD_ARCH=${CANTRIP_APP_ARCH} \
        RUST_TARGET=${RUST_TARGET} \
        BUILD_ROOT=$(CANTRIP_OUT_C_APP_RELEASE) \
        BUILD_TYPE=release
.PRECIOUS:: $(CANTRIP_OUT_C_APP_RELEASE)/%.elf

# Rust apps

CANTRIP_SRC_RUST_APP := $(CANTRIP_SRC_DIR)/apps/rust
CANTRIP_OUT_RUST_APP_DEBUG := $(CANTRIP_OUT_DEBUG)/apps/rust
CANTRIP_OUT_RUST_APP_RELEASE := $(CANTRIP_OUT_RELEASE)/apps/rust

# NB: pass SEL4_DIR for sel4-config to find the kernel

$(CANTRIP_OUT_RUST_APP_DEBUG)/%.elf: $(CANTRIP_SRC_RUST_APP)/%.rs $(CANTRIP_KERNEL_DEBUG)
	$(MAKE) -C $(dir $<) \
        OUT_CANTRIP=$(CANTRIP_OUT_DEBUG) \
        SEL4_DIR=$(SEL4_KERNEL_DIR) \
        BUILD_ARCH=${CANTRIP_APP_ARCH} \
        RUST_TARGET=${RUST_TARGET} \
        BUILD_ROOT=$(CANTRIP_OUT_RUST_APP_DEBUG) \
        BUILD_TYPE=debug
.PRECIOUS:: $(CANTRIP_OUT_RUST_APP_DEBUG)/%.elf

$(CANTRIP_OUT_RUST_APP_RELEASE)/%.elf: $(CANTRIP_SRC_RUST_APP)/%.rs $(CANTRIP_KERNEL_RELEASE)
	$(MAKE) -C $(dir $<) \
        OUT_CANTRIP=$(CANTRIP_OUT_RELEASE) \
        SEL4_DIR=$(SEL4_KERNEL_DIR) \
        BUILD_ARCH=${CANTRIP_APP_ARCH} \
        RUST_TARGET=${RUST_TARGET} \
        BUILD_ROOT=$(CANTRIP_OUT_RUST_APP_RELEASE) \
        BUILD_TYPE=release
.PRECIOUS:: $(CANTRIP_OUT_RUST_APP_RELEASE)/%.elf

## Build the hello-world C application in debug mode.
hello_debug: $(CANTRIP_OUT_C_APP_DEBUG)/hello/hello.app
## Build the hello-world C application in release mode.
hello_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/hello/hello.app

## Build the fibonacci C application in debug mode.
fibonacci_debug: $(CANTRIP_OUT_C_APP_DEBUG)/fibonacci/fibonacci.app
## Build the fibonacci C application in release mode.
fibonacci_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/fibonacci/fibonacci.app

## Build the keyval Rust application in debug mode.
keyval_debug: $(CANTRIP_OUT_RUST_APP_DEBUG)/keyval/keyval.app
## Build the keyval Rust application in release mode.
keyval_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/keyval/keyval.app

## Build the logtest Rust application in debug mode.
logtest_debug: $(CANTRIP_OUT_RUST_APP_DEBUG)/logtest/logtest.app
## Build the logtest Rust application in release mode.
logtest_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/logtest/logtest.app

## Build the panic Rust application in debug mode.
panic_debug: $(CANTRIP_OUT_RUST_APP_DEBUG)/panic/panic.app
## Build the panic Rust application in release mode.
panic_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/panic/panic.app

## Build the suicide C application in debug mode.
suicide_debug: $(CANTRIP_OUT_C APP_DEBUG)/suicide/suicide.app
## Build the suicide C application in release mode.
suicide_release: $(CANTRIP_OUT_C APP_RELEASE)/suicide/suicide.app

## Build the timer Rust application in debug mode.
timer_debug: $(CANTRIP_OUT_RUST_APP_DEBUG)/timer/timer.app
## Build the timer Rust application in release mode.
timer_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/timer/timer.app

## Build the test Rust application in debug mode.
test_debug: $(CANTRIP_OUT_RUST_APP_DEBUG)/test/test.app
## Build the test Rust application in release mode.
test_release: $(CANTRIP_OUT_RUST_APP_RELEASE)/test/test.app

.PHONY:: hello_debug hello_release
.PHONY:: fibonacci_debug fibonacci_release
.PHONY:: keyval_debug keyval_release
.PHONY:: logtest_debug logtest_release
.PHONY:: panic_debug panic_release
.PHONY:: suicide_debug suicide_release
.PHONY:: timer_debug timer_release
