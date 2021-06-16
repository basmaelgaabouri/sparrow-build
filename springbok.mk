SPRINGBOK_BUILD_DIR=$(OUT)/springbok/
SPRINGBOK_SRC_DIR=$(ROOTDIR)/sw/vec

springbok:
	cd $(SPRINGBOK_SRC_DIR)/hello_vec; \
		make OUTPREFIX=$(SPRINGBOK_BUILD_DIR)

clean_springbok:
	@rm -rf $(SPRINGBOK_BUILD_DIR)

.PHONY:: springbok clean_springbok
