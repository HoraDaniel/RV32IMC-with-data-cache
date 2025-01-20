`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2025 11:17:05 AM
// Design Name: 
// Module Name: eviction_controller
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


module eviction_controller
    #(
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    input i_sample_signal,
    input i_evict_en,
    input ready_mm,
    input [127:0] i_evicted_block,
    input [ADDR_BITS-5:0]                       i_base_addr,
    output [ADDR_BITS-1:0]                      o_addr_to_bram,
    output [31:0]                               o_data_to_bram,
    output reg                                  o_done,
    output [3:0]                            o_write_signal // 4'b1111 for a full word write
    );
    
    // Buffer to store the victim block
    reg [31:0] buffer[3:0];
    reg [ADDR_BITS-1:0] addr_buffer[3:0];
    
    //counter
    reg [1:0] counter;
    
    assign o_data_to_bram = buffer[counter];
    assign o_addr_to_bram = addr_buffer[counter];
    assign o_write_signal = (i_evict_en && ready_mm) ? 4'b1111 : 4'b0000;
    
    always @(posedge clk) begin
        if (!nrst) begin
            counter <= 0;
            buffer[0] <= 32'b0;
            buffer[1] <= 32'b0;
            buffer[2] <= 32'b0;
            buffer[3] <= 32'b0;
        end
        else begin
            if (i_sample_signal) begin
                // Sample the evicted block
                buffer[0] <= i_evicted_block[31:0];
                buffer[1] <= i_evicted_block[63:32];
                buffer[2] <= i_evicted_block[95:64];
                buffer[3] <= i_evicted_block[127:96];
                
                // Sample the address and generate addresses
                addr_buffer[0] <= {i_base_addr, 2'b00};
                addr_buffer[1] <= {i_base_addr, 2'b01};
                addr_buffer[2] <= {i_base_addr, 2'b10};
                addr_buffer[3] <= {i_base_addr, 2'b11};
            end
            
            if (ready_mm && i_evict_en) begin
                counter <= counter + 1;
                
            end
            
            if (counter == 2'b11) begin
                o_done <= 1'b1;
            end else o_done <= 1'b0;
            
            
        end
    end
endmodule
