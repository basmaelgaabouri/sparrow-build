# Build riscv-tests artifacts for SMC and Springbok cores

RISCV_TEST_SPRINGBOK_SRC_DIR   := $(ROOTDIR)/sw/riscv-tests/springbok
RISCV_TEST_SPRINGBOK_BUILD_DIR := $(OUT)/tmp/riscv-tests-springbok
RISCV_TEST_SPRINGBOK_OUT_DIR   := $(OUT)/springbok/riscv-tests

$(RISCV_TEST_SPRINGBOK_OUT_DIR):
	mkdir -p $(RISCV_TEST_SPRINGBOK_OUT_DIR)

$(RISCV_TEST_SPRINGBOK_BUILD_DIR):
	mkdir -p $(RISCV_TEST_SPRINGBOK_BUILD_DIR)

## Build riscv-tests artifact for Springbok core
# This target builds the binaries from sw/riscv-tests/springbok and stores
# them at out/springbok/riscv-tests
# To run the artifact, please build spike with `m spike` and out/host/spike/bin/spike <elf>
#
springbok_riscv_tests: install_llvm | $(RISCV_TEST_SPRINGBOK_BUILD_DIR) $(RISCV_TEST_SPRINGBOK_OUT_DIR)
	cd $(RISCV_TEST_SPRINGBOK_BUILD_DIR) && \
		$(RISCV_TEST_SPRINGBOK_SRC_DIR)/configure \
			--with-xlen=32 --srcdir=$(RISCV_TEST_SPRINGBOK_SRC_DIR) \
			--target="${CACHE}/toolchain_iree_rv32imf/bin/riscv32-unknown-elf" \
			--prefix=$(RISCV_TEST_SPRINGBOK_OUT_DIR)
	$(MAKE) -C $(RISCV_TEST_SPRINGBOK_BUILD_DIR) install
	@echo "To run, please run \`m spike\` and then out/host/spike/bin/spike <elf>"

## Clean the Springbok riscv-test artifacts
springbok_riscv_tests_clean:
	rm -rf $(RISCV_TEST_SPRINGBOK_OUT_DIR) $(RISCV_TEST_SPRINGBOK_BUILD_DIR)

.PHONY:: springbok_riscv_tests
