`ifndef TRISTATE_DRIVER_SV
`define TRISTATE_DRIVER_SV
    
// tristate_driver.sv
// author: Tom Riley
// date: 2026-01-01

module tristate_driver #(
    parameter int DATA_W=8
) (
    input  logic               en,
    input  logic [DATA_W-1:0]  d,
    output tri   [DATA_W-1:0]  bus
);
    assign bus = en ? d : 'z;
endmodule
    
`endif
