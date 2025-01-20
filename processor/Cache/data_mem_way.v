`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/30/2024 05:11:37 PM
// Design Name: 
// Module Name: data_mem_way
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: One way of the data array. Each way consists of 4 data_mem_columns for 4 words per block
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module data_mem_way
    # (
    parameter INDEX_BITS = 3
    )
    (
    input clk,
    input                   i_wr,
    input                   i_am_LRU,
    input                   i_data_from_mem_valid,
    input [31:0]            i_data_from_core,
    input [127:0]           i_data_from_mem,        // The entire block for refills
    input                   i_hit,
    input [INDEX_BITS-1:0]  i_index,
    input [1:0]             i_offset,
    input [3:0]             i_dm_write,
    output reg [31:0]       o_out_way,
    output [127:0]          o_block                 // The entire block for eviction
    );
    
    wire [31:0] output_column[3:0];
    wire [31:0] data_from_mem_n [3:0];
    reg [3:0] we_bus;
    reg [31:0] r_data_o;
    
    assign o_block = (i_am_LRU) ? { output_column[3], output_column[2], output_column[1], output_column[0] } : 128'b0;
    // parse each data_from_mem
    assign data_from_mem_n[3] = i_data_from_mem[31:0];
    assign data_from_mem_n[2] = i_data_from_mem[63:32];
    assign data_from_mem_n[1] = i_data_from_mem[95:64];
    assign data_from_mem_n[0] = i_data_from_mem[127:96];
    
    
    genvar i;
    generate 
    
    // generate four columns
        for (i = 0; i < 4; i = i + 1) begin
            data_mem_column #(.INDEX_BITS(INDEX_BITS))
                data_column (.clk(clk), .i_index(i_index), .i_weA(we_bus[i] && i_wr && i_hit && !i_data_from_mem_valid), 
                    .i_dm_write(i_dm_write),
                    .i_data_from_mem(data_from_mem_n[i]), .i_weB(i_hit && i_data_from_mem_valid),
                    .i_data_from_core(i_data_from_core), .o_data(output_column[i]));
        end
    endgenerate
    
    always @ (*) begin
        case (i_offset)
            2'b00: begin
                we_bus <= 4'b0001;
                o_out_way <= output_column[0];
            end            
            2'b01: begin
                we_bus <= 4'b0010;
                o_out_way <= output_column[1];
            end
            2'b10: begin
                we_bus <= 4'b0100;
                o_out_way <= output_column[2];
            end
            
            2'b11: begin
                we_bus <= 4'b1000;
                o_out_way <= output_column[3];
            end
        endcase
    end
    

endmodule
