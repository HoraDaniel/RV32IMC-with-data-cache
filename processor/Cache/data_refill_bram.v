`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2025 06:18:07 PM
// Design Name: 
// Module Name: data_refill_bram
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


module data_refill_bram
    #(
    parameter INDEX_BITS = 5,
    parameter CACHE_WAY = 2,
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    input i_wr,
    input i_rd,
    input [ADDR_BITS-1:0] i_data_addr,
    input [INDEX_BITS-1:0] index,
    input [1:0] offset,
    input [31:0] i_data,

    input [CACHE_WAY-1:0] hit_way,
    input [CACHE_WAY-1:0] lru_way,
    
    input sample_addr,
    input refill_en,
    input ready_mm,
    
    
    
    output [31:0] o_data,
    output [127:0] data_block,
    output done,
    output [2:0] counter
    );
    
    wire [127:0] data_block_to_mem;
    wire [31:0] data_from_memA;
    wire [ADDR_BITS-1:0] addr_to_memA;
    wire [127:0] data_block_from_mem; 
    wire done_mm;

       // Instantiate the Data Array
    data_array #(.CACHE_WAY(CACHE_WAY), .INDEX_BITS(INDEX_BITS))
        data_array (
            .clk(clk),
            .i_wr(i_wr),
            .i_rd(i_rd),
            .i_index(index), .i_offset(offset),
            .i_data_from_mem_valid(done_mm),
            .i_data_from_core(i_data),
            .i_data_from_mem(data_block_from_mem),
            .i_way(hit_way),
            .i_LRU(lru_way),
            
            .o_data_to_core(o_data),
            .o_block_to_mem(data_block_to_mem)
        );
    

    
    // Instantiate the Refill Controller
    refill_controller #(.ADDR_BITS(ADDR_BITS))
        refill_cont (
            .clk(clk),      .nrst(nrst),
            .i_base_addr(i_data_addr[ADDR_BITS-1:4]),  .i_data_from_mem(data_from_memA),
            .i_sample_signal(sample_addr),
            .i_refill_en(refill_en),  .ready_mm(ready_mm),
            
            .o_data_block(data_block_from_mem), .o_addr_to_mem(addr_to_memA),
            .o_done(done_mm),
            .counter_probe(counter)
        );
        
         // Instantiate the BRAM
     // for now
     dual_port_bram # (.ADDR_WIDTH(ADDR_BITS))
        bram(
            // PORT A - refills
            .clkA(clk),
            .enaA(1'b1),
            .addrA(addr_to_memA),
            .doutA(data_from_memA)
            
        );
        
        assign data_block = data_block_from_mem;
        assign done = done_mm;
endmodule
