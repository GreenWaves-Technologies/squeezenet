# Copyright (C) 2020 GreenWaves Technologies
# All rights reserved.

# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.

ifndef GAP_SDK_HOME
  $(error Source sourceme in gap_sdk first)
endif


include common.mk
include $(RULES_DIR)/at_common_decl.mk

io?=host

$(info Building NNTOOL model)
NNTOOL_EXTRA_FLAGS ?= 

include common/model_decl.mk

IMAGE=$(CURDIR)/images/sample.ppm
GROUND_TRUTH = 644 # class predicted by tflite model on sample.ppm image

APP_SRCS += $(MODEL_PREFIX).c $(MODEL_GEN_C) $(MODEL_COMMON_SRCS) $(CNN_LIB)

APP_CFLAGS += -O3 -w -s -mno-memcpy -fno-tree-loop-distribute-patterns 
APP_CFLAGS += -I. -I$(GAP_SDK_HOME)/utils/power_meas_utils -I$(MODEL_COMMON_INC) -I$(TILER_EMU_INC) -I$(TILER_INC) -I$(MODEL_BUILD) $(CNN_LIB_INCLUDE)
APP_CFLAGS += -DPERF -DAT_MODEL_PREFIX=$(APP) $(MODEL_SIZE_CFLAGS) -DFREQ_FC=$(FREQ_FC) -DFREQ_CL=$(FREQ_CL) -DFREQ_PE=$(FREQ_PE)
APP_CFLAGS += -DSTACK_SIZE=$(CLUSTER_STACK_SIZE) -DSLAVE_STACK_SIZE=$(CLUSTER_SLAVE_STACK_SIZE) -DGROUND_TRUTH=$(GROUND_TRUTH)
APP_CFLAGS += -DAT_IMAGE=$(IMAGE)
ifneq '$(platform)' 'gvsoc'
ifdef GPIO_MEAS
APP_CFLAGS += -DGPIO_MEAS
endif
VOLTAGE?=800
ifeq '$(PMSIS_OS)' 'pulpos'
	APP_CFLAGS += -DVOLTAGE=$(VOLTAGE)
endif
endif

USE_PRIVILEGED_FLASH?=0
ifeq ($(USE_PRIVILEGED_FLASH), 1)
MODEL_SEC_L3_FLASH=AT_MEM_L3_MRAMFLASH
else
MODEL_SEC_L3_FLASH=
endif
ifneq ($(MODEL_SEC_L3_FLASH), )
  runner_args += --flash-property=$(CURDIR)/$(MODEL_SEC_TENSORS)@mram:readfs:files
endif

READFS_FILES=$(realpath $(MODEL_TENSORS))
PLPBRIDGE_FLAGS = -f

# build depends on the model
build:: model

clean:: clean_model

include common/model_rules.mk
include $(RULES_DIR)/pmsis_rules.mk
