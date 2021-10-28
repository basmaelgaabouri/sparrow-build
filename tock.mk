# Source directories
DIR_KERNEL_SRC=$(ROOTDIR)/sw/matcha/board/
DIR_MATCHA_SRC=$(ROOTDIR)/sw/matcha/app/

# Kernel binaries
TOCK_KERNEL_DEBUG   = $(OUT)/tock/riscv32imc-unknown-none-elf/debug/opentitan-matcha.elf
TOCK_KERNEL_RELEASE = $(OUT)/tock/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf

# Matcha app binaries
MATCHA_APP_DEBUG   = $(OUT)/matcha/riscv32imc-unknown-none-elf/debug/matcha
MATCHA_APP_RELEASE = $(OUT)/matcha/riscv32imc-unknown-none-elf/release/matcha

# Bundled kernel+app binaries
MATCHA_TOCK_BUNDLE_DEBUG   = $(OUT)/matcha-tock-bundle-debug.elf
MATCHA_TOCK_BUNDLE_RELEASE = $(OUT)/matcha-tock-bundle-release.elf

########################################

$(MATCHA_TOCK_BUNDLE_DEBUG):
	cd $(DIR_KERNEL_SRC); make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(OUT)/tock/ debug
	cd $(DIR_MATCHA_SRC); PLATFORM=opentitan cargo build
	elf2tab -n matcha -o $(MATCHA_APP_DEBUG).tab $(MATCHA_APP_DEBUG) --stack 4096 --app-heap 1024 --kernel-heap 1024 --protected-region-size=64
	cp $(TOCK_KERNEL_DEBUG) $(MATCHA_TOCK_BUNDLE_DEBUG)
	riscv32-unknown-elf-objcopy --update-section .apps=$(MATCHA_APP_DEBUG).tbf $(MATCHA_TOCK_BUNDLE_DEBUG)

$(MATCHA_TOCK_BUNDLE_RELEASE):
	cd $(DIR_KERNEL_SRC); make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(OUT)/tock/ release
	cd $(DIR_MATCHA_SRC); PLATFORM=opentitan cargo build --release
	elf2tab -n matcha -o $(MATCHA_APP_RELEASE).tab $(MATCHA_APP_RELEASE) --stack 4096 --app-heap 1024 --kernel-heap 1024 --protected-region-size=64
	cp $(TOCK_KERNEL_RELEASE) $(MATCHA_TOCK_BUNDLE_RELEASE)
	riscv32-unknown-elf-objcopy --update-section .apps=$(MATCHA_APP_RELEASE).tbf $(MATCHA_TOCK_BUNDLE_RELEASE)

########################################

## Builds TockOS for the security core in debug mode
#
# Sparrow-specific source is in sw/tock/boards/opentitan-matcha.
matcha_tock_debug: $(MATCHA_TOCK_BUNDLE_DEBUG)

## Builds TockOS for the security core in release mode
#
# Sparrow-specific source is in sw/tock/boards/opentitan-matcha.
matcha_tock_release: $(MATCHA_TOCK_BUNDLE_RELEASE)

## Removes the TockOS and libtockrs build artifacts from out/
matcha_tock_clean:
	cd $(DIR_KERNEL_SRC); make TARGET_DIRECTORY=$(OUT)/tock clean
	cd $(DIR_MATCHA_SRC); PLATFORM=opentitan cargo clean --target-dir=$(OUT)/matcha

.PHONY:: matcha_tock_debug matcha_tock_release matcha_tock_clean $(MATCHA_TOCK_BUNDLE_DEBUG) $(MATCHA_TOCK_BUNDLE_RELEASE)
