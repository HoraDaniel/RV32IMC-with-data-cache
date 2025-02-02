`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/29/2025 09:42:06 AM
// Design Name: 
// Module Name: OCM_INTERFACE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The interface of a Core an the On-Chip Memory. Controlls the stall. 
//              Different 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OCM_INTERFACE
    #(parameter ADDR_BITS = 12)
    (
    input clk,
    input nrst,
    
    input i_grant,
    input i_rd,
    input i_wr,
    
    output o_req,
    output o_stall
    
    
     
    );
    
    // FSM handles the stall if necessary
    
    reg [1:0] state;
    
    localparam S_IDLE = 2'd0;
    localparam S_WAIT = 2'd1;
    localparam S_DONE = 2'd2;
    
    
    always @ (posedge clk) begin
        if (!nrst) state <= S_IDLE;
        else begin
            case (state) 
            
                S_IDLE: begin 
                    if (i_rd || i_wr) state <= S_WAIT;
                    
                end
                
                S_WAIT: begin
                    if (i_grant) state <= S_DONE;
                end
                
                S_DONE: begin
                    if (i_rd || i_wr) state <= S_WAIT;
                    else state <= S_IDLE;
                
                end
                default: state <= S_IDLE;
            endcase 
            
        end
        
    end
    
    assign o_stall = (state == S_WAIT) ? 1'b1 : 1'b0;
    assign o_done = (state == S_DONE) ? 1'b1 : 1'b0;
    assign o_req = (i_rd | i_wr);
endmodule
