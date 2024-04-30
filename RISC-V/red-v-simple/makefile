#------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------
REF_DIR := .
SRC_DIR := $(REF_DIR)/src
INC_DIR := 
LIB_DIR := 
OBJ_DIR := $(REF_DIR)/build
TRG_DIR := $(REF_DIR)/bin

TOOL_DIR = /opt/riscv/bin
BOARD    = /media/mike/HiFive 

#-----------------------------------------------------------------------------

TRG_NAME           := slon
LINKER_SCRIPT_FILE := red-v.ld

#-----------------------------------------------------------------------------
uniq    = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))
fixPath = $1


TRG_FILE  := $(TRG_NAME)
TRG       := $(TRG_DIR)/$(TRG_FILE)

#------------------------------------------------------------------------------

#--- assembler flags
ASM_FLAGS  = 
ASM_FLAGS += -march=rv32g
ASM_FLAGS += -mabi=ilp32

#--- linker flags
LD_FLAGS := 
#LD_FLAGS += -Wl,--gc-sections
#LD_FLAGS += -Wl,--cref
LD_FLAGS += -Wl,-Map=$(TRG_DIR)/$(TRG_NAME).map
LD_FLAGS += -T$(LINKER_SCRIPT_FILE)
LD_FLAGS += -nostartfiles
LD_FLAGS += -nostdlib
LD_FLAGS += -mcmodel=medany
LD_FLAGS += -static
#LD_FLAGS += -fvisibility=hidden

#------------------------------------------------------------------------------
ASM       = $(TOOL_DIR)/riscv64-unknown-elf-as
CC        = $(TOOL_DIR)/riscv64-unknown-elf-gcc
CXX       = $(TOOL_DIR)/riscv64-unknown-elf-g++
#LD        = $(TOOL_DIR)/riscv64-unknown-elf-ld
LD        = $(TOOL_DIR)/riscv64-unknown-elf-gcc
OC        = $(TOOL_DIR)/riscv64-unknown-elf-objcopy
OD        = $(TOOL_DIR)/riscv64-unknown-elf-objdump

#------------------------------------------------------------------------------

#---
ASM_SRC :=  $(SRC_DIR)/main.s
ASM_SRC_DIRS := $(dir $(ASM_SRC))
vpath %.s $(call uniq, $(ASM_SRC_DIRS))

ASM_FLAGS := $(strip $(ASM_FLAGS))
OBJ_ASM   := $(patsubst %.s,$(OBJ_DIR)/%.o,$(notdir $(ASM_SRC)))


#------------------------------------------------------------------------------
.PHONY: all clean load print-%

all:    $(TRG)

load: $(TRG)
	cp $(TRG).hex $(BOARD)

clean:
	rm -rf $(OBJ_DIR) $(TRG_DIR)

print-%:
	@echo $* = $($*)

#------------------------------------------------------------------------------

$(TRG): $(OBJ_ASM) | $(TRG_DIR)
	$(LD) $(LD_FLAGS) -o  $@ $(OBJ_ASM)
	$(OC) -O ihex $(TRG) $(TRG).hex
	$(OD) -d $(TRG) > $(TRG).lst

$(OBJ_ASM): $(OBJ_DIR)/%.o : %.s | $(OBJ_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(OBJ_DIR):
	mkdir $(call fixPath, $(abspath $(OBJ_DIR)))

$(TRG_DIR):
	mkdir $(call fixPath, $(abspath $(TRG_DIR)))






