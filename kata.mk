KATA_INIT_ARGS := -DCROSS_COMPILER_PREFIX=riscv32-unknown-elf-

KATA_TOPLEVEL_NINJA_SCRIPT := $(OUT)/kata/build.ninja
KATA_ROOTSERVER_IMAGE_NAME := $(OUT)/kata/images/capdl-loader-image-riscv-spike
KATA_SIMULATE_SCRIPT_NAME  := $(OUT)/kata/simulate

KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
						-name \*.rs -or \
						-name \*.c -or \
						-name \*.h -or \
						-name \*.cpp \
						-type f)

$(KATA_TOPLEVEL_NINJA_SCRIPT): $(KATA_SOURCES) | $(OUT)/kata
	pushd $(OUT)/kata; cmake -G Ninja $(KATA_INIT_ARGS) $(ROOTDIR)/kata/projects/processmanager

$(KATA_ROOTSERVER_IMAGE_NAME): $(KATA_TOPLEVEL_NINJA_SCRIPT) $(KATA_SOURCES) | $(OUT)/kata
	pushd $(OUT)/kata; ninja

$(KATA_SIMULATE_SCRIPT_NAME): $(KATA_ROOTSERVER_IMAGE_NAME)

$(OUT)/kata:
	@mkdir -p $(OUT)/kata

simulate-kata: $(KATA_SIMULATE_SCRIPT_NAME)
	@echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	@echo Press Control-A H to get qemu console help!
	@echo Press Control-A X to quit qemu!
	@echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	@echo
	pushd $(OUT)/kata; ./simulate '--extra-qemu-args=-bios none'

kata: $(KATA_ROOTSERVER_IMAGE_NAME)
.PHONY:: kata
