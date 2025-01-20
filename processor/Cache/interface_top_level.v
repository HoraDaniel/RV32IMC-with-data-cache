`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/08/2025 12:32:02 PM
// Design Name: 
// Module Name: interface_top_level
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top level for synthesis and post-synthesis timing simulation
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module interface_top_level
    #
    (
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    input [ADDR_BITS-1:0]   i_testbench_addr,
    input [ADDR_BITS-1:0]   i_base_addr,
    input                   i_sample_signal,
    input                   i_refill_en,
    input                   ready_mm,
    output                  o_done,
    output  [127:0]         o_data_block,
    output [31:0]           o_testbench_data
    
    );
    
    
    
    wire done;
    assign o_done = done;
    
    wire [ADDR_BITS-1:0] addr_to_mem;
    wire [31:0] data_from_mem;

    refill_controller #(.ADDR_BITS(ADDR_BITS))
        refill_cont (
            .clk(clk),     .nrst(nrst),
            .i_base_addr(i_base_addr[ADDR_BITS-1:2]), .i_data_from_mem(data_from_mem),
            .i_sample_signal(i_sample_signal), .i_refill_en(i_refill_en),
            .ready_mm(ready_mm), .o_data_block(o_data_block),
            .o_addr_to_mem(addr_to_mem),
            .o_done(done)
            
        );
    
    dual_port_bram #(.ADDR_WIDTH(ADDR_BITS))
        BRAM(
            .clkA(clk),
            .enaA(1'b1),
            .addrA(addr_to_mem),
            .doutA(data_from_mem)
            
            

        );
endmodule
