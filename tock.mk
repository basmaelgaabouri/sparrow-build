
TOCK_OUTPUT_DIRECTORY=$(OUT)/tock/
EARLGREY_TARGET_ELF=$(TOCK_OUTPUT_DIRECTORY)/riscv32imc-unknown-none-elf/release/opentitan.elf
TOCK_DIRECTORY=sw/tock
EARLGREY_BOARD_DIRECTORY=$(TOCK_DIRECTORY)/boards/opentitan

LIBTOCKRS_DIRECTORY=sw/libtock-rs
LIBTOCKRS_OUT=$(OUT)/libtock-rs/


$(EARLGREY_TARGET_ELF): $(TOCK_DEPS)

earlgrey_tock:
	cd $(EARLGREY_BOARD_DIRECTORY); \
	    make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(TOCK_OUTPUT_DIRECTORY) V=1

earlgrey_tock_clean:
	cd $(EARLGREY_BOARD_DIRECTORY); \
		make TARGET_DIRECTORY=$(TOCK_OUTPUT_DIRECTORY) V=1 clean

libtockrs_helloworld: earlgrey_tock
	cd $(LIBTOCKRS_DIRECTORY); \
		 PLATFORM=opentitan cargo run --release --target=riscv32imc-unknown-none-elf \
		 	--example=hello_world --target-dir=$(LIBTOCKRS_OUT)
	 riscv32-unknown-elf-objcopy --update-section .apps=$(LIBTOCKRS_OUT)/riscv32imc-unknown-none-elf/tab/opentitan/hello_world/rv32imc.tbf \
	 	$(EARLGREY_TARGET_ELF)

libtockrs_helloworld_clean:
	cd $(LIBTOCKRS_DIRECTORY); \
		 PLATFORM=opentitan cargo clean --release --target=riscv32imc-unknown-none-elf \
		 	--target-dir=$(LIBTOCKRS_OUT)

tock: libtockrs_helloworld

tock_clean: libtockrs_helloworld_clean earlgrey_tock_clean


.PHONY:: earlgrey_tock earlgrey_tock_clean libtockrs_helloworld libtockrs_helloworld_clean tock
