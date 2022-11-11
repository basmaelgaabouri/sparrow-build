# seL4 maps platform rpi3 to bcm2837, but this can be either 32- or 64-bit
# and defaults to 32-bit; override by forcing aarch64
CANTRIP_EXTRA_CMAKE_OPTS     := -DAARCH64=1
