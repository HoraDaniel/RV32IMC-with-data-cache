`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2024 06:16:25 PM
// Design Name: 
// Module Name: tag_mem
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


module tag_mem #(
    parameter TAG_BITS = 5,
    parameter INDEX_BITS = 3
    )(
    input clk,
    input nrst,
    input                       i_wr_en,
    input   [TAG_BITS-1:0]      i_tag,
    input   [INDEX_BITS-1:0]    i_index,
    input                       i_invalidate,
    input                       i_modify,
    input                       i_reserve_exclusive,
    input                       i_am_LRU,
    output  [TAG_BITS + 1:0]    o_tag,
    output                      o_hit
    );
    
    localparam NUM_SETS = 1 << INDEX_BITS;
    localparam TAG_BITS_WITH_LRU = TAG_BITS + 2;        //each entry: {2 bit MESI state + TAG}
    
    // 1D tag memory
    reg [TAG_BITS-1:0] tag_mem[NUM_SETS-1:0];

    // how about the MESI states tag?
    // We need to represent the MESI states
    // Invalid:     00
    // Shared:      01
    // Modified:    10
    // Exclusive:   11
    // bit 0 - stored in MESI_state_0;
    // bit 1 - stored in MESI_state_1;
    reg [NUM_SETS-1:0] MESI_state_0;
    reg [NUM_SETS-1:0] MESI_state_1;


    
    
    // ============ ASSIGN WIRES ====================//
    
    wire MESI_state_bit_0;
    wire MESI_state_bit_1;
    wire [1:0] MESI;
    wire valid;
    wire match;


    
    assign MESI_state_bit_0 = MESI_state_0[i_index];
    assign MESI_state_bit_1 = MESI_state_1[i_index];
    assign MESI = {MESI_state_bit_1, MESI_state_bit_0};
    assign o_tag = (i_am_LRU) ? {MESI, tag_mem[i_index]} : 0;
    
    assign valid = (MESI == 2'b00) ? 1'b0 : 1'b1;
    assign match = (tag_mem[i_index] == i_tag) ? 1'b1 : 1'b0;
    assign o_hit = (valid) ? (match ? 1'b1 : 1'b0) : 1'b0;
 
    integer i;
    initial begin
        MESI_state_0 <= 0;
        MESI_state_1 <= 0;
        for (i = 0; i < NUM_SETS; i = i+ 1) begin
            tag_mem[i] <= 0;
        end
    end
    
    // ============ SYNCHRONOUS READ ================//
    
    always @(posedge clk) begin
        if (!nrst) begin
           MESI_state_0 <= 0;
           MESI_state_1 <= 0;

           
        end
        else begin
            if (i_wr_en && i_am_LRU) begin
                tag_mem[i_index] <= i_tag;
                //shared
                MESI_state_0[i_index] <= 1'b1;
                MESI_state_1[i_index] <= 1'b0;
            end
            
            if (i_invalidate) begin
                MESI_state_0[i_index] <= 1'b0;
                MESI_state_1[i_index] <= 1'b0;
            end
            
            if (i_modify) begin
                MESI_state_0[i_index] <= 1'b0;
                MESI_state_1[i_index] <= 1'b1;
            end
            
            if (i_reserve_exclusive) begin
                MESI_state_0[i_index] <= 1'b1;
                MESI_state_1[i_index] <= 1'b1;
            end
           
            
        end
    end
    
    
    
    
endmodule
