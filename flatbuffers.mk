FLATBUFFERS_SRC_DIR     := $(ROOTDIR)/sw/flatbuffers
FLATBUFFERS_BUILD_DIR   := $(OUT)/flatbuffers
FLATBUFFERS_INSTALL_DIR := $(OUT)/host/flatbuffers

# NB: We only need to depend on some of the files in the host source tree from
# the flatbuffers repo, so a simple single directory wildcard should suffice for
# determining when we need to rebuild this target.
FLATBUFFERS_SRCS := $(wildcard $(FLATBUFFERS_SRC_DIR)/src/*)

$(FLATBUFFERS_BUILD_DIR):
	mkdir -p $(FLATBUFFERS_BUILD_DIR)

## Builds and installs the flatbuffers host tooling
#
# Output is placed in the out/host/flatbuffers tree.
flatbuffers: $(FLATBUFFERS_SRCS) | $(FLATBUFFERS_BUILD_DIR)
	cmake -S $(FLATBUFFERS_SRC_DIR) -B $(FLATBUFFERS_BUILD_DIR) -G Ninja \
		-DCMAKE_INSTALL_PREFIX=$(FLATBUFFERS_INSTALL_DIR)
	ninja -C $(OUT)/flatbuffers install

## Cleans up the flatbuffers binaries
flatbuffers-clean:
	rm -rf $(FLATBUFFERS_BUILD_DIR) $(FLATBUFFERS_INSTALL_DIR)

.PHONY:: flatbuffers
