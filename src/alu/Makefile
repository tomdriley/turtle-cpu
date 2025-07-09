ALU_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(ALU_DIR)/rtl $(ALU_DIR)/tb
INCLUDE_FILES := alu_pkg.sv
FILE_LIST := $(INCLUDE_FILES) alu.sv # alu_tb.sv
WAVE_FILE := waves.vcd
