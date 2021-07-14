IREE_TOOLCHAIN=$(CACHE)/toolchain_iree
IREE_SRC=$(ROOTDIR)/toolchain/iree
IREE_HOST_OUT=$(OUT)/host/iree-build-host
IREE_RISCV_OUT=$(OUT)/host/iree-build-riscv64
IREE_RISCV32_OUT=$(OUT)/host/iree-build-riscv32
QEMU_PATH=${OUT}/host/qemu/riscv64-linux-user
TOOLCHAINRV32_PATH=$(CACHE)/toolchain_iree_rv32imf
LINKER_SCRIPT=$(ROOTDIR)/sw/vec/springbok/matcha.ld
CRT0=$(ROOTDIR)/sw/vec/springbok/crt0.s

# The following targets are always rebuilt when the iree target is made

iree_check:
	if [[ ! -d "$(IREE_TOOLCHAIN)" ]]; then \
		echo "IREE toolchain $(IREE_TOOLCHAIN) doesn't exist, please run 'm install_llvm' first"; \
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

iree_riscv_build: | iree_check
	cmake -G Ninja -B $(IREE_RISCV_OUT) \
	    -DCMAKE_TOOLCHAIN_FILE="$(ROOTDIR)/build/riscv_iree.cmake" \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_HOST_OUT)/install" \
	    -DRISCV_CPU=rv64 -DIREE_BUILD_COMPILER=OFF \
	    -DIREE_ENABLE_MLIR=OFF -DIREE_BUILD_SAMPLES=OFF \
	    -DRISCV_TOOLCHAIN_ROOT=$(IREE_TOOLCHAIN) \
	    $(IREE_SRC)
	cmake --build $(IREE_RISCV_OUT)

iree_rv32_build:
	cmake -G Ninja -B $(IREE_RISCV32_OUT) \
	    -DCMAKE_TOOLCHAIN_FILE="$(ROOTDIR)/build/riscv_iree.cmake" \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_HOST_OUT)/install" \
	    -DRISCV_CPU=rv32-baremetal -DIREE_BUILD_COMPILER=OFF \
	    -DIREE_ENABLE_MLIR=OFF -DIREE_BUILD_SAMPLES=ON \
	    -DIREE_BUILD_TESTS=OFF \
	    -DRISCV_TOOLCHAIN_ROOT=$(TOOLCHAINRV32_PATH) \
	    -DSPRINGBOK_ROOT=$(ROOTDIR)/sw/vec/springbok \
	    $(IREE_SRC)
# TODO: Build everything, not just target. Hits 256k limitation on some examples.
	cmake --build $(IREE_RISCV32_OUT) --target iree/hal/local/elf/elf_module_test_binary

iree_test:
	bash ${ROOTDIR}/scripts/run-iree.sh

iree: iree_host_build iree_riscv_build iree_test

iree_clean:
	rm -rf $(IREE_HOST_OUT) $(IREE_RISCV_OUT) $(IREE_RISCV32_OUT)

.PHONY:: iree iree_check iree_host_build iree_riscv_build iree_test iree_clean
