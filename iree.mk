IREE_SRC=$(ROOTDIR)/toolchain/iree
QEMU_PATH=$(OUT)/host/qemu/riscv32-softmmu
TOOLCHAINRV32_PATH=$(CACHE)/toolchain_iree_rv32imf
SPRINGBOK_ROOT=$(ROOTDIR)/sw/vec/springbok
IREE_RUNTIME_ROOT=$(ROOTDIR)/sw/vec_iree
IREE_RUNTIME_OUT=$(OUT)/springbok_iree

RV32_EXE_LINKER_FLAGS=-Wl,--print-memory-usage

RV32_COMPILER_FLAGS=-g3 \
    -ggdb

# The following targets are always rebuilt when the iree target is made

iree_check:
	if [[ ! -d "$(TOOLCHAINRV32_PATH)" ]]; then \
		echo "IREE toolchain $(TOOLCHAINRV32_PATH) doesn't exist, please run 'm install_llvm' first"; \
		exit 1; \
	fi
	@echo Update $(IREE_SRC) submodules...
	git -C $(IREE_SRC) submodule sync && \
	  git -C $(IREE_SRC) submodule update --init --jobs=8 --depth=10

$(IREE_COMPILER_DIR)/build.ninja: | iree_check
	cmake -G Ninja -B $(IREE_COMPILER_DIR) \
	    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
	    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	    -DCMAKE_INSTALL_PREFIX=$(IREE_COMPILER_DIR)/install \
	    -DIREE_HAL_DRIVERS_TO_BUILD="Dylib;VMVX" \
	    -DIREE_TARGET_BACKENDS_TO_BUILD="DYLIB-LLVM-AOT;VMVX" \
	    -DIREE_BUILD_TESTS=OFF \
	    $(IREE_SRC)

## Builds the IREE compiler from source and records the HEAD commit ID
iree_compiler_src: $(IREE_COMPILER_DIR)/build.ninja | iree_check
	cmake --build $(IREE_COMPILER_DIR) --target install
	git -C "$(IREE_SRC)" rev-parse HEAD > $(IREE_COMPILER_DIR)/tag

$(IREE_COMPILER_DIR):
	mkdir -p $(IREE_COMPILER_DIR)

## Downloads the latest release of the IREE compiler and tflite tools.
#
# The release tag and commit are recorded for consistency checks in
# the `iree_runtime` target. The outputs of this target are placed in
# out/host/iree_compiler.
#
iree_compiler: | $(IREE_COMPILER_DIR)
# TODO(b/221857706) Temporarily pin to the earlier release 59
	scripts/download_iree_compiler.py --tag candidate-20220225.59
iree_commit_check:
	scripts/check-iree-commit.sh $(IREE_SRC)

$(IREE_RUNTIME_OUT)/build.ninja: | iree_check iree_commit_check
	cmake -G Ninja -B $(IREE_RUNTIME_OUT) \
	    -DCMAKE_TOOLCHAIN_FILE="$(IREE_RUNTIME_ROOT)/cmake/riscv_iree.cmake" \
	    -DCMAKE_BUILD_TYPE=MinSizeRel \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_COMPILER_DIR)/install" \
	    -DRISCV_TOOLCHAIN_ROOT=$(TOOLCHAINRV32_PATH) \
	    -DRISCV_COMPILER_FLAGS="$(RV32_COMPILER_FLAGS)" \
	    -DCMAKE_EXE_LINKER_FLAGS="$(RV32_EXE_LINKER_FLAGS)" \
	    $(IREE_RUNTIME_ROOT)

## Installs the IREE runtime applications.
#
# Unlike the `iree_compiler` target, this target actually builds the runtime
# from source in toolchain/iree. The results of the build are placed in
# out/springbok_iree.
#
# In general, you probably want the `iree` target instead, which combines
# `iree_compiler` and `iree_runtime`.
iree_runtime: $(IREE_RUNTIME_OUT)/build.ninja | iree_check iree_commit_check
	cmake --build $(IREE_RUNTIME_OUT)

## Installs the IREE compiler and its runtime applications.
iree: iree_compiler iree_runtime

iree_clean:
	rm -rf $(IREE_COMPILER_DIR) $(IREE_RUNTIME_OUT)

.PHONY:: iree iree_check iree_compiler iree_runtime iree_clean iree_commit_check iree_compiler_src
