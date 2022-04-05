SPINGBOK_SYSTEMC_SRC_DIR     := $(ROOTDIR)/hw/springbok/systemc
SPINGBOK_SYSTEMC_BUILD_DIR   := $(OUT)/springbok/systemc

SPINGBOK_SYSTEMC_SOURCES := $(shell find $(SPINGBOK_SYSTEMC_SRC_DIR) \
	-name \*.h -or \
	-name \*.cc \
	-type f)

$(SPINGBOK_SYSTEMC_BUILD_DIR):
	mkdir -p $(SPINGBOK_SYSTEMC_BUILD_DIR)

## Springbok HW SystemC
#
# This target builds the springbok core SystemC module using the libsystemc
# library. The source code is at hw/springbok/systemc, while the output is
# at out/springbok/systemc.
springbok_systemc: systemc $(SPINGBOK_SYSTEMC_SOURCES) | $(SPINGBOK_SYSTEMC_BUILD_DIR)
	$(MAKE) -C $(SPINGBOK_SYSTEMC_SRC_DIR) all


## Springbok SystemC Tests
#
# This a lit test target to run the artifacts generated by `m springbok_systemc`
springbok_systemc_test: install_llvm springbok_systemc springbok_riscv_tests
	lit --path=/usr/lib/llvm-11/bin -a --time-tests $(SPINGBOK_SYSTEMC_SRC_DIR)/tests

springbok_systemc_clean:
	rm -r $(SPINGBOK_SYSTEMC_BUILD_DIR)

.PHONY:: springbok_systemc springbok_systemc_clean
