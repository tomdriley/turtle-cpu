REGISTER_FILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(REGISTER_FILE_DIR)/rtl $(REGISTER_FILE_DIR)/tb $(REGISTER_FILE_DIR)/../common/rtl
INCLUDE_FILES := register_file_pkg.sv tristate_driver.sv
FILE_LIST := $(INCLUDE_FILES) register_file.sv register_file_tb.sv
WAVE_FILE := waves.vcd
