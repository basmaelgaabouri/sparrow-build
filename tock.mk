# Source directories
DIR_TOCK_SRC=$(ROOTDIR)/sw/tock/boards/opentitan-matcha/
DIR_LIBTOCK_SRC=$(ROOTDIR)/sw/libtock-rs/

# Kernel build directories
DIR_TOCK_OUT_DEBUG = $(OUT)/tock-debug/
DIR_TOCK_OUT_RELEASE = $(OUT)/tock-release/

# TockOS app build directories
DIR_LIBTOCK_OUT_DEBUG = $(OUT)/libtock-rs-debug/
DIR_LIBTOCK_OUT_RELEASE = $(OUT)/libtock-rs-release/

# Kernel binaries
MATCHA_TOCK_APP_DEBUG = $(DIR_LIBTOCK_OUT_DEBUG)/riscv32imc-unknown-none-elf/tab/opentitan/hello_world/rv32imc.tbf
MATCHA_TOCK_APP_RELEASE = $(DIR_LIBTOCK_OUT_RELEASE)/riscv32imc-unknown-none-elf/tab/opentitan/hello_world/rv32imc.tbf

# TockOS app binaries
MATCHA_TOCK_KERNEL_DEBUG = $(DIR_TOCK_OUT_DEBUG)/riscv32imc-unknown-none-elf/debug/opentitan-matcha.elf
MATCHA_TOCK_KERNEL_RELEASE = $(DIR_TOCK_OUT_RELEASE)/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf

# Bundled kernel+app binaries
MATCHA_TOCK_BUNDLE_DEBUG = $(OUT)/matcha-tock-bundle-debug.elf
MATCHA_TOCK_BUNDLE_RELEASE = $(OUT)/matcha-tock-bundle-release.elf

########################################

$(MATCHA_TOCK_KERNEL_DEBUG):
	cd $(DIR_TOCK_SRC); make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(DIR_TOCK_OUT_DEBUG) debug

$(MATCHA_TOCK_KERNEL_RELEASE):
	cd $(DIR_TOCK_SRC); make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(DIR_TOCK_OUT_RELEASE) release

$(MATCHA_TOCK_APP_DEBUG):
	cd $(DIR_LIBTOCK_SRC); PLATFORM=opentitan cargo run --target=riscv32imc-unknown-none-elf --example=hello_world --target-dir=$(DIR_LIBTOCK_OUT_DEBUG)

$(MATCHA_TOCK_APP_RELEASE):
	cd $(DIR_LIBTOCK_SRC); PLATFORM=opentitan cargo run --target=riscv32imc-unknown-none-elf --example=hello_world --target-dir=$(DIR_LIBTOCK_OUT_RELEASE) --release

$(MATCHA_TOCK_BUNDLE_DEBUG): $(MATCHA_TOCK_KERNEL_DEBUG) $(MATCHA_TOCK_APP_DEBUG)
	cp $(MATCHA_TOCK_KERNEL_DEBUG) $(MATCHA_TOCK_BUNDLE_DEBUG)
	riscv32-unknown-elf-objcopy --update-section .apps=$(MATCHA_TOCK_APP_DEBUG) $(MATCHA_TOCK_BUNDLE_DEBUG)

$(MATCHA_TOCK_BUNDLE_RELEASE): $(MATCHA_TOCK_KERNEL_RELEASE) $(MATCHA_TOCK_APP_RELEASE)
	cp $(MATCHA_TOCK_KERNEL_RELEASE) $(MATCHA_TOCK_BUNDLE_RELEASE)
	riscv32-unknown-elf-objcopy --update-section .apps=$(MATCHA_TOCK_APP_RELEASE) $(MATCHA_TOCK_BUNDLE_RELEASE)

########################################

matcha_tock_debug: $(MATCHA_TOCK_BUNDLE_DEBUG)
matcha_tock_release: $(MATCHA_TOCK_BUNDLE_RELEASE)

matcha_tock_clean:
	cd $(DIR_TOCK_SRC); make TARGET_DIRECTORY=$(DIR_TOCK_OUT_DEBUG) clean
	cd $(DIR_TOCK_SRC); make TARGET_DIRECTORY=$(DIR_TOCK_OUT_RELEASE) clean
	cd $(DIR_LIBTOCK_SRC); PLATFORM=opentitan cargo clean --target-dir=$(DIR_LIBTOCK_OUT_DEBUG)
	cd $(DIR_LIBTOCK_SRC); PLATFORM=opentitan cargo clean --target-dir=$(DIR_LIBTOCK_OUT_RELEASE)

.PHONY:: matcha_tock_debug matcha_tock_release matcha_tock_clean $(MATCHA_TOCK_KERNEL_DEBUG) $(MATCHA_TOCK_KERNEL_RELEASE) $(MATCHA_TOCK_APP_DEBUG) $(MATCHA_TOCK_APP_RELEASE)