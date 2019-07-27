# Makefile for ARM on macos

#	Naming the target and defining the build paths structure
#	Default is the name of the current directory
NAME = $(notdir $(shell pwd))

MCU = SAML21G18B

#	Toolchain Paths (variables defined with := are expanded once, but variables defined with = are expanded whenever they are used)
#	ARM GCC installation path
ARM_GCC_PATH := /mnt/d/arm-dev/gcc-arm-none-eabi-8-2019-q3-update
#	OpenOCD installation path 
OPENOCD_PATH := /mnt/d/arm-dev/OpenOCD-20190715-0.10.0
#	ASF installation path
ASF_PATH := /mnt/d/arm-dev/xdk-asf-3.45.0

BUILD_DIR = build
OBJECT_DIR = $(BUILD_DIR)/obj
DEPENDENCIES_DIR = $(BUILD_DIR)/dep

#	Additional src and include folders
FOLDER = driver

TARGET = $(BUILD_DIR)/$(NAME)

#	generating include flags for each includepath
# 	obtaining compiler default includes via "gcc -xc++ -E -v -" or "echo | ./arm-none-eabi-gcc.exe -Wp,-v -x c++ - -fsyntax-only"
INCLUDE_DIR = xdk-asf xdk-asf/include xdk-asf/cmsis $(FOLDER)
INCLUDE_FLAGS = $(INCLUDE_DIR:%=-I %)

SHARED_LIBS_PATHS = 
SHARED_LIBS_PATHS_FLAGS = $(SHARED_LIBS_PATHS:%=-L %) # mind the space between -L and %! Important so ~ in paths are expanded

#	shared libs
SHARED_LIBS = 
SHARED_LIBS_FLAGS = $(SHARED_LIBS:%=-l%)

#	defines
DEFINES = __$(MCU)__
DEFINES_FLAGS = $(DEFINES:%=-D%)

#	collecting all source files in the same directory as this makefile
SRC = $(wildcard *.c) $(wildcard */*.c)
CPPSRC = $(wildcard *.cpp) $(wildcard */*.cpp)
ASRC = $(wildcard *.S)

#	creating a list of all object files (compiled sources, but not linked)
OBJ = $(SRC:%.c=$(OBJECT_DIR)/%.o) $(CPPSRC:%.cpp=$(OBJECT_DIR)/%.o) $(ASRC:%.S=$(OBJECT_DIR)/%.o)

#	Defining Compiler Tools
PREFIX := $(ARM_GCC_PATH)/bin/arm-none-eabi-
CC := $(PREFIX)gcc
CXX := $(PREFIX)c++
LD := $(PREFIX)ld
GDB := $(PREFIX)gdb
SIZE := $(PREFIX)size
NM := $(PREFIX)nm
RM := rm -f -v
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
OPENOCD := $(OPENOCD_PATH)/bin/openocd.exe

#	compiler flags
WARNINGS = -Wall -Wextra -Wno-unused-parameter
ARCH_FLAGS := -mthumb -mcpu=cortex-m0plus -mfloat-abi=soft
LIBFLAGS = -static $(SHARED_LIBS_PATHS_FLAGS) $(SHARED_LIBS_FLAGS)
CXXFLAGS = -ffreestanding -ffunction-sections -fdata-sections -fno-rtti -fno-exceptions -g -Os $(ARCH_FLAGS) $(INCLUDE_FLAGS) $(WARNINGS) $(DEFINES_FLAGS) -std=c++11
CXXFLAGS += 
CFLAGS = -ffreestanding -ffunction-sections -fdata-sections -g -Os $(ARCH_FLAGS) $(INCLUDE_FLAGS) $(WARNINGS) $(DEFINES_FLAGS) 
LDFLAGS =  -Txdk-asf/flash.ld $(ARCH_FLAGS) -Wl,-Map,$(TARGET).map,--cref,--gc-sections $(LIBFLAGS)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPENDENCIES_DIR)/$*.Td

.DEFAULT_GOAL := all

all: tree $(TARGET).elf executables size
rebuild: clean all

$(TARGET).elf: $(OBJ)
	@echo "Linking $@"
	$(CXX) -o $@ $(OBJ) $(LDFLAGS)
	@echo 
	
$(OBJECT_DIR)/%.o: %.cpp $(DEPENDENCIES_DIR)/%.d
	@echo "Compiling $<" and generating Dependencies
	$(CXX) $(CXXFLAGS) $(DEPFLAGS) -c $< -o $@ 
	$(CXX) $(CXXFLAGS) -E $< -o $(OBJECT_DIR)/$*.i
	$(CXX) $(CXXFLAGS) -S $< -o $(OBJECT_DIR)/$*.s
	@mv -f $(DEPENDENCIES_DIR)/$*.Td $(DEPENDENCIES_DIR)/$*.d && touch $@
	@echo 

$(OBJECT_DIR)/%.o: %.c $(DEPENDENCIES_DIR)/%.d
	@echo "Compiling $<" and generating Dependencies
	$(CC) $(CFLAGS) $(DEPFLAGS) -c $< -o $@ 
	$(CC) $(CFLAGS) -E $< -o $(OBJECT_DIR)/$*.i
	$(CC) $(CFLAGS) -S $< -o $(OBJECT_DIR)/$*.s
	@mv -f $(DEPENDENCIES_DIR)/$*.Td $(DEPENDENCIES_DIR)/$*.d && touch $@
	@echo 

$(DEPENDENCIES_DIR)/%.d: ;
.PRECIOUS: $(DEPENDENCIES_DIR)/%.d

-include $(OBJ:%.o=$(DEPENDENCIES_DIR)/%.d)
	

.PHONY: clean rebuild tree run debug program server_start server_stop links reset help
run: all program

clean:
	@echo "Removing files:"
	@$(RM) $(TARGET).* 
	@$(RM) $(OBJECT_DIR)/*.*
	@$(RM) $(OBJECT_DIR)/xdk-asf/*.*
	@$(FOLDER:%=$(RM) $(OBJECT_DIR)/%/*.*)
	@$(RM) $(DEPENDENCIES_DIR)/*.*
	@$(FOLDER:%=$(RM) $(DEPENDENCIES_DIR)/%/*.*)

#	create folder structure if not existing
#	"@" in front of line suppresses the output ... I guess
tree:
	@if [ ! -d "$(BUILD_DIR)" ]; then mkdir -p $(BUILD_DIR); fi
	@if [ ! -d "$(OBJECT_DIR)/xdk-asf" ]; then mkdir -p $(OBJECT_DIR)/xdk-asf; fi
	@mkdir -p $(FOLDER:%=$(OBJECT_DIR)/%) || true
	@if [ ! -d "$(DEPENDENCIES_DIR)/xdk-asf" ]; then mkdir -p $(DEPENDENCIES_DIR)/xdk-asf; fi
	@mkdir -p $(FOLDER:%=$(DEPENDENCIES_DIR)/%) || true

#	print final codesize
size: $(TARGET).elf
	@$(NM) -n -f sysv --size-sort $< > $(TARGET).nm
	@$(SIZE) --format=sysv --radix=16 --target=elf32-littlearm $< > $(TARGET).size
	
	
#	create flash files, executable files for flash
executables: $(TARGET).elf
	$(OBJCOPY) -O ihex $< $(TARGET).hex
	$(OBJCOPY) -O binary $< $(TARGET).bin
	@$(OBJDUMP) -h -S $< > $(TARGET).s
	@echo 
	

debug:
	$(GDB) $(TARGET).elf -ex "target extended-remote localhost:3333" -ex load $(TARGET).elf

reset: 
	$(GDB) -iex "target extended-remote localhost:3333" -ex "monitor reset" 


# -iex "target extended-remote localhost:3333": initially connect to target
# -ex load: flash file to mcu
# -ex "monitor reset": reset remote target
# -ex "kill inferiors 1": kill the connection so we can quit without user interaction
# -ex quit: quit gdb
program:
	$(GDB) -iex "target extended-remote localhost:3333" -ex load -ex "monitor reset" -ex "kill inferiors 1" -ex quit $(TARGET).elf

# Execute openocd in the background and redirect all output to /dev/null
# Start only once !!
server_start:
	@echo 'Starting OpenOCD Server'
	@$(OPENOCD) &>/dev/null &

# use = instead of := to make this expand on each read
OPENOCD_PID = $(shell ps | grep openocd | cut -d' ' -f3 | sed 1q)
server_stop:
	@echo 'Stopping OpenOCD Server with pid $(OPENOCD_PID)'
	kill $(OPENOCD_PID)

links:
	@if [ ! -d "xdk-asf" ]; then \
		mkdir -p xdk-asf; \
		ln -s $(ASF_PATH)/thirdparty/CMSIS/Include xdk-asf/cmsis; \
		ln -s $(ASF_PATH)/sam0/utils/cmsis/saml21/include_b xdk-asf/include; \
		ln -s $(ASF_PATH)/sam0/utils/linker_scripts/saml21/gcc/saml21g18b_flash.ld xdk-asf/flash.ld; \
		ln -s $(ASF_PATH)/sam0/utils/cmsis/saml21/source/gcc/startup_saml21.c xdk-asf/ ; \
		ln -s $(ASF_PATH)/sam0/utils/cmsis/saml21/source/system_saml21.c xdk-asf/ ; \
		ln -s $(ASF_PATH)/sam0/utils/cmsis/saml21/source/system_saml21.h xdk-asf/ ; \
		ln -s $(ASF_PATH)/sam0/utils/syscalls/gcc/syscalls.c xdk-asf/;\
	fi

link_qtouch:
	@if [ ! -f "" ]; then ln -s $(ASF_PATH)/thirdparty/qtouch/devspecific/sam0/saml/include/touch_api_ptc.h xdk-asf/; fi

help:
	@echo "Supported commands:"
	@echo "all\t\tBuild project"
	@echo "clean\t\tClean up build directory"
	@echo "run\t\tBuild and flash target"
	@echo "program\t\tFlash target"
	@echo "debug\t\tFlash target and start gdb"
	@echo "reset\t\tReset target"
	@echo "server_start\tStart GDB Server"
	@echo "server_stop\tStop GDB Server"
	@echo "links\t\tLink project to ASF"
	@echo "tree\t\tCreates folder structure"
