TURTLE_CPU_TOP_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(TURTLE_CPU_TOP_DIR)/..
CURRENT_DIR := /work/turtle_cpu_top

include ../../rtl-toolkit/tools/tool_flows.mk

include ../clk_rst_gen/Makefile
CLK_RST_GEN_DIRS := $(INCLUDE_DIRS)
CLK_RST_GEN_FILE_LIST := $(FILE_LIST)

include ../alu/Makefile
ALU_INCLUDE_DIRS := $(INCLUDE_DIRS)
ALU_FILE_LIST := $(FILE_LIST)


INCLUDE_DIRS := $(CLK_RST_GEN_DIRS) $(ALU_INCLUDE_DIRS) $(TURTLE_CPU_TOP_DIR)/rtl $(TURTLE_CPU_TOP_DIR)/tb
FILE_LIST := turtle_cpu_top.sv 
WAVE_FILE := waves.vcd
