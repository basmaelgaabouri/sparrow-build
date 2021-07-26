SPRINGBOK_BUILD_DIR=$(OUT)/springbok/
SPRINGBOK_SRC_DIR=$(ROOTDIR)/sw/vec

springbok_config:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)

springbok: springbok_config
	cmake --build $(SPRINGBOK_BUILD_DIR)

springbok_iree: springbok_config
	cmake --build $(SPRINGBOK_BUILD_DIR) --target springbok_intrinsic

test_springbok: springbok_config
	cmake --build $(SPRINGBOK_BUILD_DIR) --target AllTests

clean_springbok:
	@rm -rf $(SPRINGBOK_BUILD_DIR)

.PHONY:: springbok clean_springbok test_springbok springbok_iree
