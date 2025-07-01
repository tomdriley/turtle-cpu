CLK_RST_GEN_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(CLK_RST_GEN_DIR)/rtl $(CLK_RST_GEN_DIR)/tb
FILE_LIST := clk_rst_gen.sv clk_rst_gen_tb.sv
WAVE_FILE := waves.vcd
