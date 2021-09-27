KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
						-name \*.rs -or \
						-name \*.c -or \
						-name \*.h -or \
						-name \*.cpp \
						-type f)

OPENTITAN_SOURCE=$(ROOTDIR)/hw/opentitan-upstream
OPENTITAN_OLD_SOURCE=$(ROOTDIR)/hw/opentitan

OPENTITAN_GEN=$(OUT)/kata/opentitan-gen/include/opentitan
VC_TOP_GEN=$(OUT)/kata/vc_top-gen/include/vc_top

REGTOOL=$(OPENTITAN_SOURCE)/util/regtool.py
OLD_REGTOOL=$(OPENTITAN_OLD_SOURCE)/util/regtool.py

$(OPENTITAN_GEN):
	mkdir -p $(OPENTITAN_GEN)

PLIC_HEADER=$(OPENTITAN_GEN)/plic.h
PLIC_IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/rv_plic
PLIC_HJSON=$(PLIC_IP_DIR)/data/rv_plic.hjson
PLIC_JINJA=$(PLIC_IP_DIR)/util/reg_rv_plic.py
PLIC_TEMPLATE=$(PLIC_IP_DIR)/data/rv_plic.hjson.tpl
$(PLIC_HEADER): $(OPENTITAN_GEN) $(REGTOOL) $(PLIC_JINJA) $(PLIC_TEMPLATE) $(PLIC_HJSON)
	$(PLIC_JINJA) -s 96 -t 2 -p 7 $(PLIC_TEMPLATE) > $(PLIC_HJSON)
	$(REGTOOL) -D -o $(PLIC_HEADER) $(PLIC_HJSON)

TIMER_HEADER=$(OPENTITAN_GEN)/timer.h
TIMER_IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/rv_timer
TIMER_HJSON=$(TIMER_IP_DIR)/data/rv_timer.hjson
TIMER_JINJA=$(TIMER_IP_DIR)/util/reg_timer.py
TIMER_TEMPLATE=$(TIMER_IP_DIR)/data/rv_timer.hjson.tpl
$(TIMER_HEADER): $(OPENTITAN_GEN) $(REGTOOL) $(TIMER_JINJA) $(TIMER_TEMPLATE) $(TIMER_HJSON)
	$(TIMER_JINJA) -s 2 -t 1 $(TIMER_TEMPLATE) > $(TIMER_HJSON)
	$(REGTOOL) -D -o $(TIMER_HEADER) $(TIMER_HJSON)

UART_HEADER=$(OPENTITAN_GEN)/uart.h
UART_IP_DIR=$(OPENTITAN_OLD_SOURCE)/hw/ip/uart
UART_HJSON=$(UART_IP_DIR)/data/uart.hjson
# TODO(mattharvey): Migrate UART to opentitan-upstream.
$(UART_HEADER): $(OPENTITAN_GEN) $(OLD_REGTOOL) $(UART_HJSON)
	$(OLD_REGTOOL) -D -o $(UART_HEADER) $(UART_HJSON)

$(VC_TOP_GEN):
	mkdir -p $(VC_TOP_GEN)

VC_TOP_HEADER=$(VC_TOP_GEN)/vc_top.h
VC_TOP_HJSON=$(OPENTITAN_SOURCE)/hw/ip/vc_top/data/vc_top.hjson
$(VC_TOP_HEADER): $(VC_TOP_GEN) $(REGTOOL) $(VC_TOP_HJSON)
	$(REGTOOL) -D -o $(VC_TOP_HEADER) $(VC_TOP_HJSON)

kata-clean-headers:
	rm -rf $(OPENTITAN_GEN) $(VC_TOP_HEADER)

kata-gen-headers: $(PLIC_HEADER) $(TIMER_HEADER) $(UART_HEADER) $(VC_TOP_HEADER)

kata: $(KATA_SOURCES) kata-gen-headers
	mkdir -p $(OUT)/kata
	cd $(OUT)/kata && cmake -G Ninja \
		-DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4 \
		$(ROOTDIR)/kata/projects/processmanager
	cd $(OUT)/kata && ninja

.PHONY:: kata kata-clean-headers kata-gen-headers
