KATA_SOURCES := $(shell find $(ROOTDIR)/kata \
						-name \*.rs -or \
						-name \*.c -or \
						-name \*.h -or \
						-name \*.cpp \
						-type f)

kata: $(KATA_SOURCES)
	mkdir -p $(OUT)/kata
	cd $(OUT)/kata && cmake -G Ninja -DCROSS_COMPILER_PREFIX=riscv32-unknown-elf- -DSIMULATION=0 $(ROOTDIR)/kata/projects/processmanager
	cd $(OUT)/kata && ninja

.PHONY:: kata
