# Builds Kata, the seL4-based operating system that runs on the SMC.
# The source is in $(KATA_SRC_DIR), while the outputs are placed in
# $(KATA_KERNEL_DEBUG) & $(KATA_ROOTSERVER_DEBUG) or
# $(KATA_KERNEL_RELEASE) & $(KATA_ROOTSERVER_RELEASE).

# NB: see $(KATA_SRC_DIR)/easy-settings.cmake for config knobs;
#     but beware you may need to "clean" before building with changes

KATA_SRC_DIR      := $(ROOTDIR)/kata/projects/processmanager
KATA_COMPONENTS   := $(KATA_SRC_DIR)/apps/system/components
CARGO_TEST        := cargo +$(KATA_RUST_VERSION) test

# NB: $(KATA_SRC_DIR)/apps/system/rust.cmake forces riscv32imac for
#     the target when building Rust code
KATA_TARGET_ARCH  := riscv32-unknown-elf

# Location of seL4 kernel source (for sel4-sys)
SEL4_KERNEL_DIR  := $(ROOTDIR)/kata/kernel

KATA_OUT_DIR     := $(OUT)/kata/$(KATA_TARGET_ARCH)
KATA_OUT_DEBUG   := $(KATA_OUT_DIR)/debug
KATA_OUT_RELEASE := $(KATA_OUT_DIR)/release

# seL4 kernel included in the ext flash tarball
KATA_KERNEL_DEBUG   := $(KATA_OUT_DEBUG)/kernel/kernel.elf
KATA_KERNEL_RELEASE := $(KATA_OUT_RELEASE)/kernel/kernel.elf

# Rootserver image that has the CAmkES components embedded in
# the ELF image in a ._archive_cpio section.
KATA_ROOTSERVER_DEBUG := $(KATA_OUT_DEBUG)/capdl-loader
KATA_ROOTSERVER_RELEASE := $(KATA_OUT_RELEASE)/capdl-loader

KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
	-name \*.rs -or \
	-name \*.c -or \
	-name \*.h -or \
	-name \*.cpp \
	-type f)

# Driver include files auto-generated from opentitan definitions.

OPENTITAN_SOURCE=$(ROOTDIR)/hw/opentitan-upstream
REGTOOL=$(OPENTITAN_SOURCE)/util/regtool.py

OPENTITAN_GEN_DIR=$(KATA_OUT_DIR)/opentitan-gen/include/opentitan
$(OPENTITAN_GEN_DIR):
	mkdir -p $(OPENTITAN_GEN_DIR)

TIMER_IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/rv_timer
TIMER_JINJA=$(TIMER_IP_DIR)/util/reg_timer.py
TIMER_TEMPLATE=$(TIMER_IP_DIR)/data/rv_timer.hjson.tpl

TIMER_HEADER=$(OPENTITAN_GEN_DIR)/timer.h
TIMER_HJSON=$(OPENTITAN_GEN_DIR)/rv_timer.hjson

$(TIMER_HJSON): $(TIMER_JINJA) $(TIMER_TEMPLATE) | $(OPENTITAN_GEN_DIR)
	$(TIMER_JINJA) -s 2 -t 1 $(TIMER_TEMPLATE) > $(TIMER_HJSON)
$(TIMER_HEADER): $(REGTOOL) $(TIMER_HJSON)
	$(REGTOOL) -D -o $@ $(TIMER_HJSON)

UART_IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/uart

UART_HEADER=$(OPENTITAN_GEN_DIR)/uart.h
UART_HJSON=$(UART_IP_DIR)/data/uart.hjson

$(UART_HEADER): $(REGTOOL) $(UART_HJSON) | $(OPENTITAN_GEN)
	$(REGTOOL) -D -o $@ $(UART_HJSON)

## Builds auto-generated include files for the Kata operating system
kata-gen-headers: $(TIMER_HEADER) $(UART_HEADER)

## Cleans the auto-generated Kata include files
kata-clean-headers:
	rm -f $(TIMER_HJSON)
	rm -f $(TIMER_HEADER)
	rm -f $(UART_HEADER)

## Cleans all Kata operating system build artifacts
kata-clean:
	rm -rf $(OUT)/kata

# Build Kata bundles. A bundle is an seL4 kernel elf plus the user space
# bits: rootserver + CAmkES components (embedded in the rootserver elf).
# Crates that depend on the kernel check the SEL4_OUT_DIR environment
# variable for the location of the files generated for the kernel.
# We also pass SEL4_DIR in the environment; though the default logic
# in crates that use sel4-config can calculate this if SEL4_DIR is
# not defined.
#
# NB: files generated by kata-gen-headers are shared so we craft
#     a symlink in the target-specific build directories

$(KATA_KERNEL_DEBUG): $(KATA_SOURCES) kata-gen-headers
	mkdir -p $(KATA_OUT_DEBUG)
	ln -sf $(KATA_OUT_DIR)/opentitan-gen $(KATA_OUT_DEBUG)/
	cmake -B $(KATA_OUT_DEBUG) -G Ninja \
		-DCROSS_COMPILER_PREFIX=$(KATA_TARGET_ARCH)- \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4-debug \
		-DRELEASE=OFF \
	  $(KATA_SRC_DIR)
	SEL4_DIR=$(SEL4_KERNEL_DIR) \
	SEL4_OUT_DIR=$(KATA_OUT_DEBUG)/kernel \
		ninja -C $(KATA_OUT_DEBUG)

## Generates Kata operating build artifacts with debugging suport
kata-bundle-debug: $(KATA_KERNEL_DEBUG)

$(KATA_KERNEL_RELEASE): $(KATA_SOURCES) kata-gen-headers
	mkdir -p $(KATA_OUT_RELEASE)
	ln -sf $(KATA_OUT_DIR)/opentitan-gen $(KATA_OUT_RELEASE)/
	cmake -B $(KATA_OUT_RELEASE) -G Ninja \
		-DCROSS_COMPILER_PREFIX=$(KATA_TARGET_ARCH)- \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4-release \
		-DRELEASE=ON \
		 $(KATA_SRC_DIR)
	SEL4_DIR=$(SEL4_KERNEL_DIR) \
	SEL4_OUT_DIR=$(KATA_OUT_RELEASE)/kernel \
		ninja -C $(KATA_OUT_RELEASE)

## Generates Kata operating build artifacts setup for release
kata-bundle-release: $(KATA_KERNEL_RELEASE)

## Generates both debug & release Kata operating system build artifacts
# NB: shorthand for testing (sim targets depend on explicit pathnames)
kata: kata-bundle-debug kata-bundle-release

# NB: cargo_test_debugconsole_zmodem is broken
NULL=
CARGO_TEST_KATA=\
	cargo_test_kata_proc_manager \
	cargo_test_kata_proc_interface \
	cargo_test_debugconsole_kata_logger \
	$(NULL)

## Runs all cargo unit tests for the Kata operating system
cargo_test_kata: $(CARGO_TEST_KATA)

## Runs cargo unit tests for the ProcessManager implementation
cargo_test_kata_proc_manager:
	cd $(KATA_COMPONENTS)/ProcessManager/kata-proc-manager && $(CARGO_TEST)

## Runs cargo unit tests for the ProcessManager interface
cargo_test_kata_proc_interface:
	cd $(KATA_COMPONENTS)/ProcessManager/kata-proc-interface && $(CARGO_TEST)

## Runs cargo unit tests for the KataLogger service
cargo_test_debugconsole_kata_logger:
	cd $(KATA_COMPONENTS)/DebugConsole/kata-logger && \
		$(CARGO_TEST) -- --test-threads=1

## Runs cargo unit tests for the DebugConsole zmomdem support
cargo_test_debugconsole_zmodem:
	cd $(KATA_COMPONENTS)/DebugConsole/zmodem && $(CARGO_TEST)

.PHONY:: kata kata-clean
.PHONY:: kata-bundle-debug kata-bundle-release
.PHONY:: kata-gen-headers kata-clean-headers
.PHONY:: cargo_test_kata $(CARGO_TEST_KATA)
