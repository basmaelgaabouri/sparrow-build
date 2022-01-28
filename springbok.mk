SPRINGBOK_BUILD_DIR=$(OUT)/springbok/
SPRINGBOK_SRC_DIR=$(ROOTDIR)/sw/vec

$(SPRINGBOK_BUILD_DIR)/build.ninja:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)

## Vector core BSP and RVV test code
#
# This target builds the springbok BSP as well as the associated vector test
# code. Source code is in sw/vec, while output is placed in out/springbok.
springbok: $(SPRINGBOK_BUILD_DIR)/build.ninja
	cmake --build $(SPRINGBOK_BUILD_DIR)

test_springbok: springbok
	cd $(SPRINGBOK_BUILD_DIR) && ctest -j 16

clean_springbok:
	@rm -rf $(SPRINGBOK_BUILD_DIR)

.PHONY:: springbok clean_springbok test_springbok
