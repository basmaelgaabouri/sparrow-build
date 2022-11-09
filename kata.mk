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

# Builds Cantrip, the seL4-based operating system with a Rust-based userland.
# The source is in $(CANTRIP_SRC_DIR), while the outputs are placed in
# $(CANTRIP_KERNEL_DEBUG) & $(CANTRIP_ROOTSERVER_DEBUG) or
# $(CANTRIP_KERNEL_RELEASE) & $(CANTRIP_ROOTSERVER_RELEASE).

# Drivers for each platform and platform-specific make targets are stored in
# platform/$PLATFORM/platform.mk make files. Everything in this file must be
# made platform-agnostic. As such, we use phony targets that can be extended in
# the platform.mk files as double-colon (::) aggregate targets. These phony
# targets are explicitly grouped and have notes in their doccomments.

# NB: see $(CANTRIP_SRC_DIR)/easy-settings.cmake for config knobs;
#     but beware you may need to "clean" before building with changes

CANTRIP_SRC_DIR      := $(ROOTDIR)/cantrip/projects/cantrip
CANTRIP_COMPONENTS   := $(CANTRIP_SRC_DIR)/apps/system/components
CARGO_CMD         := cargo +$(CANTRIP_RUST_VERSION)
CARGO_TEST        := ${CARGO_CMD} test

# Location of seL4 kernel source (for sel4-sys)
SEL4_KERNEL_DIR  := $(ROOTDIR)/cantrip/kernel

CANTRIP_OUT_DIR     := $(OUT)/cantrip/$(CANTRIP_TARGET_ARCH)
CANTRIP_OUT_DEBUG   := $(CANTRIP_OUT_DIR)/debug
CANTRIP_OUT_RELEASE := $(CANTRIP_OUT_DIR)/release

# seL4 kernel included in the ext flash tarball
CANTRIP_KERNEL_DEBUG   := $(CANTRIP_OUT_DEBUG)/kernel/kernel.elf
CANTRIP_KERNEL_RELEASE := $(CANTRIP_OUT_RELEASE)/kernel/kernel.elf

# Rootserver image that has the CAmkES components embedded in
# the ELF image in a ._archive_cpio section.
CANTRIP_ROOTSERVER_DEBUG := $(CANTRIP_OUT_DEBUG)/capdl-loader
CANTRIP_ROOTSERVER_RELEASE := $(CANTRIP_OUT_RELEASE)/capdl-loader

CANTRIP_SOURCES := $(shell find $(ROOTDIR)/cantrip \
	-name \*.rs -or \
	-name \*.c -or \
	-name \*.h -or \
	-name \*.cpp \
	-type f)

# Platform-specific aggregate targets

## Builds auto-generated include files for the Cantrip operating system
#
# In the generic case, this doesn't do anything except generate headers for our
# Rust components to use from the CAmkES assemblies. It's an aggregate target,
# though, so that platform-specific headers may also be generated from other
# parts of the project.
#
# Note: this is a platform-specific aggregate phony target, and additional rules
# for each platform are defined in build/$PLATFORM/platform.mk
cantrip-gen-headers:: cantrip-component-headers

## Cleans the auto-generated Cantrip include files
#
# Note: this is a platform-specific aggregate phony target, and additional rules
# for each platform are defined in build/$PLATFORM/platform.mk
cantrip-clean-headers::
	rm -f $(OUT)/cantrip/components

## Cantrip debug build-tree preparation target
#
# Prepares the output directory tree for building. In the generic case, this
# just makes our target directory tree, but each specific platform may also need
# to link in source files or modify the target tree somewhat. This aggregate
# target provides that functionality for a debug build.
#
# Note: this is a platform-specific aggregate phony target, and additional rules
# for each platform are defined in build/$PLATFORM/platform.mk
cantrip-build-debug-prepare:: | $(CANTRIP_OUT_DEBUG)

## Cantrip release build-tree preparation target
#
# Prepares the output directory tree for building. In the generic case, this
# just makes our target directory tree, but each specific platform may also need
# to link in source files or modify the target tree somewhat. This aggregate
# target provides that functionality for a release build.
#
# Note: this is a platform-specific aggregate phony target, and additional rules
# for each platform are defined in build/$PLATFORM/platform.mk
cantrip-build-release-prepare:: | $(CANTRIP_OUT_RELEASE)

# Cantrip-generic targets

## Cleans all Cantrip operating system build artifacts
cantrip-clean:
	rm -rf $(OUT)/cantrip

$(RUSTDIR)/bin/cbindgen: | rust_presence_check
	${CARGO_CMD} install cbindgen

$(OUT)/cantrip/components:
	mkdir -p $(OUT)/cantrip/components

## Builds cbindgen headers for Cantrip components
#
# This target regenerates these header definitions using Makefiles embedded in
# each component's source tree.
cantrip-component-headers: $(RUSTDIR)/bin/cbindgen | rust_presence_check $(OUT)/cantrip/components
	for f in $$(find $(CANTRIP_COMPONENTS) -name cbindgen.toml); do \
		dir=$$(dirname $$f); \
		test -f $$dir/Makefile && $(MAKE) -C $$dir; \
	done

$(CANTRIP_OUT_DEBUG):
	mkdir -p $(CANTRIP_OUT_DEBUG)

$(CANTRIP_OUT_RELEASE):
	mkdir -p $(CANTRIP_OUT_RELEASE)

# Build Cantrip bundles. A bundle is an seL4 kernel elf plus the user space
# bits: rootserver + CAmkES components (embedded in the rootserver elf).
# Crates that depend on the kernel check the SEL4_OUT_DIR environment
# variable for the location of the files generated for the kernel.
# We also pass SEL4_DIR in the environment; though the default logic
# in crates that use sel4-config can calculate this if SEL4_DIR is
# not defined.
#
# NB: files generated by cantrip-gen-headers are shared so we craft
#     a symlink in the target-specific build directories

$(CANTRIP_KERNEL_DEBUG): $(CANTRIP_SOURCES) cantrip-gen-headers cantrip-build-debug-prepare | $(CANTRIP_OUT_DEBUG) rust_presence_check
	cmake -B $(CANTRIP_OUT_DEBUG) -G Ninja \
		-DCROSS_COMPILER_PREFIX=$(C_PREFIX) \
		-DRUST_TARGET=${RUST_TARGET} \
		-DPLATFORM=${PLATFORM} \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4-debug \
		-DRELEASE=OFF \
	  $(CANTRIP_SRC_DIR)
	SEL4_DIR=$(SEL4_KERNEL_DIR) \
	SEL4_OUT_DIR=$(CANTRIP_OUT_DEBUG)/kernel \
		ninja -C $(CANTRIP_OUT_DEBUG)

## Generates Cantrip operating build artifacts with debugging suport
cantrip-bundle-debug: $(CANTRIP_KERNEL_DEBUG)

$(CANTRIP_KERNEL_RELEASE): $(CANTRIP_SOURCES) cantrip-gen-headers cantrip-build-release-prepare | $(CANTRIP_OUT_RELEASE) rust_presence_check
	cmake -B $(CANTRIP_OUT_RELEASE) -G Ninja \
		-DCROSS_COMPILER_PREFIX=$(C_PREFIX) \
		-DRUST_TARGET=${RUST_TARGET} \
		-DPLATFORM=${PLATFORM} \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4-release \
		-DRELEASE=ON \
		 $(CANTRIP_SRC_DIR)
	SEL4_DIR=$(SEL4_KERNEL_DIR) \
	SEL4_OUT_DIR=$(CANTRIP_OUT_RELEASE)/kernel \
		ninja -C $(CANTRIP_OUT_RELEASE)

## Generates Cantrip operating build artifacts setup for release
cantrip-bundle-release: $(CANTRIP_KERNEL_RELEASE)

## Generates both debug & release Cantrip operating system build artifacts
#
# NB: shorthand for testing (sim targets depend on explicit pathnames)
cantrip: cantrip-bundle-debug cantrip-bundle-release

# NB: cargo_test_debugconsole_zmodem is broken
#	TODO(b/232928288): temporarily disable cargo_test_cantrip_proc_manager &
#   cargo_test_cantrip_proc_interface; they have dependency issues
CARGO_TEST_CANTRIP=\
	cargo_test_cantrip_os_common_logger \
	cargo_test_cantrip_os_common_slot_allocator

## Runs all cargo unit tests for the Cantrip operating system
cargo_test_cantrip: $(CARGO_TEST_CANTRIP)

## Runs cargo unit tests for the ProcessManager implementation
cargo_test_cantrip_proc_manager:
	cd $(CANTRIP_COMPONENTS)/ProcessManager/cantrip-proc-manager && $(CARGO_TEST)

## Runs cargo unit tests for the ProcessManager interface
cargo_test_cantrip_proc_interface:
	cd $(CANTRIP_COMPONENTS)/ProcessManager/cantrip-proc-interface && $(CARGO_TEST)

## Runs cargo unit tests for the CantripLogger service
cargo_test_cantrip_os_common_logger:
	cd $(CANTRIP_COMPONENTS)/cantrip-os-common/src/logger && \
		$(CARGO_TEST) -- --test-threads=1

## Runs cargo unit tests for the CantripSlotAllocator crate
cargo_test_cantrip_os_common_slot_allocator:
	cd $(CANTRIP_COMPONENTS)/cantrip-os-common/src/slot-allocator && \
		$(CARGO_TEST) -- --test-threads=1

## Runs cargo unit tests for the DebugConsole zmomdem support
cargo_test_debugconsole_zmodem:
	cd $(CANTRIP_COMPONENTS)/DebugConsole/zmodem && $(CARGO_TEST)

## Builds the flatbuffers tooling and libraries
cantrip-flatbuffers: $(OUT)/host/flatbuffers/bin/flatc $(ROOTDIR)/sw/cantrip/flatbuffers
	$(MAKE) -C $(ROOTDIR)/sw/cantrip/flatbuffers \
		FLATC=$(OUT)/host/flatbuffers/bin/flatc \
		SRC_DIR=$(ROOTDIR)/sw/cantrip/flatbuffers \
		TARGET_BASEDIR=$(ROOTDIR) \
		all

.PHONY:: cantrip cantrip-clean
.PHONY:: cantrip-bundle-debug cantrip-bundle-release
.PHONY:: cantrip-builtins-debug cantrip-builtins-release
.PHONY:: cantrip-gen-headers cantrip-clean-headers
.PHONY:: cantrip-flatbuffers
.PHONY:: cargo_test_cantrip $(CARGO_TEST_CANTRIP)
.PHONY:: cantrip-build-debug-prepare cantrip-build-release-prepare
.PHONY:: $(CANTRIP_OUT_DEBUG) $(CANTRIP_OUT_RELEASE)
