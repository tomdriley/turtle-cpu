DATA_MEMORY_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(DATA_MEMORY_DIR)/rtl $(DATA_MEMORY_DIR)/tb $(DATA_MEMORY_DIR)/../common/rtl
FILE_LIST := tristate_driver.sv data_memory.sv data_memory_tb.sv
WAVE_FILE := waves.vcd
