IREE_TOOLCHAIN=$(CACHE)/toolchain_iree
IREE_SRC=$(ROOTDIR)/toolchain/iree
IREE_HOST_OUT=$(OUT)/host/iree-build-host
IREE_RISCV_OUT=$(OUT)/host/iree-build-riscv
QEMU_PATH=${OUT}/host/qemu/riscv64-linux-user

# The following targets are always rebuilt when the iree target is made

iree_check:
	if [ ! -d "${IREE_TOOLCHAIN}" ]; then \
		echo "IREE toolchain $(IREE_TOOLCHAIN) doesn't exist, please run 'm toolchain_llvm' first"; \
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
	    -DCMAKE_TOOLCHAIN_FILE="$(IREE_SRC)/build_tools/cmake/riscv.toolchain.cmake" \
	    -DIREE_HOST_BINARY_ROOT="$(IREE_HOST_OUT)/install" \
	    -DRISCV_CPU=rv64 -DIREE_BUILD_COMPILER=OFF \
	    -DIREE_ENABLE_MLIR=OFF -DIREE_BUILD_SAMPLES=OFF \
	    -DRISCV_TOOLCHAIN_ROOT=$(IREE_TOOLCHAIN) \
	    $(IREE_SRC)
	cmake --build $(IREE_RISCV_OUT)

iree_test:
	bash ${ROOTDIR}/scripts/run-iree.sh

iree: iree_host_build iree_riscv_build iree_test

iree_clean:
	rm -rf $(IREE_HOST_OUT) $(IREE_RISCV_OUT)

.PHONY:: iree iree_check iree_host_build iree_riscv_build iree_test iree_clean
