SPRINGBOK_BUILD_DIR := $(OUT)/springbok/rvv
SPRINGBOK_SRC_DIR   := $(ROOTDIR)/sw/vec
SPRINGBOK_BUILD_SCALAR_DIR := $(OUT)/springbok/scalar

$(SPRINGBOK_BUILD_DIR)/build.ninja:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)

# Set up BUILD_SIMPLIFIELD_CORE CMake option to remove usages of unimplemented
# ISA extentions, such as f-ext.
$(SPRINGBOK_BUILD_SCALAR_DIR)/build.ninja:
	cmake -B $(SPRINGBOK_BUILD_SCALAR_DIR) -GNinja \
		-DBUILD_SIMPLIFIED_CORE=ON \
		$(SPRINGBOK_SRC_DIR)

## Vector core BSP and RVV test code
#
# This target builds the springbok BSP as well as the associated vector test
# code. Source code is in sw/vec, while output is placed in out/springbok/rvv.
springbok: $(SPRINGBOK_BUILD_DIR)/build.ninja
	cmake --build $(SPRINGBOK_BUILD_DIR)

test_springbok: springbok
	cd $(SPRINGBOK_BUILD_DIR) && ctest -j 16

## Springbok test code with simplified configuration
#
# This target builds the springbok SW artifacts with scalar-only configuration.
# Source code is in sw/vec, while the output is placed in out/springbok/scalar.
springbok_simplified: $(SPRINGBOK_BUILD_SCALAR_DIR)/build.ninja
	cmake --build $(SPRINGBOK_BUILD_SCALAR_DIR)

springbok_clean:
	rm -rf $(SPRINGBOK_BUILD_DIR)

springbok_simplified_clean:
	rm -rf $(SPRINGBOK_BUILD_SCALAR_DIR)

.PHONY:: springbok springbok_clean test_springbok springbok_simplified springbok_simplified_clean
