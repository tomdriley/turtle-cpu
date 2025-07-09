REGISTER_FILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(REGISTER_FILE_DIR)/rtl $(REGISTER_FILE_DIR)/tb
INCLUDE_FILES := register_file_pkg.sv
FILE_LIST := $(INCLUDE_FILES) register_file.sv # register_file_tb.sv
WAVE_FILE := waves.vcd
