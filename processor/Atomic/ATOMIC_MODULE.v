`timescale 1ns / 1ps
`include "constants.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2025 09:50:40 AM
// Design Name: 
// Module Name: ATOMIC_MODULE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The atomic module to be placed in the MEM stage. Contains a small ALU for the binary operations (so we wouldnt need
//              to go back to EXE stage)
//              i_is_atomic - signal from ID stage if instruction is Atomic. Serves as enable signal
//              i_opA, i_opB - input operands. One from memory, one from register file
//              funct5 - 5 bits telling the binary op
//
//              Also functions as the interface to the On-Chip memory
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ATOMIC_MODULE
    #(
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    input i_wr,
    input i_rd,
    input i_is_atomic,
    
    input [31:0] i_data_from_core,  // Data to be sent to OCM
    input [31:0] i_data_from_OCM,
    input [ADDR_BITS-1:0] i_addr,
    input [3:0] i_dm_write,
    input [4:0] i_atomic_op,
    input i_grant,
    
    input [31:0] i_opB,                    // RS2 if Atomic
    
    output [31:0] o_data_to_OCM,
    output [ADDR_BITS-1:0] o_addr, 
    output [3:0] o_dm_write,
    output [31:0] o_data_to_WB,     // to Writeback stage
    output o_request,
   
    output o_done,          
    output o_stall_atomic
    );
    
    reg [31:0] res;
    reg [31:0] temp;
    
    
    // FSM of the module.
    // If instruction is atomic, stall the IF, ID, and EXE stage for 2 cycles (load, modify and store)
    // State:
    // 2'd0 S_IDLE
    // 2'd1 S_WAIT - wait for memory resources to be free
    // 2'd2 S_WORK - load and modify
    // 2'd3 S_DONE - store back the results, free the resource, from DONE we can jump back to wait and bypass IDLE
    reg [1:0] state;
    localparam S_IDLE = 2'd0;
    localparam S_WAIT = 2'd1;
    localparam S_WORK = 2'd2;
    localparam S_DONE = 2'd3;
    
    initial begin
        state <= S_IDLE;
    end
    
    always @ (posedge clk) begin
        if (!nrst) begin
            state <= S_IDLE;
            temp <= 0;
            res <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (i_is_atomic || i_wr || i_rd) state <= S_WAIT;
                end 
                
                S_WAIT: begin
                    if (i_grant && i_is_atomic) state <= S_WORK;
                    else if (i_grant && !i_is_atomic) state <= S_DONE;
                    
                end
                
                S_WORK: begin
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    if (i_is_atomic) state <= S_WAIT; // bypass IDLE state 
                    else state <= S_IDLE;
                end
            endcase
            
            if (i_is_atomic && (state == S_WORK)) begin
                temp <= i_data_from_OCM;
            end
            
            
            
        end
        
    end
    
    // Small ALU module for binary operation
    // 5 bits to tell the operation
    // amoadd - 00000
    // amoswap - 00001
    // amoxor - 00100
    // amoand - 01100
    // etc
    
    always @ (*) begin
        case (i_atomic_op) 
            4'd2: res <= temp + i_opB;
            4'd1: res <= i_opB;
            4'd3: res <= temp ^ i_opB;
            4'd4: res <= temp & i_opB;
            4'd5: res <= temp | i_opB;
            default: res <= 0;
            // to follow: minimum and maximums;
        endcase
    end
    
    assign o_done = (state == S_DONE) ? 1'b1 : 1'b0;
    assign o_request = (i_is_atomic || i_wr || i_rd);
    assign o_data_to_OCM = (i_is_atomic) ? res : i_data_from_core;
    assign o_dm_write = (state == S_DONE && i_is_atomic) ? 4'b1111 : i_dm_write;
    assign o_data_to_WB = (state == S_DONE && i_is_atomic) ? temp : 
                (state == S_DONE && !i_is_atomic) ? i_data_from_OCM : 0;
    assign o_addr = i_addr;
    assign o_stall_atomic = (state == S_WORK || state == S_WAIT) ? 1'b1 : 1'b0;
endmodule
