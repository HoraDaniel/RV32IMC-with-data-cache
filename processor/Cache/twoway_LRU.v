`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/29/2024 06:43:25 PM
// Design Name: 
// Module Name: twoway_LRU
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


module twoway_LRU(
    input nrst,
    input [1:0] i_way_accessed,
    input i_hit,
    
    output reg [1:0] o_LRU
    );
    
    // ============= Assigning registers ======== //
    reg plru_bit; // holds the MRU ( why the name tho? I dunno) 
    
     // ============= Logic ======================= //
     always @ (*) begin
        if (!nrst) plru_bit <= 1'b1;
        if (i_hit) begin
            case (i_way_accessed)
                2'b01: begin
                    plru_bit <= 0;
                end
                
                2'b10: begin
                    plru_bit <= 1;
                end    
            endcase
        end    
     end
    
    
    always @ (*) begin
        //output PLRU
        if (plru_bit) o_LRU <= 2'b01;
        else o_LRU <= 2'b10;
    end
    
    
endmodule
