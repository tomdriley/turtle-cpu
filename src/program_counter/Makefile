PROGRAM_COUNTER_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(PROGRAM_COUNTER_DIR)/..
CURRENT_DIR := /work/program_counter

include ../../rtl-toolkit/tools/tool_flows.mk

include ../register_file/Makefile
REGISTER_FILE_DIRS := $(INCLUDE_DIRS)
REGISTER_FILE_INCLUDE_FILES := $(INCLUDE_FILES)

INCLUDE_DIRS := $(REGISTER_FILE_DIRS) $(PROGRAM_COUNTER_DIR)/rtl $(PROGRAM_COUNTER_DIR)/tb
INCLUDE_FILES := $(REGISTER_FILE_INCLUDE_FILES) program_counter_pkg.sv
FILE_LIST := $(INCLUDE_FILES) program_counter.sv # program_counter_tb.sv
WAVE_FILE := waves.vcd
