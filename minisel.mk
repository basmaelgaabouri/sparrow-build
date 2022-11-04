# Minisel requires that we've already generated our platform-specific headers
# in $OUT/.../kernel, so we depend on the Cantrip kernel here.

$(CANTRIP_OUT_DEBUG)/minisel/minisel.elf: $(ROOTDIR)/cantrip/projects/minisel/minisel.c $(CANTRIP_KERNEL_DEBUG)
	$(MAKE) -C $(ROOTDIR)/cantrip/projects/minisel SRC_LIBSEL4=$(SEL4_KERNEL_DIR)/libsel4 OUT_CANTRIP=$(CANTRIP_OUT_DEBUG) OUT_MINISEL=$(CANTRIP_OUT_DEBUG)/minisel all

$(CANTRIP_OUT_RELEASE)/minisel/minisel.elf: $(ROOTDIR)/cantrip/projects/minisel/minisel.c $(CANTRIP_KERNEL_RELEASE)
	$(MAKE) -C $(ROOTDIR)/cantrip/projects/minisel OPT=-O3 DBG= SRC_LIBSEL4=$(SEL4_KERNEL_DIR)/libsel4 OUT_CANTRIP=$(CANTRIP_OUT_RELEASE) OUT_MINISEL=$(CANTRIP_OUT_RELEASE)/minisel all

## Build minisel for debugging
minisel_debug: $(CANTRIP_OUT_DEBUG)/minisel/minisel.elf

## Build minisel for release
minisel_release: $(CANTRIP_OUT_RELEASE)/minisel/minisel.elf

.PHONY:: minisel_debug minisel_release
