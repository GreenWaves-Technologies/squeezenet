# Copyright (C) 2017 GreenWaves Technologies
# All rights reserved.

# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.

APP = squeezenet
AT_INPUT_WIDTH=224
AT_INPUT_HEIGHT=224
AT_INPUT_COLORS=3
IMAGE=sample.png
RM=rm -f

#To Enable Bridge functions to read/write files from host (this function will be replaced by semihosting in next SDK release):
USE_BRIDGE=1

ifeq ($(USE_BRIDGE),1)
APP_CFLAGS += -DENABLE_BRIDGE
PLPBRIDGE_FLAGS += -fileIO 10
endif

USE_DISP=1
ifdef USE_DISP
  SDL_FLAGS= -lSDL2 -lSDL2_ttf
else
  SDL_FLAGS=
endif

CLUSTER_STACK_SIZE=2048
CLUSTER_SLAVE_STACK_SIZE=1024
TOTAL_STACK_SIZE=$(shell expr $(CLUSTER_STACK_SIZE) \+ $(CLUSTER_SLAVE_STACK_SIZE) \* 7)
MODEL_L1_MEMORY=$(shell expr 60000 \- $(TOTAL_STACK_SIZE))
MODEL_L2_MEMORY=450000
MODEL_L3_MEMORY=8388608
MODEL_SIZE_CFLAGS = -DAT_INPUT_HEIGHT=$(AT_INPUT_HEIGHT) -DAT_INPUT_WIDTH=$(AT_INPUT_WIDTH) -DAT_INPUT_COLORS=$(AT_INPUT_COLORS)

MODEL_COMMON ?= ../common
MODEL_COMMON_INC ?= $(MODEL_COMMON)/src
MODEL_COMMON_SRC ?= $(MODEL_COMMON)/src
MODEL_COMMON_SRC_FILES ?= ImgIO.c helpers.c
MODEL_COMMON_SRCS = $(realpath $(addprefix $(MODEL_COMMON_SRC)/,$(MODEL_COMMON_SRC_FILES)))
CNN_AT_PATH = $(TILER_GENERATOR_PATH)/CNN
MODEL_DIR = ./BUILD_MODEL_8BIT

APP_SRCS += $(MODEL_DIR)/$(APP)_ATmodel.c $(AT_GENERATED)/$(APP)Kernels.c \
            $(APP).c \
            $(CNN_AT_PATH)/CNN_BiasReLULinear_BasicKernels.c \
            $(CNN_AT_PATH)/CNN_Conv_BasicKernels.c \
            $(CNN_AT_PATH)/CNN_MatAlgebra.c \
            $(CNN_AT_PATH)/CNN_Pooling_BasicKernels.c \
            $(CNN_AT_PATH)/CNN_Conv_DW_DP_BasicKernels.c \
            $(CNN_AT_PATH)/CNN_Conv_DW_BasicKernels.c \
            $(CNN_AT_PATH)/CNN_Conv_DP_BasicKernels.c \
            $(CNN_AT_PATH)/CNN_SoftMax.c

APP_SRCS += $(MODEL_COMMON_SRCS) $(MODEL_SRCS)

AT_GENERATED = ./AT_gen_code
$(AT_GENERATED):
	mkdir $(AT_GENERATED)

APP_INC += $(TILER_INC) $(CNN_AT_PATH) $(AT_GENERATED)

APP_CFLAGS += -O3 -s -mno-memcpy -fno-tree-loop-distribute-patterns 
APP_CFLAGS += -I. -I$(MODEL_COMMON_INC) -I$(TILER_EMU_INC) -I$(TILER_INC) -I$(TILER_CNN_KERNEL_PATH) -I$(AT_GENERATED) -I$(MODEL_DIR)
APP_CFLAGS += -DPERF -DAT_MODEL_PREFIX=$(APP) $(MODEL_SIZE_CFLAGS)
APP_CFLAGS += -DSTACK_SIZE=$(CLUSTER_STACK_SIZE) -DSLAVE_STACK_SIZE=$(CLUSTER_SLAVE_STACK_SIZE)
APP_CFLAGS += -DAT_IMAGE=$(IMAGE)

#APP_CFLAGS += -O2 -mno-memcpy -fno-tree-loop-distribute-patterns -fdata-sections -ffunction-sections
#APP_CFLAGS += -Wno-maybe-uninitialized -Wno-unused-but-set-variable 
#LDFLAGS    +=  -flto -Wl,--gc-sections

#mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
#FLASH_FILE_PATH = $(dir $(mkfile_path))binFiles/
#FLASH_FILES = $(shell find $(FLASH_FILE_PATH) -iname "L0_INPUT.bin")
#FLASH_FILES += $(shell find $(dir $(mkfile_path)) -iname "mobilenet_v1_L3_Flash_Const.dat")
#PLPBRIDGE_FLAGS += -f $(FLASH_FILES) 
#override runner_args = $(addprefix --config-opt=flash/fs/files=, $(FLASH_FILES))
# --trace=.*

#Uncomment to use freertos
#PMSIS_OS ?= freerto
USE_PMSIS_BSP = 1

# The double colon allows us to force this to occur before the imported all target
# Link model generation to all step
all:: $(APP)Kernels.c

# Build the code generator
GenTile:
	gcc -o Gen$(APP) -I$(TILER_INC) -I$(CNN_AT_PATH) $(MODEL_DIR)/$(APP)_ATmodel.c $(CNN_AT_PATH)/CNN_Generators.c $(TILER_LIB) $(SDL_FLAGS)

# Run the code generator
$(APP)Kernels.c: GenTile $(AT_GENERATED)
	./Gen$(APP) -o $(AT_GENERATED) -c $(AT_GENERATED) 

model: $(APP)Kernels.c

clean::
	$(RM) Gen$(APP)
	$(RM) -rf $(AT_GENERATED)
	echo $(CNN_AT_PATH)

.PHONY: model clean

include $(GAP_SDK_HOME)/tools/rules/pmsis_rules.mk
