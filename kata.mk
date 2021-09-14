KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
						-name \*.rs -or \
						-name \*.c -or \
						-name \*.h -or \
						-name \*.cpp \
						-type f)

OPENTITAN_SOURCE=$(ROOTDIR)/hw/opentitan-upstream
OPENTITAN_GEN=$(OUT)/kata/opentitan-gen/include/opentitan
VC_TOP_GEN=$(OUT)/kata/vc_top-gen/include/vc_top
REGTOOL=$(OPENTITAN_SOURCE)/util/regtool.py

$(OPENTITAN_GEN):
	mkdir -p $(OPENTITAN_GEN)

PLIC_HEADER=$(OPENTITAN_GEN)/plic.h
$(PLIC_HEADER): IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/rv_plic
$(PLIC_HEADER): JINJA=$(IP_DIR)/util/reg_rv_plic.py
$(PLIC_HEADER): TEMPLATE=$(IP_DIR)/data/rv_plic.hjson.tpl
$(PLIC_HEADER): HJSON=$(OPENTITAN_GEN)/rv_plic.hjson
$(PLIC_HEADER): $(OPENTITAN_GEN) $(JINJA) $(TEMPLATE) $(REGTOOL)
	$(JINJA) -s 96 -t 2 -p 7 $(TEMPLATE) > $(HJSON)
	$(REGTOOL) -D -o $(PLIC_HEADER) $(HJSON)

TIMER_HEADER=$(OPENTITAN_GEN)/timer.h
$(TIMER_HEADER): IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/rv_timer
$(TIMER_HEADER): JINJA=$(IP_DIR)/util/reg_timer.py
$(TIMER_HEADER): TEMPLATE=$(IP_DIR)/data/rv_timer.hjson.tpl
$(TIMER_HEADER): HJSON=$(OPENTITAN_GEN)/rv_timer.hjson
$(TIMER_HEADER): $(OPENTITAN_GEN) $(JINJA) $(TEMPLATE) $(REGTOOL)
	$(JINJA) -s 2 -t 1 $(TEMPLATE) > $(HJSON)
	$(REGTOOL) -D -o $(TIMER_HEADER) $(HJSON)

UART_HEADER=$(OPENTITAN_GEN)/uart.h
# TODO(mattharvey): Migrate UART to opentitan-upstream.
$(UART_HEADER): OPENTITAN_SOURCE=$(ROOTDIR)/hw/opentitan
$(UART_HEADER): REGTOOL=$(OPENTITAN_SOURCE)/util/regtool.py
$(UART_HEADER): IP_DIR=$(ROOTDIR)/hw/opentitan/hw/ip/uart
$(UART_HEADER): HJSON=$(IP_DIR)/data/uart.hjson
$(UART_HEADER): $(OPENTITAN_GEN) $(TEMPLATE) $(REGTOOL)
	$(REGTOOL) -D -o $(UART_HEADER) $(HJSON)

$(VC_TOP_GEN):
	mkdir -p $(VC_TOP_GEN)

VC_TOP_HEADER=$(VC_TOP_GEN)/vc_top.h
$(VC_TOP_HEADER): HJSON=$(ROOTDIR)/hw/springbok/vc_top/data/vc_top.hjson
$(VC_TOP_HEADER): $(VC_TOP_GEN) $(TEMPLATE) $(REGTOOL)
	$(REGTOOL) -D -o $(VC_TOP_HEADER) $(HJSON)

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

.PHONY:: kata kata-clean-headers
