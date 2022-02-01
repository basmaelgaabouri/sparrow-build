# Matcha platform + kernel binaries
MATCHA_PLATFORM_SRC_DIR := $(ROOTDIR)/sw/matcha/platform/
MATCHA_PLATFORM_DEBUG   := $(OUT)/matcha/riscv32imc-unknown-none-elf/debug/matcha_platform
MATCHA_PLATFORM_RELEASE := $(OUT)/matcha/riscv32imc-unknown-none-elf/release/matcha_platform

# Matcha app binaries
MATCHA_APP_SRC_DIR := $(ROOTDIR)/sw/matcha/app/
MATCHA_APP_DEBUG   := $(OUT)/matcha/riscv32imc-unknown-none-elf/debug/matcha_app
MATCHA_APP_RELEASE := $(OUT)/matcha/riscv32imc-unknown-none-elf/release/matcha_app

# Bundled platform+kernel+app binaries
MATCHA_BUNDLE_DEBUG   := $(OUT)/matcha-bundle-debug.elf
MATCHA_BUNDLE_RELEASE := $(OUT)/matcha-bundle-release.elf

########################################

$(MATCHA_BUNDLE_DEBUG): matcha_toolchain
	cd $(MATCHA_PLATFORM_SRC_DIR); cargo build
	cd $(MATCHA_APP_SRC_DIR); PLATFORM=opentitan cargo build
	elf2tab -n matcha -o $(MATCHA_APP_DEBUG).tab $(MATCHA_APP_DEBUG) --stack 4096 --app-heap 1024 --kernel-heap 1024 --protected-region-size=64
	cp $(MATCHA_PLATFORM_DEBUG) $(MATCHA_BUNDLE_DEBUG)
	riscv32-unknown-elf-objcopy --update-section .apps=$(MATCHA_APP_DEBUG).tbf $(MATCHA_BUNDLE_DEBUG)

$(MATCHA_BUNDLE_RELEASE): matcha_toolchain
	cd $(MATCHA_PLATFORM_SRC_DIR); cargo build --release
	cd $(MATCHA_APP_SRC_DIR); PLATFORM=opentitan cargo build --release
	elf2tab -n matcha -o $(MATCHA_APP_RELEASE).tab $(MATCHA_APP_RELEASE) --stack 4096 --app-heap 1024 --kernel-heap 1024 --protected-region-size=64
	cp $(MATCHA_PLATFORM_RELEASE) $(MATCHA_BUNDLE_RELEASE)
	riscv32-unknown-elf-objcopy --update-section .apps=$(MATCHA_APP_RELEASE).tbf $(MATCHA_BUNDLE_RELEASE)

########################################

## Updates the Rust toolchain for matcha's app+platform
matcha_toolchain:
	./scripts/install-rust-toolchain.sh "$(RUSTDIR)" $(MATCHA_PLATFORM_SRC_DIR)/rust-toolchain riscv32imc-unknown-none-elf
	./scripts/install-rust-toolchain.sh "${RUSTDIR}" $(MATCHA_APP_SRC_DIR)/rust-toolchain riscv32imc-unknown-none-elf

## Builds TockOS for the security core in debug mode
matcha_tock_debug: $(MATCHA_BUNDLE_DEBUG)

## Builds TockOS for the security core in release mode
matcha_tock_release: $(MATCHA_BUNDLE_RELEASE)

## Removes the TockOS and libtockrs build artifacts from out/
matcha_tock_clean:
	cd $(MATCHA_PLATFORM_SRC_DIR); make TARGET_DIRECTORY=$(OUT)/tock clean
	cd $(MATCHA_APP_SRC_DIR); PLATFORM=opentitan cargo clean --target-dir=$(OUT)/matcha

.PHONY:: matcha_toolchain matcha_tock_debug matcha_tock_release matcha_tock_clean $(MATCHA_BUNDLE_DEBUG) $(MATCHA_BUNDLE_RELEASE)
