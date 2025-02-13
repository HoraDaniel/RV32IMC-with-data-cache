`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2025 08:36:51 AM
// Design Name: 
// Module Name: OCM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:     The On-Chip Memory (OCM) allocates a non-cacheable region in the data memory
//                  Primarily for the flags/CSRs of communication protocols (to be implemented)
//                  Direct Memory Access of protocol controllers
//                  Leverage for use in atomic locks, semaphores, and mutexes
//                  There's probably a more efficient way to do atomics, but this is the easiest one we can do
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OCM #(
    parameter ADDR_BITS = 12
    )
    (
    input clk,
    input nrst,
    
    // Core 1 signals and data
    input i_req_core_1,
    input i_done_core_1,
    output reg o_grant_core_1,
    input [31:0] i_data_core_1,
    input [3:0] i_dm_write_core_1,
    //output [31:0] o_data_core_1,
    input [ADDR_BITS-1:0] i_addr_1,

    
    // Core 2 signals and data
    input i_req_core_2,
    input i_done_core_2,
    output reg o_grant_core_2,
    input [31:0] i_data_core_2,
    input [3:0] i_dm_write_core_2,
    //output [31:0] o_data_core_2,
    input [ADDR_BITS-1:0] i_addr_2,

    output [31:0] o_data,
    output reg valid_data,
    output reg valid_write_data,
    
    input [ADDR_BITS-1:0] addr_tb,
    output [31:0] out_tb
    
    );
    
    
    // Implement an arbitration module
    // Signals
    // req_core_n - request signal from Core 1 or 2
    // grant_core_n - grant signal to Core 1 or 2
    // done_core_n - done signal from Core 1 or 2 
    
    // Arbitration strategy: Round Robin style (easiest and simplest)
    // per clock cycle, if there are no requests, cycle through the two cores giving each a fair chance
    
    reg current_grant; // 0 - grant core 1;     1 - grant core 2
    
    initial begin
    
        current_grant <= 0;
    
    end
    
    always @ (posedge clk) begin
        if (!nrst) begin
            current_grant <= 0;
        end else begin
        
            case (current_grant) 
                0: begin 
                    // Core 1 has grant
                    if (i_req_core_1) begin // core 1 is requesting while core 1 is given grant
                        
                        o_grant_core_1 <= 1;
                        o_grant_core_2 <= 0;
                        if (i_done_core_1) begin
                            current_grant <= 1;
                            o_grant_core_1 <= 0;
                        end
                    end else if (i_req_core_2) begin
                        // Core 2 requests instead,
                        o_grant_core_2 <= 1;
                        o_grant_core_1 <= 0;
                        current_grant <= 1;
                    end else begin 
                        // No cores are requesting
                        current_grant <= 1; // give the grant to core 2
                        o_grant_core_2 <= 0;
                        o_grant_core_1 <= 0;
                    end
                   
                end
                
                
                1: begin
                    // Core 2 has grant
                    if (i_req_core_2) begin

                        o_grant_core_2 <= 1;
                        o_grant_core_1 <= 0;
                        if (i_done_core_2) begin
                            current_grant <= 0;
                            o_grant_core_2 <= 0;
                        end
                    end else if (i_req_core_1) begin
                        o_grant_core_2 <= 0;
                        o_grant_core_1 <= 1;
                        current_grant <= 0;
                    end else begin
                        current_grant <= 0;
                        o_grant_core_2 <= 0;
                        o_grant_core_1 <= 0;
                    end
                    

                end
            endcase
        end
    end
    
    // stalls
     
    
    
    ///////////////////////////////////////////////////////////////////
    // The memory part
    // States
    // MEM_WAIT - memory is waiting for a transaction
    // MEM_GRANT - a core is granted access to the memory; input ports are latched to the memory
    // MEM_RESP - since its ideal, need only one cycle to complete transactions. Assert necessary signals here
    // MEM_DONE - done state;
    

    
    localparam MEM_WAIT = 2'd0;
    localparam MEM_GRANT = 2'd1;
    localparam MEM_RESP = 2'd2;
    localparam MEM_DONE = 2'd3;
    
    reg [2:0] m_state;
    reg [31:0] in_data_bus;
    wire [31:0] out_data_bus;
    reg [3:0] dm_wire;
    reg [ADDR_BITS-1:0] in_addr_bus;
    
    wire wr = |dm_wire;
    wire rd = ~(|dm_wire);
    always @ (posedge clk) begin
       if (!nrst) begin
            in_data_bus <= 0;
            dm_wire <= 0;
            valid_data <= 0;
            m_state <= 0;
       end else
            case (m_state)
                MEM_WAIT: begin
                    if (i_req_core_1 && o_grant_core_1) begin
                        in_data_bus <= i_data_core_1;
                        in_addr_bus <= i_addr_1;
                        dm_wire <= i_dm_write_core_1;
                        m_state <= MEM_GRANT;
                    end 
                    else if (i_req_core_2 && o_grant_core_2) begin
                        in_data_bus <= i_data_core_2;
                        in_addr_bus <= i_addr_2;
                        dm_wire <= i_dm_write_core_2;
                        m_state <= MEM_GRANT;
                    end
                    else begin
                        in_data_bus <= in_data_bus;
                        in_addr_bus <= in_addr_bus;
                        dm_wire <= dm_wire;
                        m_state <= MEM_WAIT;
                    end
                end
                
                
                MEM_GRANT: begin
                    // We'll continue to next state, no take backs
                    // We can put delays here or wait for some signal from AXI protocol
                    m_state <= MEM_RESP;
                    if (rd) valid_data <= 1;
                    else if (wr) valid_write_data <= 1;
                end
                
                MEM_RESP: begin
                    // assert necessary valid signals
                    m_state <= MEM_DONE;
                    valid_data <= 0;
                    valid_write_data <= 0;
                end
                
                MEM_DONE: begin
                    m_state <= MEM_WAIT;
                end
            endcase
    end
    
    // Instantiate the BRAM
    dual_port_ram_bytewise_write #(.ADDR_WIDTH(ADDR_BITS) )
        bram (
            // port A for cores
            .clkA(clk),
            .enaA(1'b1),
            .weA(dm_wire),
            .addrA(in_addr_bus),
            .dinA(in_data_bus),
            .doutA(o_data),
            
            .clkB(clk),
            .enaB(1'b1),
            .addrB(addr_tb),
            .doutB(out_tb)
            
        
    );
    
endmodule
