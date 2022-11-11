include $(ROOTDIR)/build/platforms/rpi3/cantrip.mk
include $(ROOTDIR)/build/platforms/rpi3/cantrip_builtins.mk
include $(ROOTDIR)/build/platforms/rpi3/sim.mk
include $(ROOTDIR)/build/platforms/rpi3/sim_sel4test.mk

cantrip-build-release-prepare:: | $(CANTRIP_OUT_RELEASE)
cantrip-build-debug-prepare:: | $(CANTRIP_OUT_DEBUG)
cantrip-gen-headers::
cantrip-clean-headers::
