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
    output logic [DATA_W-1:0] read_data,            // Tri-state output for read data to ALU operand b bus

    // Status register inputs (from ALU)
    input logic status_write_enable,
    input logic zero_flag,
    input logic negative_flag,
    input logic carry_flag,
    input logic overflow_flag,
    
    // Special register outputs for memory address computation
    output logic [D_ADDR_WIDTH-1:0] dmar,
    output logic [I_ADDR_WIDTH-1:0] imar
);

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

    // Tristate drivers for acc_in bus (internal read to accumulator)
    assign internal_acc_in = acc_in;
    assign internal_acc_in = read_get_to_acc ? reg_read_data : 'z;

    // Tristate driver for read_data bus
    assign read_data = read_data_output_enable ? reg_read_data : 'z;

    // Register write logic
    always_ff @(posedge clk or negedge reset_n) begin
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
            status <= '0;
        end else begin
            // Accumulator update (highest priority)
            if (acc_write_enable) begin
                acc <= internal_acc_in;
            end
            
            // PUT operation: Write ACC to register specified by reg_addr
            if (write_put_acc) begin
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
            if (status_write_enable) begin
                status[ZERO_FLAG] <= zero_flag;     // Z/NZ flag
                status[NEGATIVE_FLAG] <= negative_flag; // P/N flag
                status[CARRY_FLAG] <= carry_flag;    // CS/CC flag
                status[OVERFLOW_FLAG] <= overflow_flag; // OS/OC flag
                // Upper bits remain unchanged
            end
        end
    end

endmodule: register_file

`endif // REGISTER_FILE_SV
