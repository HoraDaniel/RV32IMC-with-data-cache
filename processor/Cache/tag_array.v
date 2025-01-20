`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2024 12:39:02 PM
// Design Name: 
// Module Name: tag_array
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


module tag_array #
    (
    parameter TAG_BITS = 20,
    parameter INDEX_BITS = 3,
    parameter CACHE_WAY = 8
    )
    
    (
    input clk,
    input nrst,
    
    input                               i_wr_en,            // Enable tag writes
    
    input [TAG_BITS-1:0]                i_tag,
    input [INDEX_BITS-1:0]              i_index,
    
    input [CACHE_WAY-1:0]               i_LRU_set,                  //  Expects a One hot encoding from the PLRU module
    
    // MESI protocol
    input                               i_invalidate,
    input                               i_modify,
    input                               i_reserve_exclusive,
    
    output wire [CACHE_WAY-1:0]         o_way,              // one hot encoding to tell which way was accessed to the Data Array
    output                              o_hit,
    output wire [TAG_BITS + 1:0]        o_LRU_set_tag_info  // to Cache controller in case of eviction
    );
    
    
    // generate the correct number tag memory
    // based on the CACHE_WAY parameter
    wire [CACHE_WAY-1:0] hit_bus; // the packed outputs of the tag_mems
    wire [TAG_BITS+1:0] tag_output_mems[CACHE_WAY-1:0]; // output wires of tag infos for each tag mem
    
    
    reg [TAG_BITS + 1:0] lru_tag;
    
    assign o_way = hit_bus;
    assign o_LRU_set_tag_info = lru_tag;
    assign o_hit = |hit_bus;
    //assign o_LRU_set_tag_info = LRU_set_tag_info;
    genvar i;
    
    generate
        // i feel like this got more complicated when i was trying to simplify things

        for (i = 0; i < CACHE_WAY; i = i + 1) begin
            
            tag_mem #(.TAG_BITS(TAG_BITS), .INDEX_BITS(INDEX_BITS))
                small_tag_mem(
                    .clk(clk),  .nrst(nrst),
                    .i_wr_en(i_wr_en), .i_tag(i_tag), .i_index(i_index),
                    .i_invalidate(i_invalidate), .i_modify(i_modify && hit_bus[i]), .i_reserve_exclusive(i_reserve_exclusive),
                    .i_am_LRU(i_LRU_set[i]),
                    .o_tag(tag_output_mems[i]), .o_hit(hit_bus[i])
                );
                
        end
        
        
        
    endgenerate
    
    integer j;
    reg found;
    always @ (*) begin
        lru_tag = 0;
        found = 1'b0;
        for (j=0; j < CACHE_WAY; j = j + 1) begin
            if (i_LRU_set[j] == 1'b1 && !found) begin
                found = 1'b1;
                lru_tag = tag_output_mems[j];
            end 
        end
    end
    
    
    
endmodule
