`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2025 11:15:00 AM
// Design Name: 
// Module Name: MEM_ADDR_ROUTE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: If address falls into cacheable regions, then redirect the address and request to L1 Data Cache
//              Else if address falls into non-cacheable region, direc the address to OCM
//              Non-cacheable data: flags, locks, and protocol memory registers
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MEM_ADDR_ROUTE#
    (
    parameter ADDR_BITS = 12
    )
    (
    input [ADDR_BITS-1:0] i_addr,
    input [31:0] i_data,
    input  i_is_atomic,
    input [3:0] i_dm_write,
    input  i_wr,
    input  i_rd,
    
    
    // port to L1 Data Cache
    output reg [ADDR_BITS-1:0] o_addr_to_cache,
    output reg o_atomic_lock_to_cache, // prolly will be unused
    output reg [3:0] o_dm_write_to_cache,
    output reg o_wr_to_cache,
    output reg o_rd_to_cache,
    output reg [31:0] o_data_to_cache,
    
    // port to OCM
    output reg [ADDR_BITS-1:0] o_addr_to_OCM,
    output reg [3:0] o_dm_write_to_OCM,
    output reg o_atomic_lock_to_OCM,
    output reg o_wr_to_OCM,
    output reg o_rd_to_OCM,
    output reg [31:0] o_data_to_OCM, 
    
    output o_to_OCM,
    output o_to_cache
    );
    
    // Regions
    localparam ONCHIP_MEM_END = 32'h00000FFF; // Non cacheable region
    // So anything above this is cacheable???    
    //
    
    wire to_OCM;
    wire to_cache;
    
    assign to_OCM = (i_addr <= ONCHIP_MEM_END && (i_rd || i_wr || i_is_atomic)) ? 1'b1 : 1'b0;
    assign to_cache = ~to_OCM;
    assign o_to_OCM = to_OCM;
    assign o_to_cache = to_cache;
    always @ (*) begin
        if (to_OCM) begin
            o_addr_to_OCM <= {2'b00, i_addr[ADDR_BITS-1:2]};
            o_wr_to_OCM <= i_wr;
            o_rd_to_OCM <= i_rd;
            o_dm_write_to_OCM <= i_dm_write;
            o_data_to_OCM <= i_data;

            
            o_addr_to_cache <= 0;
            o_dm_write_to_cache <= 0;
            o_wr_to_cache <= 0;
            o_rd_to_cache <= 0;
            o_data_to_cache <= 0;

        end
        else if (to_cache) begin
            o_addr_to_cache <= i_addr;
            o_dm_write_to_cache <= i_dm_write;
            o_wr_to_cache <= i_wr;
            o_rd_to_cache <= i_rd;
            o_data_to_cache <= i_data;

            
            o_addr_to_OCM <= 0;
            o_wr_to_OCM <= 0;
            o_rd_to_OCM <= 0;
            o_dm_write_to_OCM <= 0;
            o_data_to_OCM <= 0;

        end
    end
    
    
endmodule
