`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2025 08:36:51 AM
// Design Name: 
// Module Name: OCM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:     The On-Chip Memory (OCM) allocates a non-cacheable region in the data memory
//                  Primarily for the flags/CSRs of communication protocols (to be implemented)
//                  Direct Memory Access of protocol controllers
//                  Leverage for use in atomic locks, semaphores, and mutexes
//                  There's probably a more efficient way to do atomics, but this is the easiest one we can do
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OCM #(
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    
    // Core 1 signals and data
    input i_req_core_1,
    input i_done_core_1,
    output reg o_grant_core_1,
    input [31:0] i_data_core_1,
    input [3:0] i_dm_write_core_1,
    output [31:0] o_data_core_1,
    input [ADDR_BITS-1:0] i_addr_1,

    input [ADDR_BITS-1:0] addr_tb,
    output [31:0] out_tb,
    
    
    // Core 2 signals and data
    input i_req_core_2,
    input i_done_core_2,
    output reg o_grant_core_2,
    input [31:0] i_data_core_2,
    input [3:0] i_dm_write_core_2,
    output [31:0] o_data_core_2,
    input [ADDR_BITS-1:0] i_addr_2

    
    
    );
    
    
    
    // Implement an arbitration module
    // Signals
    // req_core_n - request signal from Core 1 or 2
    // grant_core_n - grant signal to Core 1 or 2
    // done_core_n - done signal from Core 1 or 2 
    
    // Arbitration strategy: Round Robin style (easiest and simplest)
    // per clock cycle, if there are no requests, cycle through the two cores giving each a fair chance
    
    reg current_grant; // 0 - grant core 1;     1 - grant core 2
    
    initial begin
    
        current_grant <= 0;
    
    end
    
    
    
    always @ (posedge clk) begin
        if (!nrst) begin
            current_grant <= 0;
        end else begin
        
            case (current_grant) 
                0: begin 
                    // Core 1 has grant
                    if (i_req_core_1) begin // core 1 is requesting while core 1 is given grant
                        
                        o_grant_core_1 <= 1;
                        o_grant_core_2 <= 0;
                        if (i_done_core_1) current_grant <= 1;
                    end else if (i_req_core_2) begin
                        // Core 2 requests instead,
                        o_grant_core_2 <= 1;
                        o_grant_core_1 <= 0;
                        current_grant <= 1;
                    end else begin 
                        // No cores are requesting
                        current_grant <= 1; // give the grant to core 2
                        o_grant_core_2 <= 0;
                        o_grant_core_1 <= 0;
                    end
                   
                end
                
                
                1: begin
                    // Core 2 has grant
                    if (i_req_core_2) begin

                        o_grant_core_2 <= 1;
                        o_grant_core_1 <= 0;
                        if (i_done_core_2) current_grant <= 0;
                    end else if (i_req_core_1) begin
                        o_grant_core_2 <= 0;
                        o_grant_core_1 <= 1;
                        current_grant <= 0;
                    end else begin
                        current_grant <= 0;
                        o_grant_core_2 <= 0;
                        o_grant_core_1 <= 0;
                    end
                    

                end
            endcase
        end
    end
    
    // stalls
     
    
    
    ///////////////////////////////////////////////////////////////////
    // The memory part
    wire [31:0] in_data_bus;
    wire [31:0] out_data_bus;
    wire [3:0] dm_wire;
    wire [ADDR_BITS-1:0] in_addr_bus;
    assign in_data_bus = (current_grant) ? i_data_core_2 : i_data_core_1;
    assign in_addr_bus = (current_grant) ? i_addr_2 : i_addr_1;
    assign dm_wire = (current_grant) ? i_dm_write_core_2 : i_dm_write_core_1;
    assign o_data_core_1 = (!current_grant) ? out_data_bus : prev_out_data_bus_1;
    assign o_data_core_2 = (current_grant) ? out_data_bus : prev_out_data_bus_2; 
    
    reg [31:0] prev_out_data_bus_1;
    reg [31:0] prev_out_data_bus_2;
    always @ (posedge clk) begin
        if (current_grant) prev_out_data_bus_2 <= out_data_bus;
        else prev_out_data_bus_1 <= out_data_bus;
    end
    
    // Instantiate the BRAM
    dual_port_ram_bytewise_write #(.ADDR_WIDTH(ADDR_BITS) )
        bram (
            // port A for cores
            .clkA(clk),
            .enaA(1'b1),
            .weA(dm_wire),
            .addrA(in_addr_bus),
            .dinA(in_data_bus),
            .doutA(out_data_bus),
            
            .clkB(clk),
            .enaB(1'b1),
            .addrB(addr_tb),
            .dinB(),
            .doutB(out_tb)
            
        
    );
    
endmodule
