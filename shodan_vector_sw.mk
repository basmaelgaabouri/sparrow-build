SHODAN_VECTOR_BUILD_DIR=$(OUT)/sparrow_vector_tests
SHODAN_VECTOR_BUILD_OUT_DIR=$(SHODAN_VECTOR_BUILD_DIR)/build-out
SHODAN_VECTOR_BUILD_NINJA_SCRIPT=$(SHODAN_VECTOR_BUILD_DIR)/build-out/build.ninja
SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG=$(SHODAN_VECTOR_BUILD_DIR)/toolchain-configured.txt

$(SHODAN_VECTOR_BUILD_DIR):
	@mkdir -p "$(SHODAN_VECTOR_BUILD_DIR)"

$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG): | $(SHODAN_VECTOR_BUILD_DIR)
	@echo "Setup toolchain configuration $(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"
	cd $(ROOTDIR)/sw/vector_tests; \
		cp toolchain.txt $(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG); \
	    	sed -i "s#%TOOLCHAIN_PATH%#$(CACHE)/toolchain_vp#g" "$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"

$(SHODAN_VECTOR_BUILD_NINJA_SCRIPT): $(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)
	@echo "Creating build directories $(SHODAN_VECTOR_BUILD_OUT_DIR)"
	cd $(ROOTDIR)/hw/opentitan; \
	    BUILD_ROOT=$(SHODAN_VECTOR_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"

vector_tests_clean:
	@echo "Remove sparrow vector tests directory $(SHODAN_VECTOR_BUILD_DIR)"
	@rm -rf $(SHODAN_VECTOR_BUILD_DIR)

vector_tests_hellovector: $(SHODAN_VECTOR_BUILD_NINJA_SCRIPT) sparrow_test_sw_bootrom
	cd $(ROOTDIR)/sw/vector_tests; \
		BUILD_ROOT=$(SHODAN_VECTOR_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"; \
		ninja -C $(SHODAN_VECTOR_BUILD_OUT_DIR) \
			hello_vector/hello_vector_export_sim_verilator hello_vector/hello_vector_export_sim_dv hello_vector/hello_vector_export_fpga_nexysvideo

vector_tests_load_store: $(SHODAN_VECTOR_BUILD_NINJA_SCRIPT) sparrow_test_sw_bootrom
	cd $(ROOTDIR)/sw/vector_tests; \
		BUILD_ROOT=$(SHODAN_VECTOR_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"; \
		ninja -C $(SHODAN_VECTOR_BUILD_OUT_DIR) \
			vector_load_store_tests_export_sim_verilator vector_load_store_tests_export_sim_dv vector_load_store_tests_export_fpga_nexysvideo

vector_vadd_vsub_tests: $(SHODAN_BUILD_NINJA_SCRIPT)
	cd $(ROOTDIR)/sw/vector_tests; \
		BUILD_ROOT=$(SHODAN_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_BUILD_TOOLCHAIN_CONFIG)"; \
		ninja --verbose -C $(SHODAN_BUILD_OUT_DIR) \
			vector_vadd_vsub_tests_export_sim_verilator vector_vadd_vsub_tests_export_sim_dv vector_vadd_vsub_tests_export_fpga_nexysvideo;

vector_tests_vset: $(SHODAN_VECTOR_BUILD_NINJA_SCRIPT) sparrow_test_sw_bootrom
	cd $(ROOTDIR)/sw/vector_tests; \
		BUILD_ROOT=$(SHODAN_VECTOR_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"; \
		ninja -C $(SHODAN_VECTOR_BUILD_OUT_DIR) \
			vector_vset_tests_export_sim_verilator vector_vset_tests_export_sim_dv vector_vset_tests_export_fpga_nexysvideo

vector_executive: $(SHODAN_VECTOR_BUILD_NINJA_SCRIPT) sparrow_test_sw_bootrom
	cd $(ROOTDIR)/sw/vector_tests; \
	    BUILD_ROOT=$(SHODAN_VECTOR_BUILD_DIR) ./meson_init.sh -f -t "$(SHODAN_VECTOR_BUILD_TOOLCHAIN_CONFIG)"; \
	    ninja -C $(SHODAN_VECTOR_BUILD_OUT_DIR) vector_executive/vector_executive_export_sim_verilator

.PHONY:: vector_tests_load_store vector_tests_vset vector_vadd_vsub_tests vector_tests_hellovector vector_executive vector_tests_clean
