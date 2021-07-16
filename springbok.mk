SPRINGBOK_BUILD_DIR=$(OUT)/springbok/
SPRINGBOK_IREE_BUILD_DIR=$(OUT)/springbok_iree/
SPRINGBOK_SRC_DIR=$(ROOTDIR)/sw/vec

springbok:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)
	cmake --build $(SPRINGBOK_BUILD_DIR)

springbok_iree:
	cmake -B $(SPRINGBOK_IREE_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR) -DBUILD_IREE=ON
	cmake --build $(SPRINGBOK_IREE_BUILD_DIR) --target springbok_intrinsic

test_springbok:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)
	cmake --build $(SPRINGBOK_BUILD_DIR) --target AllTests

clean_springbok:
	@rm -rf $(SPRINGBOK_BUILD_DIR)
	@rm -rf $(SPRINGBOK_IREE_BUILD_DIR)

.PHONY:: springbok clean_springbok test_springbok springbok_iree
