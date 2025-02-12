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
    input [3:0] i_atomic_op,
    input i_grant,
    input i_data_valid,
    input i_data_write_valid,
    
    input [31:0] i_opB,                    // RS2 if Atomic
    
    output [31:0] o_data_to_OCM,
    output [ADDR_BITS-1:0] o_addr, 
    output [3:0] o_dm_write,
    output [31:0] o_data_to_WB,     // to Writeback stage
    output o_request,
   
    output o_done,          
    output  o_stall_atomic
    );
    
    wire initial_stall;
    reg r_stall;
    
    reg [31:0] res;
    reg [31:0] temp;

                                
                                
    // FSM of the module.
    // If instruction is atomic, stall the IF, ID, and EXE stage till phases are done
    // State:
    // 4'd0 S_IDLE - wait for operations and wait for memory resources to be free
    // 4'd1 S_GRANT - arbitrator gives grant to core; wait for valid signals
    // 4'd2 S_ATOMIC_VALID_READ - valid data received at ports; wait for valid write after doing atomic operations on data
    // 4'd3 S_ATOMIC_VALID_WRITE - confirmation that result is written in memory
    // 4'd4 S_ATOMIC_DONE - atomic operation is done
    //
    // 4'd5 S_BASIC_LOAD - if load operation at non-cacheable region, wait for valid data
    // 4'd6 S_BASIC_STORE - if write operation at non-cacheable region, wait for write confirmation
    // 4'd7 S_BASIC_LOAD_RESP - basic load is done. valid data available for WB stage
    // 4'd8 S_BASIC_WRITE_RESP - basic write is done. valid data is written at OCM
    // 4'd9 S_DONE - load/store operation done. Cleanup. 
    reg [3:0] state;
    localparam S_IDLE = 4'd0;
    localparam S_WAIT = 4'd1;
    localparam S_GRANT = 4'd2;
    localparam S_ATOMIC_VALID_READ = 4'd3;
    localparam S_ATOMIC_VALID_WRITE = 4'd4;
    localparam S_DONE = 4'd5;
    
    localparam S_BASIC_LOAD = 4'd6;
    localparam S_BASIC_STORE = 4'd7; 
    localparam S_BASIC_LOAD_RESP = 4'd8; 
    localparam S_BASIC_WRITE_RESP = 4'd9;

    
    initial begin
        state <= S_IDLE;
        r_stall <= 0;
    end
    
    // I had to change this to negedge clk because I couldn't figure out for the life of me to make this work 
    // in posedge clk.    
    always @ (negedge clk) begin
        if (!nrst) begin
            state <= S_IDLE;
            r_stall <= 0;
            temp <= 0;
            res <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if ( i_is_atomic || i_rd || i_wr) begin
                        state <= S_WAIT;
                        r_stall <= 1;
                    end 
                    else begin
                        state <= S_IDLE;
                    end
                end
                S_WAIT: begin
                    if (!(i_wr || i_rd || i_is_atomic)) begin
                        state <= S_IDLE; // go back to idle since we were wrong to enter here
                        r_stall <= 0;
                    end
                    if (( i_is_atomic || i_rd || i_wr) && i_grant) state <= S_GRANT;
                end
                S_GRANT: begin
                    // grant is given, wait for memory to complete the request
                    if (i_data_valid && i_is_atomic) begin
                        state <= S_ATOMIC_VALID_READ;
                        temp <= i_data_from_OCM;
                    end
                    else if (i_data_valid && i_rd) begin
                        state <= S_BASIC_LOAD;
                        temp <= i_data_from_OCM;
                    end
                    
                    else if (i_data_write_valid && i_wr) begin
                        state <= S_BASIC_STORE;
                        
                    end
                    else state <= S_GRANT;
                end
                
                S_ATOMIC_VALID_READ: begin
                    // do the work and operatin
                    // wait for valid writes
                    if (i_data_write_valid && i_is_atomic) begin
                        state <= S_ATOMIC_VALID_WRITE;
                    end
                end
                
                S_ATOMIC_VALID_WRITE: begin
                    state <= S_DONE;
                    //r_stall <= 0;
                end
                
                S_DONE: begin
                    //bypass the IDLE if consecutive requests?
                    /*
                    if (i_is_atomic || i_wr || i_rd) begin 
                        state <= S_WAIT;
                        r_stall <= 1;
                    end
                    */
                    //else begin
                        state <= S_IDLE;
                        r_stall <= 0;
                    //end
                end
                
                S_BASIC_LOAD: begin
                    //r_stall <= 0;
                    state <= S_DONE;
                end
                
                S_BASIC_STORE: begin
                    //r_stall <= 0;
                    state <= S_DONE;
                end
            endcase
            

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
    
    //assign initial_stall = (i_is_atomic || i_rd || i_wr) && !i_grant;
    
    
    assign o_done = (state == S_DONE) ? 1'b1 : 1'b0;
    assign o_request = (i_is_atomic || i_wr || i_rd);
    assign o_data_to_OCM = (i_is_atomic) ? res : i_data_from_core;
    
    assign o_dm_write = (i_is_atomic) ? 
                            ( !(state == S_ATOMIC_VALID_READ) ) ? 4'b0000 : 4'b1111
                         : (i_rd || i_wr) ? i_dm_write : 4'b0000  ;
    
    
    
    assign o_data_to_WB = (i_is_atomic) ? 
                            (i_atomic_op == 1) ? temp : res
                            : temp;
    
    assign o_addr = i_addr;
    assign o_stall_atomic =  r_stall;
endmodule
