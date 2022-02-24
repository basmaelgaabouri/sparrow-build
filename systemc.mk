SYSTEMC_SRC_DIR     := $(ROOTDIR)/sim/systemc
SYSTEMC_BUILD_DIR   := $(OUT)/systemc
SYSTEMC_INSTALL_DIR := $(OUT)/host/systemc

$(SYSTEMC_BUILD_DIR):
	mkdir -p $(SYSTEMC_BUILD_DIR)

## Builds the System C Libraries
#
# Using sources in sim/systemc, this target builds systemc from source and stores
# its output in out/host/systemc.
#
# To rebuild this target, run `m systemc_clean` and re-run.
#
systemc: | $(SYSTEMC_BUILD_DIR)
	cmake -B $(SYSTEMC_BUILD_DIR) \
		-DCMAKE_INSTALL_PREFIX=$(SYSTEMC_INSTALL_DIR) \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=False \
		-DCMAKE_CXX_STANDARD=17 \
		-G Ninja \
		$(SYSTEMC_SRC_DIR)
	cmake --build $(SYSTEMC_BUILD_DIR) --target install

## Removes systemc build artifacts and install from out/
systemc_clean:
	@rm -rf $(SYSTEMC_BUILD_DIR)
	@rm -rf $(SYSTEMC_INSTALL_DIR)

clean:: systemc_clean

.PHONY:: systemc systemc_clean
