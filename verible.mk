VERIBLE_BUILD_DIR := $(OUT)/tmp/verible
VERIBLE_OUT_DIR   := $(OUT)/host/verible
VERIBLE_BIN       := $(VERIBLE_OUT_DIR)/bin/verible-verilog-format

$(VERIBLE_OUT_DIR):
	mkdir -p $(VERIBLE_OUT_DIR)

$(VERIBLE_BUILD_DIR):
	mkdir -p $(VERIBLE_BUILD_DIR)

$(VERIBLE_BIN): | $(VERIBLE_BUILD_DIR) $(VERIBLE_OUT_DIR)
	./scripts/install-verible.sh

## Removes verible directory and binaries from out/
verible_clean:
	rm -rf $(VERIBLE_BUILD_DIR) $(VERIBLE_OUT_DIR)

## Downloads and extracts pre-built verible binaries to out/host/verible/bin
verible: $(VERIBLE_BIN)

.PHONY:: verible verible_clean
