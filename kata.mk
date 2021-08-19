KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
						-name \*.rs -or \
						-name \*.c -or \
						-name \*.h -or \
						-name \*.cpp \
						-type f)

OPENTITAN_GEN=$(OUT)/kata/opentitan-gen/include/opentitan
PLIC_HJSON=$(OPENTITAN_GEN)/rv_plic.hjson

$(OPENTITAN_GEN):
	mkdir -p $(OPENTITAN_GEN)
	# TODO(mattharvey): Migrate UART to opentitan-upstream.
	cd $(ROOTDIR)/hw/opentitan; \
		python3 util/regtool.py -D -o $(OPENTITAN_GEN)/uart.h hw/ip/uart/data/uart.hjson; \
	cd $(ROOTDIR)/hw/opentitan-upstream; \
		python3 hw/ip/rv_plic/util/reg_rv_plic.py -s 96 -t 2 -p 7 hw/ip/rv_plic/data/rv_plic.hjson.tpl > $(PLIC_HJSON); \
		python3 util/regtool.py -D -o $(OPENTITAN_GEN)/plic.h $(PLIC_HJSON)

kata-clean-opentitan-headers:
	rm -rf $(OPENTITAN_GEN)

kata-opentitan-headers: kata-clean-opentitan-headers $(OPENTITAN_GEN)

kata: $(KATA_SOURCES) $(OPENTITAN_GEN)
	mkdir -p $(OUT)/kata
	cd $(OUT)/kata && cmake -G Ninja \
		-DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4 \
		$(ROOTDIR)/kata/projects/processmanager
	cd $(OUT)/kata && ninja

.PHONY:: kata kata-opentitan-headers
