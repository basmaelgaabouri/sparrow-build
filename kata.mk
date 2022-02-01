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

TIMER_HEADER=$(OPENTITAN_GEN)/timer.h
TIMER_IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/rv_timer
TIMER_JINJA=$(TIMER_IP_DIR)/util/reg_timer.py
TIMER_TEMPLATE=$(TIMER_IP_DIR)/data/rv_timer.hjson.tpl
TIMER_HJSON=$(OPENTITAN_GEN)/rv_timer.hjson
$(TIMER_HJSON): $(TIMER_JINJA) $(TIMER_TEMPLATE) | $(OPENTITAN_GEN)
	$(TIMER_JINJA) -s 2 -t 1 $(TIMER_TEMPLATE) > $(TIMER_HJSON)
$(TIMER_HEADER): $(REGTOOL) $(TIMER_HJSON) | $(OPENTITAN_GEN)
	$(REGTOOL) -D -o $(TIMER_HEADER) $(TIMER_HJSON)

UART_HEADER=$(OPENTITAN_GEN)/uart.h
UART_IP_DIR=$(OPENTITAN_SOURCE)/hw/ip/uart
UART_HJSON=$(UART_IP_DIR)/data/uart.hjson
$(UART_HEADER): $(REGTOOL) $(UART_HJSON) | $(OPENTITAN_GEN)
	$(REGTOOL) -D -o $(UART_HEADER) $(UART_HJSON)

$(VC_TOP_GEN):
	mkdir -p $(VC_TOP_GEN)

VC_TOP_HEADER=$(VC_TOP_GEN)/vc_top.h
VC_TOP_HJSON=$(OPENTITAN_SOURCE)/hw/ip/vc_top/data/vc_top.hjson
$(VC_TOP_HEADER): $(REGTOOL) $(VC_TOP_HJSON) | $(VC_TOP_GEN)
	$(REGTOOL) -D -o $(VC_TOP_HEADER) $(VC_TOP_HJSON)

KATA_COMPONENTS=$(ROOTDIR)/kata/projects/processmanager/apps/system/components
CARGO_TEST := cargo +$(KATA_RUST_VERSION) test

kata-clean-headers:
	rm -rf $(OPENTITAN_GEN) $(VC_TOP_HEADER)

kata-gen-headers: $(TIMER_HEADER) $(UART_HEADER) $(VC_TOP_HEADER)

## Builds the Kata operating system
#
# Kata is the seL4-based operating system that runs on the SMC in Sparrow. The
# source is in kata/, while the outputs are placed in out/kata.
kata: $(KATA_SOURCES) kata-gen-headers
	mkdir -p $(OUT)/kata
	cd $(OUT)/kata && cmake -G Ninja \
		-DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- \
		-DSIMULATION=0 \
		-DSEL4_CACHE_DIR=$(CACHE)/sel4 \
		$(ROOTDIR)/kata/projects/processmanager
	cd $(OUT)/kata && ninja

cargo_test_kata_proc_manager:
	cd $(KATA_COMPONENTS)/ProcessManager/kata-proc-manager && $(CARGO_TEST)

cargo_test_kata_proc_interface:
	cd $(KATA_COMPONENTS)/ProcessManager/kata-proc-interface && $(CARGO_TEST)

cargo_test_debugconsole_kata_logger:
	cd $(KATA_COMPONENTS)/DebugConsole/kata-logger && \
		$(CARGO_TEST) -- --test-threads=1

cargo_test_debugconsole_zmodem:
	cd $(KATA_COMPONENTS)/DebugConsole/zmodem && $(CARGO_TEST)

cargo_test_kata: cargo_test_kata_proc_manager cargo_test_kata_proc_interface cargo_test_debugconsole_kata_logger

$(OUT)/kata/kernel/kernel.elf: kata

.PHONY:: kata kata-clean-headers kata-gen-headers cargo_test_kata
