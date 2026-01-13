WRAPPER_FPGA_BASYS3_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include ../../rtl-toolkit/tools/tool_flows.mk

INCLUDE_DIRS := $(WRAPPER_FPGA_BASYS3_DIR)/rtl $(WRAPPER_FPGA_BASYS3_DIR)/tb
FILE_LIST := uart_receiver.sv uart_receiver_tb.sv
WAVE_FILE := waves.vcd
