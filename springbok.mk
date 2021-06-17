SPRINGBOK_BUILD_DIR=$(OUT)/springbok/
SPRINGBOK_SRC_DIR=$(ROOTDIR)/sw/vec

springbok:
	cmake -B $(SPRINGBOK_BUILD_DIR) -GNinja $(SPRINGBOK_SRC_DIR)
	cmake --build $(SPRINGBOK_BUILD_DIR)

clean_springbok:
	@rm -rf $(SPRINGBOK_BUILD_DIR)

.PHONY:: springbok clean_springbok
