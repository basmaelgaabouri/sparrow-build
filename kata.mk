KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
						-name \*.rs -or \
						-name \*.c -or \
						-name \*.h -or \
						-name \*.cpp \
						-type f)

OPENTITAN_GEN=$(OUT)/kata/opentitan-gen/include/opentitan

$(OPENTITAN_GEN):
	mkdir -p $(OPENTITAN_GEN)
	cd $(ROOTDIR)/hw/opentitan; \
		python3 util/regtool.py -D -o $(OPENTITAN_GEN)/uart.h hw/ip/uart/data/uart.hjson

kata-clean-opentitan-headers:
	rm -rf $(OPENTITAN_GEN)

kata-opentitan-headers: kata-clean-opentitan-headers $(OPENTITAN_GEN)

kata: $(KATA_SOURCES) $(OPENTITAN_GEN)
	mkdir -p $(OUT)/kata
	cd $(OUT)/kata && cmake -G Ninja -DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- -DSIMULATION=0 $(ROOTDIR)/kata/projects/processmanager
	cd $(OUT)/kata && ninja

.PHONY:: kata kata-opentitan-headers
