DECODER_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(DECODER_DIR)/..
CURRENT_DIR := /work/decoder

include ../../rtl-toolkit/tools/tool_flows.mk

include ../alu/Makefile
ALU_DIRS := $(INCLUDE_DIRS)
ALU_INCLUDE_FILES := $(INCLUDE_FILES)

include ../program_counter/Makefile
PROGRAM_COUNTER_DIRS := $(INCLUDE_DIRS)
PROGRAM_COUNTER_INCLUDE_FILES := $(INCLUDE_FILES)

INCLUDE_DIRS := $(ALU_DIRS) $(PROGRAM_COUNTER_DIRS) $(DECODER_DIR)/rtl $(DECODER_DIR)/tb
INCLUDE_FILES := $(ALU_INCLUDE_FILES) $(PROGRAM_COUNTER_INCLUDE_FILES) decoder_pkg.sv
FILE_LIST := $(INCLUDE_FILES) decoder.sv # decoder_tb.sv
WAVE_FILE := waves.vcd
