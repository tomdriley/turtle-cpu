`ifndef ALU
`define ALU

// alu.sv
// author: Tom Riley
// date: 2025-07-05

module alu#(
    parameter int DATA_W = 8,
    localparam int ALU_FUNC_W = 3
)(
    // Inputs
    input   wire [DATA_W-1:0]       operand_a,
    input   wire [DATA_W-1:0]       operand_b,
    input   wire [ALU_FUNC_W-1:0]   alu_func,
    input   wire                    output_enable,
    // Outputs
    output  logic [DATA_W-1:0]      alu_result,
    output  logic                   zero_flag,
    output  logic                   positive_flag,
    output  logic                   carry_flag,
    output  logic                   signed_overflow
);
    /* verilator lint_off IMPORTSTAR */
    import alu_pkg::*;
    /* verilator lint_on IMPORTSTAR */

    logic [DATA_W-1:0] result;
    logic [DATA_W:0] diff_result;
    alu_func_e alu_func_enum = alu_func_e'(alu_func);

    always_comb begin
        case (alu_func_enum)
            ADD: begin
                {carry_flag, result} = operand_a + operand_b;
                diff_result = 'x;
            end
            SUB: begin
                diff_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = diff_result[DATA_W-1:0];
                carry_flag = ~diff_result[DATA_W]; // Borrow flag
            end
            AND: begin
                result = operand_a & operand_b;
                carry_flag = 'x;
                diff_result = 'x;

            end
            OR: begin
                result = operand_a | operand_b;
                carry_flag = 'x;
                diff_result = 'x;

            end
            XOR: begin
                result = operand_a ^ operand_b;
                carry_flag = 'x;
                diff_result = 'x;
            end
            INV: begin
                result = ~operand_a;
                carry_flag = 'x;
                diff_result = 'x;
            end
            default: begin
                result = 'x;
                carry_flag = 'x;
                diff_result = 'x;
            end
        endcase
    end

    always_comb begin
        if (alu_func_enum == ADD) begin
            signed_overflow = (operand_a[DATA_W-1] == operand_b[DATA_W-1]) && (result[DATA_W-1] != operand_a[DATA_W-1]);
        end else if (alu_func_enum == SUB) begin
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
