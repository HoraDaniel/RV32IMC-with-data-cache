`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2025 09:16:09 AM
// Design Name: 
// Module Name: cache_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The input-output ports should match the datamem block of the RISC V core
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cache_top
    #(
    parameter CACHE_WAY = 4,
    parameter CACHE_SIZE = 4096, // bytes
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    
    // Inputs from the RISCV core
	input [3:0]            i_dm_write,  // bytewise write
	input                  i_rd,
	input                  i_wr,
	input [ADDR_BITS-1:0]  i_data_addr,
	input [31:0]           i_data,
	input                  i_ready_mm,
	
	// Outputs
	output [31:0]          o_data,	// data output to the RISC-V core
	output                 o_all_done,

    // Cache specific output
    output                 o_stall

    );
    wire clk_inv = ~clk; // what

    // parameters
    // one word = 32-bits or 4 bytes
    localparam OFFSET_BITS = 2;
    localparam BLOCK_SIZE = 16; // 16 bytes per one block (4 words), always
    localparam NUM_BLOCKS = CACHE_SIZE / BLOCK_SIZE;
    localparam NUM_SETS = NUM_BLOCKS / CACHE_WAY;
    localparam INDEX_BITS = $clog2(NUM_SETS);
    localparam TAG_BITS = ADDR_BITS - INDEX_BITS - OFFSET_BITS - 2;
    
    wire [OFFSET_BITS-1:0]  offset;
    wire [TAG_BITS-1:0]     tags;
    wire [INDEX_BITS-1:0]   index;
    
    wire [CACHE_WAY-1:0] hit_way;
    wire [CACHE_WAY-1:0] lru_way;   
    
    // control signals
    // Tag array and data Array
    wire wetag;
    wire hit;
    wire modify;
    wire refill_en;
    wire done_mm;
    wire done_evict;
    wire sample_en;
    wire sample_addr;
    wire evict_en;
    wire [3:0] weB;
    
    
    // Refills and eviction
    wire [TAG_BITS+1:0] LRU_set_tag_info;
    wire [ADDR_BITS-1:0] addr_to_memA;
    wire [ADDR_BITS-1:0] addr_to_memB;
    wire [ADDR_BITS-5:0] evicted_base_addr;
    wire [31:0] data_from_memA;
    wire [31:0] data_to_memB;
    wire [127:0] data_block_from_mem;
    wire [127:0] data_block_to_mem;

    // change into little endian mode
    wire [31:0] data_in_little_e = {i_data[7:0], i_data[15:8], i_data[23:16], i_data[31:24]};
    // Instantiate the Tag Array
    tag_array #(.TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS), .CACHE_WAY(CACHE_WAY))
        tag_array(
            .clk(clk),                  .nrst(nrst),
            .i_wr_en(wetag),            .i_tag(tags),
            .i_index(index),            .i_LRU_set(lru_way),
            .i_invalidate(),            .i_modify(modify),
            .i_reserve_exclusive(), 
            
            .o_way(hit_way),
            .o_hit(hit),
            .o_LRU_set_tag_info(LRU_set_tag_info)
        );
    
    
    // Instantiate the Cache Controller
    cache_controller #(.CACHE_WAY(CACHE_WAY), .ADDR_WIDTH(ADDR_BITS), .TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS), .OFFSET_BITS(OFFSET_BITS))
        controller (
            .clk(clk),              .nrst(nrst),
            .i_addr(i_data_addr),   .i_hit(hit),
            .i_readymm(i_ready_mm),           .i_rd(i_rd),
            .i_wr(i_wr),                .i_way_accessed(hit_way),
            .i_LRU_set_tag_info(LRU_set_tag_info),
            .i_done_mm(done_mm),
            
            .o_tag(tags),           .o_index(index),
            .o_offset(offset),      .o_byte_offset(),
            .o_modify(modify),      .o_wetag(wetag),
            .o_LRU(lru_way),
            
            
            .o_refill_en(refill_en),
            .o_sample_data(sample_en),
            .o_sample_addr(sample_addr),
            .o_evict_en(evict_en),
            .o_addr_evicted(evicted_base_addr),
            
            .o_all_done(o_all_done),
            .o_stall(o_stall)
        );
    
    
    // Instantiate the Data Array
    data_array #(.CACHE_WAY(CACHE_WAY), .INDEX_BITS(INDEX_BITS))
        data_array (
            .clk(clk),
            .i_wr(i_wr),
            .i_rd(i_rd),
            .i_index(index), .i_offset(offset),
            .i_dm_write(i_dm_write),
            .i_data_from_mem_valid(done_mm),
            .i_data_from_core(data_in_little_e),
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
            .i_refill_en(refill_en),  .ready_mm(i_ready_mm),
            
            .o_data_block(data_block_from_mem), .o_addr_to_mem(addr_to_memA),
            .o_done(done_mm)
        );
        
     
     // Instantiate the Eviction Controller
     eviction_controller #(.ADDR_BITS(ADDR_BITS))
        evict_cont (
            .clk(clk),                          .nrst(nrst),
            .i_sample_signal(sample_en),        .i_evict_en(evict_en),
            .ready_mm(i_ready_mm),              .i_evicted_block(data_block_to_mem),
            .i_base_addr(evicted_base_addr),    .o_addr_to_bram(addr_to_memB),
            .o_data_to_bram(data_to_memB),       .o_done(done_evict),
            .o_write_signal(weB)
        );
     
        
     // Instantiate the BRAM
     // for now
     dual_port_bram # (.ADDR_WIDTH(ADDR_BITS))
        bram(
            // PORT A - refills
            .clkA(clk),
            .enaA(1'b1),
            .weA(4'b0),
            .addrA(addr_to_memA),
            .doutA(data_from_memA),
            
            
            .clkB(clk),
            .enaB(1'b1),
            .weB(weB),
            .addrB(addr_to_memB),
            .dinB(data_to_memB)
            
        );
endmodule
