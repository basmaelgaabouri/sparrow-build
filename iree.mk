IREE_SRC=$(ROOTDIR)/toolchain/iree
IREE_HOST_OUT=$(OUT)/host/iree-build-host
IREE_RISCV32_OUT=$(OUT)/host/iree-build-riscv32
QEMU_PATH=$(OUT)/host/qemu/riscv32-softmmu
TOOLCHAINRV32_PATH=$(CACHE)/toolchain_iree_rv32imf
SPRINGBOK_ROOT=$(ROOTDIR)/sw/vec/springbok

RV32_EXE_LINKER_FLAGS=-Xlinker --defsym=__itcm_length__=256K \
    -Wl,--whole-archive \
    $(OUT)/springbok_iree/springbok/libspringbok_intrinsic.a \
    -Wl,--no-whole-archive \
    -T $(SPRINGBOK_ROOT)/matcha.ld \
    -nostartfiles \
    -Wl,--print-memory-usage


# The following targets are always rebuilt when the iree target is made

iree_check:
	if [[ ! -d "$(TOOLCHAINRV32_PATH)" ]]; then \
		echo "IREE toolchain $(TOOLCHAINRV32_PATH) doesn't exist, please run 'm install_llvm' first"; \
		exit 1; \
	fi
	if [ ! -d "${QEMU_PATH}" ]; then \
		echo "QEMU path $(QEMU_PATH) doesn't exist, please run 'm qemu' first"; \
		exit 1; \
	fi
	@echo Update $(IREE_SRC) submodules...
	pushd $(IREE_SRC) &&	git submodule update --init --jobs=8 --depth=10

iree_host_build: | iree_check
	cmake -G Ninja -B $(IREE_HOST_OUT) -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
	    -DCMAKE_INSTALL_PREFIX=$(IREE_HOST_OUT)/install \
	    $(IREE_SRC)
	cmake --build $(IREE_HOST_OUT) --target install

iree_rv32_build: | springbok_iree
	cmake -G Ninja -B $(IREE_RISCV32_OUT) \
	    -DCMAKE_TOOLCHAIN_FILE="$(ROOTDIR)/build/riscv_iree.cmake" \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_HOST_OUT)/install" \
	    -DRISCV_CPU=rv32-baremetal -DIREE_BUILD_COMPILER=OFF \
	    -DIREE_ENABLE_MLIR=OFF -DIREE_BUILD_SAMPLES=ON \
	    -DIREE_BUILD_TESTS=OFF \
	    -DRISCV_TOOLCHAIN_ROOT=$(TOOLCHAINRV32_PATH) \
	    -DCMAKE_EXE_LINKER_FLAGS="$(RV32_EXE_LINKER_FLAGS)" \
	    $(IREE_SRC)
# TODO: Build everything, not just target. Hits 256k limitation on some examples.
	cmake --build $(IREE_RISCV32_OUT) --target iree/hal/local/elf/elf_module_test_binary

iree: iree_host_build iree_rv32_build

iree_clean:
	rm -rf $(IREE_HOST_OUT) $(IREE_RISCV32_OUT)

.PHONY:: iree iree_check iree_host_build iree_rv32_build iree_clean
