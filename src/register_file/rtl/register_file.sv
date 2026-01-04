`ifndef REGISTER_FILE_SV
`define REGISTER_FILE_SV

// register_file.sv
// author: Tom Riley
// date: 2025-07-03

/* verilator lint_off IMPORTSTAR */
import register_file_pkg::*;
/* verilator lint_on IMPORTSTAR */

module register_file #(
    parameter int DATA_W = 8,
    parameter int I_ADDR_WIDTH = 12,
    parameter int D_ADDR_WIDTH = 12,
    parameter int NUM_GPR = 8,
    parameter int REG_ADDR_WIDTH = 4
) (
    input logic clk,
    input logic reset_n,
    
    // Accumulator interface (tristate bus connections)
    output logic [DATA_W-1:0] acc_out,              // Always available ACC value
    input logic [DATA_W-1:0] acc_in,                // ACC input from tristate bus
    input logic acc_write_enable,                       // Write enable for ACC
    input logic read_get_to_acc,                        // enable for internal tristate from read_data to acc_in
    
    input logic write_put_acc,                          // enable for internal write from acc to reg[reg_addr]

    // General purpose register read port
    input logic [REG_ADDR_WIDTH-1:0] reg_addr,
    input logic read_data_output_enable,                       // Enable for ALU operand b bus
    output tri   [DATA_W-1:0] read_data,            // Tri-state output for read data to ALU operand b bus

    // Status register inputs (from ALU)
    input logic status_write_enable,
    input logic zero_flag,
    input logic positive_flag,
    input logic carry_flag,
    input logic overflow_flag,
    
    // Special register outputs for memory address computation
    output logic [D_ADDR_WIDTH-1:0] dmar,
    output logic [I_ADDR_WIDTH-1:0] imar,

    // Debug memory connections (for simulation/probing)
    input logic debug_enable,
    input logic [3:0] debug_addr,
    output logic [DATA_W-1:0] debug_rdata
    );
    logic [DATA_W-1:0] mem [15:0];

    // Internal register storage
    logic [DATA_W-1:0] gpr [NUM_GPR-1:0];           // R0-R7
    logic [DATA_W-1:0] acc;                         // Accumulator
    logic [D_ADDR_WIDTH-DATA_W-1:0] dbar;          // Data Memory Base Address Register
    logic [DATA_W-1:0] doff;                        // Data Memory Address Offset Register
    logic [I_ADDR_WIDTH-DATA_W-1:0] ibar;          // Instruction Memory Base Address Register
    logic [DATA_W-1:0] ioff;                        // Instruction Memory Address Offset Register
    logic [DATA_W-1:0] status;                      // Status Register

    logic [DATA_W-1:0] reg_read_data;
    logic [DATA_W-1:0] internal_acc_in;
    
    // Memory address computation
    assign dmar = {dbar, doff};
    assign imar = {ibar, ioff};
    
    // ACC output connections
    assign acc_out = acc;  // Always available for reading
    
    
    // Register read multiplexer (for operand_b and internal operations)
    always_comb begin
        case (reg_addr)
            REG_R0, REG_R1, REG_R2, REG_R3,
            REG_R4, REG_R5, REG_R6, REG_R7: begin
                reg_read_data = gpr[reg_addr[2:0]];
            end
            REG_ACC:    reg_read_data = acc;
            REG_DBAR:   reg_read_data = {{(DATA_W-(D_ADDR_WIDTH-DATA_W)){1'b0}}, dbar};
            REG_DOFF:   reg_read_data = doff;
            REG_IBAR:   reg_read_data = {{(DATA_W-(I_ADDR_WIDTH-DATA_W)){1'b0}}, ibar};
            REG_IOFF:   reg_read_data = ioff;
            REG_STATUS: reg_read_data = status;
            default:    reg_read_data = '0;
        endcase
    end

    // Internal accumulator writeback selection.
    // This is a mux (not a tri-state) to avoid multiple drivers on an internal variable.
    assign internal_acc_in = read_get_to_acc ? reg_read_data : acc_in;

    // Tri-state driver for read_data bus
    tristate_driver #(.DATA_W(DATA_W)) read_data_driver (
        .en(read_data_output_enable),
        .d(reg_read_data),
        .bus(read_data)
    );

    // Register write logic
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            // Reset all registers to zero
            for (int i = 0; i < NUM_GPR; i++) begin
                gpr[i] <= '0;
            end
            acc <= '0;
            dbar <= '0;
            doff <= '0;
            ibar <= '0;
            ioff <= '0;
            // Initialize status register with zero=1 and positive=1 flags (matching ACC=0)
            status <= 8'b00000011;
        end else begin
            // Accumulator update (highest priority)
            if (acc_write_enable && !debug_enable) begin
                acc <= internal_acc_in;
            end
            
            // PUT operation: Write ACC to register specified by reg_addr
            if (write_put_acc && !debug_enable) begin
                case (reg_addr)
                    REG_R0, REG_R1, REG_R2, REG_R3,
                    REG_R4, REG_R5, REG_R6, REG_R7: begin
                        gpr[reg_addr[2:0]] <= acc;
                    end
                    REG_DBAR: begin
                        dbar <= acc[D_ADDR_WIDTH-DATA_W-1:0];
                    end
                    REG_DOFF: begin
                        doff <= acc;
                    end
                    REG_IBAR: begin
                        ibar <= acc[I_ADDR_WIDTH-DATA_W-1:0];
                    end
                    REG_IOFF: begin
                        ioff <= acc;
                    end
                    default: begin
                        // Do nothing for invalid addresses or ACC (can't write ACC to itself)
                    end
                endcase
            end
            
            // Status register update from ALU flags
            if (status_write_enable && !debug_enable) begin
                status[ZERO_FLAG] <= zero_flag;     // Z/NZ flag
                status[POSITIVE_FLAG] <= positive_flag; // P/N flag (now directly positive)
                status[CARRY_FLAG] <= carry_flag;    // CS/CC flag
                status[OVERFLOW_FLAG] <= overflow_flag; // OS/OC flag
                // Upper bits remain unchanged
            end
        end
    end

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            mem[i] = '0; // Default to zero
        end

        // Memory view for debugging purposes
        mem[REG_R0] = gpr[0];
        mem[REG_R1] = gpr[1];
        mem[REG_R2] = gpr[2];
        mem[REG_R3] = gpr[3];
        mem[REG_R4] = gpr[4];
        mem[REG_R5] = gpr[5];
        mem[REG_R6] = gpr[6];
        mem[REG_R7] = gpr[7];
        mem[REG_ACC] = acc;
        mem[REG_DBAR] = {{(DATA_W-(D_ADDR_WIDTH-DATA_W)){1'b0}}, dbar};
        mem[REG_DOFF] = doff;
        mem[REG_IBAR] = {{(DATA_W-(I_ADDR_WIDTH-DATA_W)){1'b0}}, ibar};
        mem[REG_IOFF] = ioff;
        mem[REG_STATUS] = status;
    end

    // Debug memory read logic
    assign debug_rdata = mem[debug_addr];

endmodule: register_file

`endif // REGISTER_FILE_SV
