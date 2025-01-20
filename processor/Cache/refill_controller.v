`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/08/2025 08:43:44 AM
// Design Name: 
// Module Name: refill_controller
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


module refill_controller
    #(
    parameter ADDR_BITS = 12
    )    
    (
    input clk,
    input nrst,
    input [ADDR_BITS-5:0]   i_base_addr,            // base address from the core.
    input [31:0]            i_data_from_mem,        // data from the next mem hierarchy. Do we make it 64 bits wide?
    input                   i_sample_signal,
    input                   i_refill_en,
    input                   ready_mm,
    output [127:0]          o_data_block,
    output  [ADDR_BITS-1:0]  o_addr_to_mem,
    output                 o_done,
    output [2:0]            counter_probe
    );
    
    wire clk_inv;
    assign clk_inv = ~clk;
    
    
    reg [31:0] refill_buffer_separate[3:0];
    
    // Buffer to store the data block
    // the buffer is parsed into:
    //  [31:0] word 0
    //  [63:32] word 1
    //  [95:64] word 3
    //  [127:96] word 4
    assign o_data_block = {refill_buffer_separate[0], refill_buffer_separate[1], refill_buffer_separate[2], refill_buffer_separate[3]};
    
    
       
    // Generate burst address for the BRAM
    reg first_clock_cycle;
    reg [ADDR_BITS-1:0] addrs [3:0];
    reg [1:0] counter;    
    
    assign o_addr_to_mem = (ready_mm) ? addrs[counter] : {ADDR_BITS{1'b0}};
    
    // Update counter
    always@(posedge clk_inv) begin 
        if (!nrst) begin
            first_clock_cycle <= 0;
            refill_buffer_separate[0] = 0;
            refill_buffer_separate[1] = 0;
            refill_buffer_separate[2] = 0;
            refill_buffer_separate[3] = 0;
            counter <= 0;
        end
        else begin
            if (!first_clock_cycle) first_clock_cycle <= 1;
            
            if (!i_refill_en) first_clock_cycle <= 0;
            
            if (i_sample_signal) begin
                counter <= 0;
                addrs[0] <= {i_base_addr,2'b00};
                addrs[1] <= {i_base_addr,2'b01};
                addrs[2] <= {i_base_addr,2'b10};
                addrs[3] <= {i_base_addr,2'b11};  
            end
            else if (i_refill_en && ready_mm) begin
                refill_buffer_separate[counter] <= i_data_from_mem;
                counter <= counter + 1;
            end
            else begin
                counter <= counter;
            end
        end
    end

    assign o_done = (counter == 2'b00 && first_clock_cycle) ? 1'b1 : 1'b0;
    assign counter_probe = counter;
    
endmodule
