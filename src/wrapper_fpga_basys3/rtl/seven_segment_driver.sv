`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2026 04:29:23 PM
// Design Name: 
// Module Name: seven_segment_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_segment_driver(
    input  logic       clk,
    input  logic       reset_n,

    input  logic [3:0] dig[3:0],   // 4 hex digits to display

    output logic [6:0] seg,        // common-anode encoding (active-low segments)
    output logic [3:0] an          // active-low anodes
);

    // Tick every (CLK / (REFRESH_RATE_HZ)) cycles for per-digit rate
    localparam int TICK_CYCLES = 200_000;
    localparam int ON_CYCLES = TICK_CYCLES * 0.125; // Adjusts brightnessS
    localparam int CNT_W       = $clog2(TICK_CYCLES);

    logic [CNT_W-1:0] cnt;
    logic             tick;
    logic             digit_off_tick;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            cnt  <= '0;
            tick <= 1'b0;
            digit_off_tick <= 1'b0;
        end else begin
            if (cnt == TICK_CYCLES-1) begin
                cnt  <= '0;
                tick <= 1'b1;
            end else begin
                cnt  <= cnt + 1'b1;
                tick <= 1'b0;
            end

            if (cnt == ON_CYCLES) begin
                digit_off_tick <= 1;
            end
            else begin
                digit_off_tick <= 0;
            end
        end
    end

    logic [1:0] digit_idx, next_digit_idx;
    logic [3:0] next_an;
    logic [6:0] next_seg;
    
    // 7-seg encode (common anode, active-low segments)
    function automatic logic [6:0] enc7(input logic [3:0] v);
        unique case (v)
            4'h0: enc7 = 7'b1000000;
            4'h1: enc7 = 7'b1111001;
            4'h2: enc7 = 7'b0100100;
            4'h3: enc7 = 7'b0110000;
            4'h4: enc7 = 7'b0011001;
            4'h5: enc7 = 7'b0010010;
            4'h6: enc7 = 7'b0000010;
            4'h7: enc7 = 7'b1111000;
            4'h8: enc7 = 7'b0000000;
            4'h9: enc7 = 7'b0010000;
            4'hA: enc7 = 7'b0001000;
            4'hB: enc7 = 7'b0000011;
            4'hC: enc7 = 7'b1000110;
            4'hD: enc7 = 7'b0100001;
            4'hE: enc7 = 7'b0000110;
            4'hF: enc7 = 7'b0001110;
            default: enc7 = 7'b1111111;
        endcase
    endfunction

    assign next_digit_idx = digit_idx + 1;

    always_comb begin
        unique case (next_digit_idx)
            2'd0: next_an <= 4'b1110;
            2'd1: next_an <= 4'b1101;
            2'd2: next_an <= 4'b1011;
            2'd3: next_an <= 4'b0111;
        endcase
    end

    assign next_seg = enc7(dig[next_digit_idx]);
    
    // Drive an + seg coherently on the scan tick
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            digit_idx <= 2'd0;
            an        <= 4'b1110;       // enable digit 0 (active-low)
            seg       <= 7'b1111111;    // blank
        end else if (tick) begin
            digit_idx <= digit_idx + 2'd1;
            an        <= next_an;
            seg       <= next_seg;
        end
        else if (digit_off_tick) begin
            an <= 4'b1111;
        end
    end

endmodule: seven_segment_driver
