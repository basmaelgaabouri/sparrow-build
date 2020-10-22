KATA_INIT_ARGS := -DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- \
                  -DCMAKE_BUILD_TYPE=Release \
                  -DPLATFORM=spike \
                  -DRISCV32=1

KATA_TOPLEVEL_NINJA_SCRIPT := $(OUT)/kata/build.ninja
KATA_ROOTSERVER_IMAGE_NAME := $(OUT)/kata/images/ProcessManager-image-riscv-spike
KATA_SIMULATE_SCRIPT_NAME  := $(OUT)/kata/simulate

KATA_SOURCES := $(shell find $(ROOTDIR)/kata -name \*.c -name \*.h -name \*.cpp -type f)

$(KATA_TOPLEVEL_NINJA_SCRIPT): $(KATA_SOURCES) | $(OUT)/kata
	pushd $(OUT)/kata; $(ROOTDIR)/kata/init-build.sh $(KATA_INIT_ARGS)

$(KATA_ROOTSERVER_IMAGE_NAME): $(KATA_TOPLEVEL_NINJA_SCRIPT) $(KATA_SOURCES) | $(OUT)/kata
	pushd $(OUT)/kata; ninja

$(KATA_SIMULATE_SCRIPT_NAME): $(KATA_ROOTSERVER_IMAGE_NAME)

$(OUT):
	@mkdir -p $(OUT)

$(OUT)/kata:
	@mkdir -p $(OUT)/kata

simulate-kata: $(KATA_SIMULATE_SCRIPT_NAME)
	@echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	@echo Press Control-A H to get qemu console help!
	@echo Press Control-A X to quit qemu!
	@echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	@echo
	pushd $(OUT)/kata; ./simulate

kata: $(KATA_ROOTSERVER_IMAGE_NAME)
.PHONY:: kata
