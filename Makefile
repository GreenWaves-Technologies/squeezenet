# Copyright (C) 2020 GreenWaves Technologies
# All rights reserved.

# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.

ifndef GAP_SDK_HOME
  $(error Source sourceme in gap_sdk first)
endif

APP=squeezenet
MODEL_PREFIX = squeezenet
MODEL_SQ8=1
AT_INPUT_WIDTH=224
AT_INPUT_HEIGHT=224
AT_INPUT_COLORS=3
pulpChip = GAP
RM=rm -r

IMAGE=$(CURDIR)/images/sample.ppm
GROUND_TRUTH = 644 # class predicted by tflite model on sample.ppm image

io=host

#ifeq ($(ALREADY_FLASHED),)
        # this is for the board
READFS_FILES=$(realpath $(MODEL_TENSORS))
PLPBRIDGE_FLAGS = -f
#endif

MODEL_HWC?=0
QUANT_BITS=8
BUILD_DIR=BUILD

TRAINED_TFLITE_MODEL = model/squeezenet.tflite
ifeq ($(MODEL_NE16), 1)
	NNTOOL_SCRIPT=model/nntool_script_ne16
	MODEL_SUFFIX = _NE16
else
ifeq ($(MODEL_HWC), 1)
	NNTOOL_SCRIPT=model/nntool_script_hwc
	MODEL_SUFFIX = _HWC_SQ8
	APP_CFLAGS += -DIMAGE_SUB_128
else
	NNTOOL_SCRIPT=model/nntool_script
	MODEL_SUFFIX = _SQ8
endif
endif

CLUSTER_STACK_SIZE=6096
CLUSTER_SLAVE_STACK_SIZE=1024
TOTAL_STACK_SIZE=$(shell expr $(CLUSTER_STACK_SIZE) \+ $(CLUSTER_SLAVE_STACK_SIZE) \* 7)
ifeq '$(TARGET_CHIP_FAMILY)' 'GAP9'
	TOTAL_STACK_SIZE = $(shell expr $(CLUSTER_STACK_SIZE) \+ $(CLUSTER_SLAVE_STACK_SIZE) \* 8)
	FREQ_CL?=370
	FREQ_FC?=370
	MODEL_L1_MEMORY=$(shell expr 128000 \- $(TOTAL_STACK_SIZE))
	MODEL_L2_MEMORY=1300000
	MODEL_L3_MEMORY=8000000
else
	TOTAL_STACK_SIZE = $(shell expr $(CLUSTER_STACK_SIZE) \+ $(CLUSTER_SLAVE_STACK_SIZE) \* 7)
	FREQ_CL?=175
	FREQ_FC?=250
	MODEL_L1_MEMORY=$(shell expr 60000 \- $(TOTAL_STACK_SIZE))
	MODEL_L2_MEMORY?=300000
	MODEL_L3_MEMORY=8000000
endif

MODEL_SIZE_CFLAGS = -DAT_INPUT_HEIGHT=$(AT_INPUT_HEIGHT) -DAT_INPUT_WIDTH=$(AT_INPUT_WIDTH) -DAT_INPUT_COLORS=$(AT_INPUT_COLORS)

include common/model_decl.mk

APP_SRCS += $(MODEL_PREFIX).c $(MODEL_GEN_C) $(MODEL_COMMON_SRCS) $(CNN_LIB)

APP_INC += $(TILER_INC) $(CNN_AT_PATH) $(AT_GENERATED) $(MODEL_BUILD) $(CNN_LIB_INCLUDE)

APP_CFLAGS += -O3 -w -s -mno-memcpy -fno-tree-loop-distribute-patterns 
APP_CFLAGS += -I. -I$(MODEL_COMMON_INC) -I$(TILER_EMU_INC) -I$(TILER_INC) -I$(AT_GENERATED) -I$(MODEL_BUILD) $(CNN_LIB_INCLUDE)
APP_CFLAGS += -DPERF -DAT_MODEL_PREFIX=$(APP) $(MODEL_SIZE_CFLAGS)
APP_CFLAGS += -DSTACK_SIZE=$(CLUSTER_STACK_SIZE) -DSLAVE_STACK_SIZE=$(CLUSTER_SLAVE_STACK_SIZE) -DGROUND_TRUTH=$(GROUND_TRUTH)
APP_CFLAGS += -DAT_IMAGE=$(IMAGE)

# all depends on the model
all:: model

clean:: clean_model

clean_at_model:
	$(RM) $(MODEL_GEN_EXE)

at_model_disp:: $(MODEL_BUILD) $(MODEL_GEN_EXE)
	$(MODEL_GEN_EXE) -o $(MODEL_BUILD) -c $(MODEL_BUILD) $(MODEL_GEN_EXTRA_FLAGS) --debug=Disp

at_model:: $(MODEL_BUILD) $(MODEL_GEN_EXE)
	$(MODEL_GEN_EXE) -o $(MODEL_BUILD) -c $(MODEL_BUILD) $(MODEL_GEN_EXTRA_FLAGS)

include common/model_rules.mk

include $(RULES_DIR)/pmsis_rules.mk
