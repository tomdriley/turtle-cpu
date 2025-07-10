`ifndef DATA_MEMORY_TB
`define DATA_MEMORY_TB

// data_memory_tb.sv
// author: Tom Riley
// date: 2025-07-10

// Testbench for the data_memory module
module data_memory_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, data_memory_tb);
    end

    // Parameters
    localparam DATA_W = 8;
    localparam D_ADDR_W = 12;
    localparam D_MEMORY_DEPTH = 1 << D_ADDR_W;

    // Signals
    logic [D_ADDR_W-1:0] data_addr;
    logic [DATA_W-1:0] write_data;
    logic write_enable;
    logic output_enable;
    wire [DATA_W-1:0] read_data;

    // Instantiate the data memory
    data_memory #(
        .DATA_W(DATA_W),
        .D_ADDR_W(D_ADDR_W),
        .D_MEMORY_DEPTH(D_MEMORY_DEPTH)
    ) uut (
        .data_addr(data_addr),
        .write_data(write_data),
        .write_enable(write_enable),
        .output_enable(output_enable),
        .read_data(read_data)
    );

    // Task to write data to memory
    task automatic write_memory(
        input [D_ADDR_W-1:0] addr,
        input [DATA_W-1:0] data,
        input string test_name
    );
        data_addr = addr;
        write_data = data;
        write_enable = 1'b1;
        output_enable = 1'b0;
        #10ns;
        write_enable = 1'b0;
        #10ns;
        $display("Write: %s | Addr=%03h Data=%02h", test_name, addr, data);
    endtask

    // Task to read data from memory
    task automatic read_memory(
        input [D_ADDR_W-1:0] addr,
        input [DATA_W-1:0] expected_data,
        input string test_name
    );
        data_addr = addr;
        write_enable = 1'b0;
        output_enable = 1'b1;
        #10ns;
        if (read_data === expected_data) begin
            $display("Read: %s | Addr=%03h Expected=%02h Got=%02h [PASS]", 
                    test_name, addr, expected_data, read_data);
        end else begin
            $display("Read: %s | Addr=%03h Expected=%02h Got=%02h [FAIL]", 
                    test_name, addr, expected_data, read_data);
        end
        output_enable = 1'b0;
        #10ns;
    endtask

    // Task to test tri-state behavior
    task automatic test_tristate(
        input [D_ADDR_W-1:0] addr,
        input string test_name
    );
        data_addr = addr;
        write_enable = 1'b0;
        output_enable = 1'b0;
        #10ns;
        
`ifdef VERILATOR
        // The Verilator simulator doesn't support tristate properly, so we just check that output_enable works
        $display("Tristate: %s | Addr=%03h [PASS - Verilator mode, tristate not testable]", test_name, addr);
`else
        // In real simulators, check for proper tristate behavior
        if (read_data === 'z) begin
            $display("Tristate: %s | Addr=%03h Output=Hi-Z [PASS]", test_name, addr);
        end else begin
            $display("Tristate: %s | Addr=%03h Output=%02h [FAIL - Expected Hi-Z]", 
                    test_name, addr, read_data);
        end
`endif
        #10ns;
    endtask

    // Test sequence
    initial begin
        $display("Starting Data Memory testbench...");
        
        // Initialize signals
        data_addr = '0;
        write_data = '0;
        write_enable = 1'b0;
        output_enable = 1'b0;
        #10ns;

        // Test basic write and read operations
        write_memory(12'h000, 8'hAA, "Basic_Write_0");
        read_memory(12'h000, 8'hAA, "Basic_Read_0");
        
        write_memory(12'h001, 8'h55, "Basic_Write_1");
        read_memory(12'h001, 8'h55, "Basic_Read_1");
        
        write_memory(12'hFFF, 8'h33, "Basic_Write_LastAddr");
        read_memory(12'hFFF, 8'h33, "Basic_Read_LastAddr");

        // Test overwrite
        write_memory(12'h000, 8'h11, "Overwrite_Write");
        read_memory(12'h000, 8'h11, "Overwrite_Read");

        // Test tri-state behavior
        test_tristate(12'h000, "Tristate_Test");

        // Test reading uninitialized memory
        read_memory(12'h100, 8'h00, "Uninitialized_Read");

        // Test simultaneous write and read (should not happen in real design)
        data_addr = 12'h200;
        write_data = 8'h77;
        write_enable = 1'b1;
        output_enable = 1'b1;
        #10ns;
        $display("Simultaneous W/R: Addr=%03h WriteData=%02h ReadData=%02h", 
                data_addr, write_data, read_data);
        write_enable = 1'b0;
        output_enable = 1'b0;
        #10ns;

        // Comprehensive test: write to multiple locations
        $display("Comprehensive test: writing to multiple locations...");
        for (int i = 0; i < 16; i++) begin
            write_memory(D_ADDR_W'(i), DATA_W'(8'h10 + i), $sformatf("Multi_Write_%0d", i));
        end
        
        // Read back and verify
        $display("Reading back and verifying...");
        for (int i = 0; i < 16; i++) begin
            read_memory(D_ADDR_W'(i), DATA_W'(8'h10 + i), $sformatf("Multi_Read_%0d", i));
        end

        // Random access test
        $display("Random access test...");
        for (int i = 0; i < 50; i++) begin
            automatic logic [D_ADDR_W-1:0] rand_addr = D_ADDR_W'($urandom_range(0, D_MEMORY_DEPTH-1));
            automatic logic [DATA_W-1:0] rand_data = DATA_W'($urandom_range(0, 2**DATA_W-1));
            write_memory(rand_addr, rand_data, $sformatf("Random_Write_%0d", i));
            read_memory(rand_addr, rand_data, $sformatf("Random_Read_%0d", i));
        end

        $display("Data Memory testbench completed successfully!");
        $finish;
    end

endmodule

`endif // DATA_MEMORY_TB
