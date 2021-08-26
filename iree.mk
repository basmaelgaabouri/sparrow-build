IREE_SRC=$(ROOTDIR)/toolchain/iree
IREE_COMPILER_OUT=$(OUT)/host/iree_compiler
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
	pushd $(IREE_SRC) > /dev/null &&  git submodule update --init --jobs=8 --depth=10
  # Download IREE tflite tools with the recent release
	pip3 install iree-tools-tflite-snapshot -f https://github.com/google/iree/releases --upgrade

$(IREE_COMPILER_OUT)/build.ninja: | iree_check
	cmake -G Ninja -B $(IREE_COMPILER_OUT) \
	    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
	    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	    -DCMAKE_INSTALL_PREFIX=$(IREE_COMPILER_OUT)/install \
	    -DIREE_HAL_DRIVERS_TO_BUILD="Dylib;VMVX" \
	    -DIREE_TARGET_BACKENDS_TO_BUILD="DYLIB-LLVM-AOT;VMVX" \
	    -DIREE_BUILD_TESTS=OFF \
	    $(IREE_SRC)

iree_compiler: $(IREE_COMPILER_OUT)/build.ninja | iree_check
	cmake --build $(IREE_COMPILER_OUT) --target install

# TODO(b/194710215): Need to figure out why the second cmake config is needed to
# reduce the artifact size to <256KB.
$(IREE_RUNTIME_OUT)/build.ninja: | iree_check
	cmake -G Ninja -B $(IREE_RUNTIME_OUT) \
	    -DCMAKE_TOOLCHAIN_FILE="$(IREE_RUNTIME_ROOT)/cmake/riscv_iree.cmake" \
	    -DCMAKE_BUILD_TYPE=MinSizeRel \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_COMPILER_OUT)/install" \
	    -DRISCV_TOOLCHAIN_ROOT=$(TOOLCHAINRV32_PATH) \
	    -DRISCV_COMPILER_FLAGS="$(RV32_COMPILER_FLAGS)" \
	    -DCMAKE_EXE_LINKER_FLAGS="$(RV32_EXE_LINKER_FLAGS)" \
	    $(IREE_RUNTIME_ROOT)
	cmake -G Ninja -B $(IREE_RUNTIME_OUT) \
	    -DCMAKE_TOOLCHAIN_FILE="$(IREE_RUNTIME_ROOT)/cmake/riscv_iree.cmake" \
	    -DCMAKE_BUILD_TYPE=MinSizeRel \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_COMPILER_OUT)/install" \
	    -DRISCV_TOOLCHAIN_ROOT=$(TOOLCHAINRV32_PATH) \
	    -DRISCV_COMPILER_FLAGS="$(RV32_COMPILER_FLAGS)" \
	    -DCMAKE_EXE_LINKER_FLAGS="$(RV32_EXE_LINKER_FLAGS)" \
	    $(IREE_RUNTIME_ROOT)

iree_runtime: $(IREE_RUNTIME_OUT)/build.ninja | iree_check
	cmake --build $(IREE_RUNTIME_OUT)

iree: iree_compiler iree_runtime

iree_clean:
	rm -rf $(IREE_COMPILER_OUT) $(IREE_RUNTIME_OUT)

.PHONY:: iree iree_check iree_compiler iree_runtime iree_clean
