ALU_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(ALU_DIR)/rtl $(ALU_DIR)/tb
INCLUDE_FILES := alu_pkg.sv
FILE_LIST := $(INCLUDE_FILES) alu.sv alu_tb.sv
WAVE_FILE := waves.vcd

SCRATCH_DIR := $(ALU_DIR)/scratch

make-scratch:
	@# Create a scratch directory for sv2v/synth/lec outputs
	@mkdir -p $(SCRATCH_DIR)

SV2V_FILES := $(ALU_DIR)/rtl/alu_pkg.sv $(ALU_DIR)/rtl/alu.sv $(ALU_DIR)/rtl/alu_gates.sv
SV2V_OUT_DIR := $(SCRATCH_DIR)
sv2v: make-scratch

EQY_FILE := lec.eqy
lec: make-scratch sv2v # Require sv2v to run before lec

SYNTH_SCRIPT := $(ALU_DIR)/synth.ys
synth: make-scratch sv2v # Require sv2v to run before synthesis