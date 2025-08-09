ALU_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(ALU_DIR)/rtl $(ALU_DIR)/tb
INCLUDE_FILES := alu_pkg.sv
FILE_LIST := $(INCLUDE_FILES) alu.sv alu_tb.sv
WAVE_FILE := waves.vcd

SV2V_FILES := $(ALU_DIR)/rtl/alu_pkg.sv $(ALU_DIR)/rtl/alu.sv $(ALU_DIR)/rtl/alu_gates.sv
EQY_FILE := lec.eqy

SYNTH_SCRIPT := $(ALU_DIR)/synth.ys
synth: sv2v # Require sv2v to run before synthesis