INSTRUCTION_MEMORY_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(INSTRUCTION_MEMORY_DIR)/rtl $(INSTRUCTION_MEMORY_DIR)/tb
FILE_LIST := instruction_memory.sv instruction_memory_tb.sv
WAVE_FILE := waves.vcd
