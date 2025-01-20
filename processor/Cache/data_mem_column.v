`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/30/2024 03:51:34 PM
// Design Name: 
// Module Name: data_mem_column
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The idea is to separate each column per offset (i.e. 4 columns so 4 of these). Let us make them dual port. One port for core, and another 
//              to mem
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module data_mem_column
    #
    (
    parameter INDEX_BITS = 3
    )
    (
    
    input clk,

    
    
    input [INDEX_BITS-1:0]      i_index,
    input [3:0]                 i_dm_write,           
    input                       i_weA,           // write enable from core
    input                       i_weB,           // write enable from mem
    input [31:0]                i_data_from_core,
    input [31:0]                i_data_from_mem,
    output [31:0]               o_data
    );
    
    
    localparam NUM_SETS = 1 << INDEX_BITS;
    localparam NUM_COL = 4;
    localparam COL_WIDTH = 8;
    
    // Core memory
    reg [31:0] data_mem[NUM_SETS-1:0];
    reg [31:0] data_out;
    assign o_data = data_mem[i_index];
    

    
    // Synchronous reads
    integer i;
    always @ (posedge clk) begin
            data_out <= data_mem[i_index];
            if (i_weA) begin
                for(i=0;i<NUM_COL;i=i+1) begin
                        if(i_dm_write[i]) begin
                            data_mem[i_index][i*COL_WIDTH +: COL_WIDTH] <= i_data_from_core[i*COL_WIDTH +: COL_WIDTH];
                        end
                end 
            end 
            
            
            if (i_weB) begin
                data_mem[i_index] <= i_data_from_mem;
            end
    end
    
    
endmodule
