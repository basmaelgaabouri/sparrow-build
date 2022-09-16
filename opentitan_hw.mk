## Run OpenTitan earlgrey smoketests in verilator
# Build the verilated model, the test software and runs the tests
earlgrey_hw_verilator_smoketests: | $(VERILATOR_BIN) $(OPENTITAN_BUILD_LOG_DIR)
	cd $(OPENTITAN_SRC_DIR) && \
		bazel query "kind(test, //sw/device/tests:all)" \
			| grep "_smoketest" \
			| xargs bazel test  --test_tag_filters=verilator,-broken --test_output=streamed
	cd $(OPENTITAN_SRC_DIR) && \
		cp -rf "bazel-testlogs/sw/device" "$(OPENTITAN_BUILD_LOG_SW_DIR)"

## Run All the OpenTitan earlgrey device tests in verilator
# Build the verilated model, the test software and runs the tests.
#
# Note: This will take hours to finish. Run it with caution.
earlgrey_hw_verilator_tests_all: | $(VERILATOR_BIN) $(OPENTITAN_BUILD_LOG_DIR)
	cd $(OPENTITAN_SRC_DIR) && \
		bazel query "kind(test, //sw/device/tests:all)" \
			| xargs bazel test  --test_tag_filters=verilator,-broken --test_output=streamed
	cd $(OPENTITAN_SRC_DIR) && \
		cp -rf "bazel-testlogs/sw/device" "$(OPENTITAN_BUILD_LOG_SW_DIR)"

.PHONY:: earlgrey_hw_verilator_smoketests earlgrey_hw_verilator_tests_all
