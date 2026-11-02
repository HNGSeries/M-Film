# The film OS as a Magic Lantern module (build_fork.sh --module copies this to
# modules/filmos/ with the sources). Built per camera: the film OS reads the
# camera's buttons and sensor by CONFIG_<camera>, so build_fork.sh passes
# FILMOS_PLATFORM (e.g. 5D2.212) and the module is only for that camera.
MODULE_NAME = filmos
MODULE_OBJS = $(addprefix $(BUILD_DIR)/,$(FILMOS_OBJS))
# the maths the darkroom uses (exp2f, powf's helpers) come from the same libm and libgcc that
# autoexec.bin is linked with, so the module develops exactly as the built-in darkroom does
# (libm's own calls to __errno go to the module's fos_errno instead: libm isn't built with
# -mlong-calls, and the module may load too far from autoexec.bin for a plain BL to reach it)
MODULE_OBJS += $(BUILD_DIR)/fos-libm.a $(TOP_DIR)/platform/$(FILMOS_PLATFORM)/build/gcc-libgcc.a
TOP_DIR = ../..

FILMOS_MODEL = $(firstword $(subst ., ,$(FILMOS_PLATFORM)))
FILMOS_FW = $(lastword $(subst ., ,$(FILMOS_PLATFORM)))
MODULE_CFLAGS += -I$(TOP_DIR)/platform/$(FILMOS_PLATFORM) -I$(TOP_DIR)/platform/$(FILMOS_PLATFORM)/include \
    -DCONFIG_$(FILMOS_MODEL)=1 -DCONFIG_$(FILMOS_MODEL)_$(FILMOS_FW)=1 -DCONFIG_FW_VERSION=$(FILMOS_FW)

include $(TOP_DIR)/modules/Makefile
.DEFAULT_GOAL := $(BUILD_DIR)/module_complete

# (after the include: BUILD_DIR comes from it)
$(BUILD_DIR)/fos-libm.a: $(TOP_DIR)/platform/$(FILMOS_PLATFORM)/build/newlib-libm.a | $(BUILD_DIR)
	$(OBJCOPY) --redefine-sym __errno=fos_errno $< $@
