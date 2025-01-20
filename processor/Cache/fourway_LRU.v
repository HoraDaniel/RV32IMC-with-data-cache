`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2024 05:46:16 PM
// Design Name: 
// Module Name: fourway_LRU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module is the LRU controller to be instantiated if CACHE_WAY = 4;
//              This module's task is to take in the way accessed then update the LRU output on the tags
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fourway_LRU(
    input nrst,
    input [3:0] i_way_accessed, // one hot encoding input from way_hit
    input i_hit,
    output reg [3:0] o_LRU
    );
    
    // ============= Assigning registers ======== //
    reg [2:0] plru_bits; // points to the MRU (N-1 bits needed for N way)
    
    // ============= Assigning wires ============ //
    wire root = plru_bits[2];
    

    
    
    
    // ============= Logic ======================= //
    always@(*) begin
        if (!nrst) plru_bits <= 3'b111;
        // Convert way_accessed to plru_bits
        // when in doubt, brute-force your way out!
        if (i_hit) begin
            case (i_way_accessed) 
                4'b0001: begin
                    plru_bits[2] <= 1'b0;
                    plru_bits[1] <= 1'b0;  
                end
                
                4'b0010: begin
                    plru_bits[2] <= 1'b0;
                    plru_bits[1] <= 1'b1;  
                end
                
                4'b0100: begin
                    plru_bits[2] <= 1'b1;
                    plru_bits[0] <= 1'b0;  
                end
                
                4'b1000: begin
                    plru_bits[2] <= 1'b1;
                    plru_bits[0] <= 1'b1;  
                end
                default: begin
                    plru_bits[0] <= 1'b0;
                    plru_bits[1] <= 1'b0;
                    plru_bits[2] <= 1'b0;
                end  
            endcase
        end
       
    end
    
    
    always @ (*) begin
        // Output the LRU
        case (root)
            1'b1: begin // go left
                if (plru_bits[1]) o_LRU <= 4'b0001;
                else o_LRU <= 4'b0010;
            end 
            1'b0: begin // go right
                if (plru_bits[0]) o_LRU <= 4'b0100;
                else o_LRU <= 4'b1000;
            end
        endcase
    end
    
endmodule
