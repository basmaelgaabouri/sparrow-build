SPRINGBOK_BUILD_DIR=$(OUT)/springbok/
SPRINGBOK_SRC_DIR=$(ROOTDIR)/sw/vec

$(SPRINGBOK_BUILD_DIR)/build.ninja:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)

springbok: $(SPRINGBOK_BUILD_DIR)/build.ninja
	cmake --build $(SPRINGBOK_BUILD_DIR)

test_springbok: $(SPRINGBOK_BUILD_DIR)/build.ninja
	cmake --build $(SPRINGBOK_BUILD_DIR) --target AllTests

clean_springbok:
	@rm -rf $(SPRINGBOK_BUILD_DIR)

.PHONY:: springbok clean_springbok test_springbok
