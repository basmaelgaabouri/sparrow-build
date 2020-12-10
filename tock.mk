
TOCK_OUTPUT_DIRECTORY=${OUT}/tock/
EARLGREY_TARGET_ELF=$(TOCK_OUTPUT_DIRECTORY)/riscv32imc-unknown-none-elf/release/earlgrey-nexysvideo.elf
TOCK_DIRECTORY=sw/tock
EARLGREY_BOARD_DIRECTORY=$(TOCK_DIRECTORY)/boards/earlgrey-nexysvideo

TOCK_DEPS=$(shell find $(ROOTDIR)/$(TOCK_DIRECTORY) \( -name '*.rs' -o -name '*.c' \) -printf "%p ")

$(EARLGREY_TARGET_ELF): $(TOCK_DEPS)
	cd $(EARLGREY_BOARD_DIRECTORY); \
	    make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(TOCK_OUTPUT_DIRECTORY) V=1

earlgrey_tock: $(EARLGREY_TARGET_ELF)

earlgrey_tock_clean:
	cd $(EARLGREY_BOARD_DIRECTORY); \
	    make TARGET_DIRECTORY=$(TOCK_OUTPUT_DIRECTORY) V=1 clean

.PHONY:: earlgrey_tock earlgrey_tock_clean
