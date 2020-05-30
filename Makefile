# Copyright (C) 2020 GreenWaves Technologies
# All rights reserved.

# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.

ifndef GAP_SDK_HOME
  $(error Source sourceme in gap_sdk first)
endif

APP = squeezenet
AT_INPUT_WIDTH=224
AT_INPUT_HEIGHT=224
AT_INPUT_COLORS=3
pulpChip = GAP
RM=rm -f

IMAGE=$(CURDIR)/images/sample-0.ppm

export GAP_USE_OPENOCD=1
io=host

#ifeq ($(ALREADY_FLASHED),)
        # this is for the board
READFS_FILES=$(realpath $(MODEL_TENSORS))
PLPBRIDGE_FLAGS = -f
#endif

QUANT_BITS=8
BUILD_DIR=BUILD

#To Enable Bridge functions to read/write files from host (this function will be replaced by semihosting in next SDK release):
USE_BRIDGE=1

USE_DISP=1
ifdef USE_DISP
  SDL_FLAGS= -lSDL2 -lSDL2_ttf
else
  SDL_FLAGS=
endif

NNTOOL_SCRIPT=model/nn_tool_script
MODEL_SUFFIX = _16BIT
TRAINED_TFLITE_MODEL=model/squeezenet.tflite

CLUSTER_STACK_SIZE=2048
CLUSTER_SLAVE_STACK_SIZE=1024
TOTAL_STACK_SIZE=$(shell expr $(CLUSTER_STACK_SIZE) \+ $(CLUSTER_SLAVE_STACK_SIZE) \* 7)
MODEL_L1_MEMORY=$(shell expr 60000 \- $(TOTAL_STACK_SIZE))
MODEL_L2_MEMORY=100000
MODEL_L3_MEMORY=6388608
MODEL_SIZE_CFLAGS = -DAT_INPUT_HEIGHT=$(AT_INPUT_HEIGHT) -DAT_INPUT_WIDTH=$(AT_INPUT_WIDTH) -DAT_INPUT_COLORS=$(AT_INPUT_COLORS)

include model_decl.mk

APP_SRCS += $(APP).c ImgIO.c $(MODEL_COMMON_SRCS) $(MODEL_SRCS)

APP_INC += $(TILER_INC) $(CNN_AT_PATH) $(AT_GENERATED) $(MODEL_BUILD)

APP_CFLAGS += -O3 -w -s -mno-memcpy -fno-tree-loop-distribute-patterns 
APP_CFLAGS += -I. -I$(MODEL_COMMON_INC) -I$(TILER_EMU_INC) -I$(TILER_INC) -I$(TILER_CNN_KERNEL_PATH) -I$(AT_GENERATED) -I$(MODEL_BUILD)
APP_CFLAGS += -DPERF -DAT_MODEL_PREFIX=$(APP) $(MODEL_SIZE_CFLAGS)
APP_CFLAGS += -DSTACK_SIZE=$(CLUSTER_STACK_SIZE) -DSLAVE_STACK_SIZE=$(CLUSTER_SLAVE_STACK_SIZE)
APP_CFLAGS += -DAT_IMAGE=$(IMAGE)

# all depends on the model
all:: model

clean:: clean_model

include ./model_rules.mk

include $(GAP_SDK_HOME)/tools/rules/pmsis_rules.mk
