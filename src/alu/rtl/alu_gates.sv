`ifndef ALU_GATES
`define ALU_GATES

// alu_gates.sv
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
    logic [DATA_W-1:0] invert_b;
    logic [DATA_W-1:0] second_summand;
    logic [DATA_W:0] sum;
    logic carry_in;
    logic result_sign_not_match_a;
    logic a_sign_not_match_b;

    assign invert_b = ~operand_b;
    assign second_summand = alu_func[0] ? invert_b : operand_b;
    assign carry_in = alu_func[0];
    assign sum = operand_a + second_summand + carry_in;
    assign carry_flag = sum[DATA_W]; // Carry out is the MSB of the sum
    assign result_sign_not_match_a = (result[DATA_W-1] != operand_a[DATA_W-1]);
    assign a_sign_not_match_b = (operand_a[DATA_W-1] != operand_b[DATA_W-1]);

    assign result = (
        alu_func[2]
        ? alu_func[1]
            ? ~operand_a // NOT operation
            : alu_func[0]
                ? operand_a ^ operand_b // XOR operation
                : operand_a | operand_b // OR operation
        : alu_func[1]
            ? operand_a & operand_b // AND operation
            : sum[DATA_W-1:0] // ADD/SUB operation
    ); 

    always_comb begin
        signed_overflow = result_sign_not_match_a & ~(a_sign_not_match_b ^ (alu_func[0]));
        zero_flag = (result == '0);
        positive_flag = ~result[DATA_W-1]; // Positive if MSB is 0 (not negative)
    end

    assign alu_result = output_enable ? result : 'z;
endmodule: alu

`endif // ALU_GATES
