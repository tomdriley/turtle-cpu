`ifndef ALU
`define ALU

// alu.sv
// author: Tom Riley
// date: 2025-07-05

/* verilator lint_off IMPORTSTAR */
import alu_pkg::*;
/* verilator lint_on IMPORTSTAR */

module alu#(
    parameter int DATA_W = 8
)(
    // Inputs
    input   wire [DATA_W-1:0]   operand_a,
    input   wire [DATA_W-1:0]   operand_b,
    input   wire alu_func_e         alu_func,
    input   wire                    output_enable,
    // Outputs
    output  wire [DATA_W-1:0]   alu_result,
    output  wire                    zero_flag,
    output  wire                    positive_flag,
    output  wire                    carry_flag,
    output  wire                    signed_overflow
);
    logic [DATA_W-1:0] result;

    always_comb begin
        case (alu_func)
            ADD: begin
                {carry_flag, result} = operand_a + operand_b;
            end
            SUB: begin
                {carry_flag, result} = operand_a - operand_b;
            end
            AND: begin
                result = operand_a & operand_b;
                carry_flag = 'x;
            end
            OR: begin
                result = operand_a | operand_b;
                carry_flag = 'x;
            end
            XOR: begin
                result = operand_a ^ operand_b;
                carry_flag = 'x;
            end
            INV: begin
                result = ~operand_a;
                carry_flag = 'x;
            end
            default: begin
                result = 'x;
                carry_flag = 'x;
            end
        endcase
    end

    always_comb begin
        if (alu_func == ADD) begin
            signed_overflow = (operand_a[DATA_W-1] == operand_b[DATA_W-1]) && (result[DATA_W-1] != operand_a[DATA_W-1]);
        end else if (alu_func == SUB) begin
            signed_overflow = (operand_a[DATA_W-1] != operand_b[DATA_W-1]) && (result[DATA_W-1] != operand_a[DATA_W-1]);
        end else begin
            signed_overflow = 'x; // Not applicable for other operations
        end
        zero_flag = (result == '0);
        positive_flag = ~result[DATA_W-1]; // Positive if MSB is 0 (not negative)
    end

    assign alu_result = output_enable ? result : 'z;
endmodule: alu

`endif // ALU
