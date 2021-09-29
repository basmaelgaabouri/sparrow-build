
TOCK_OUTPUT_DIRECTORY=$(OUT)/tock/
MATCHA_TARGET_ELF=$(TOCK_OUTPUT_DIRECTORY)/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf
MATCHA_BOARD_DIRECTORY=$(ROOTDIR)/sw/tock/boards/opentitan-matcha

LIBTOCKRS_DIRECTORY=sw/libtock-rs
LIBTOCKRS_OUT=$(OUT)/libtock-rs/


matcha_tock:
	cd $(MATCHA_BOARD_DIRECTORY); \
	    make BOARD_CONFIGURATION=sim_verilator TARGET_DIRECTORY=$(TOCK_OUTPUT_DIRECTORY)

matcha_tock_clean:
	cd $(MATCHA_BOARD_DIRECTORY); \
		make TARGET_DIRECTORY=$(TOCK_OUTPUT_DIRECTORY) clean

libtockrs_helloworld: matcha_tock
	cd $(LIBTOCKRS_DIRECTORY); \
		 PLATFORM=opentitan cargo run --release --target=riscv32imc-unknown-none-elf \
		 	--example=hello_world --target-dir=$(LIBTOCKRS_OUT)
	 riscv32-unknown-elf-objcopy --update-section .apps=$(LIBTOCKRS_OUT)/riscv32imc-unknown-none-elf/tab/opentitan/hello_world/rv32imc.tbf \
	 	$(MATCHA_TARGET_ELF)

libtockrs_helloworld_clean:
	cd $(LIBTOCKRS_DIRECTORY); \
		 PLATFORM=opentitan cargo clean --release --target=riscv32imc-unknown-none-elf \
		 	--target-dir=$(LIBTOCKRS_OUT)

tock: libtockrs_helloworld

$(OUT)/tock/riscv32imc-unknown-none-elf/release/opentitan-matcha.elf: tock

tock_clean: libtockrs_helloworld_clean matcha_tock_clean


.PHONY:: matcha_tock matcha_tock_clean libtockrs_helloworld libtockrs_helloworld_clean tock
