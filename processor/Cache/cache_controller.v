`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/27/2024 12:17:34 PM
// Design Name: 
// Module Name: cache_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The main cache controller that will send appropriate control signals to the Tag array and data array
//      
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cache_controller
    #
    (
    parameter CACHE_WAY = 8,
    parameter ADDR_WIDTH = 14,
    parameter TAG_BITS = 5,
    parameter INDEX_BITS = 3,
    parameter OFFSET_BITS = 2
    )
    (
    input clk,
    input nrst,
    
    
    input [ADDR_WIDTH-1:0]      i_addr,
    input                       i_hit,           //From the Tag Array
    input                       i_readymm,       // Grant from arbitration
    input                       i_done_mm,
    input                       i_rd,
    input                       i_wr,
    
    // input for LRU
    input [TAG_BITS+1:0]        i_LRU_set_tag_info,
    input  [CACHE_WAY-1:0]      i_way_accessed,
    
    output [TAG_BITS-1:0]       o_tag, 
    output [INDEX_BITS-1:0]     o_index, 
    output [1:0]                o_offset,
    output [1:0]                o_byte_offset,
    
    //output control signals
    output                      o_modify,
    output                      o_wetag,         // Write Enable for the tag array        
    
    //output LRU information       .
    output [CACHE_WAY-1:0]      o_LRU,        
    
    //output for Refills and Eviction
    output                      o_refill_en,
    output                      o_sample_data,
    output                      o_sample_addr,
    output                      o_evict_en,
    output [ADDR_WIDTH-5:0]     o_addr_evicted,
    
    output                      o_stall,
    output                      o_all_done
    );
    

    
    // Parse address

    assign o_byte_offset = i_addr[1:0];             // For bytewise writes
    assign o_offset = i_addr[3:2];      // should I just do 2 bits for 4 words per block?
    assign o_index = i_addr[ADDR_WIDTH - TAG_BITS - 1: 4];
    assign o_tag = i_addr[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_BITS ];

        

    
    // Parse LRU tag info from tag array to check if modified
    // need the 2 MSB for the MESI protocol
    wire MESI_state_1;
    wire MESI_state_0;
    wire modified;
    assign MESI_state_1 = i_LRU_set_tag_info[TAG_BITS+1];
    assign MESI_state_0 = i_LRU_set_tag_info[TAG_BITS];
    // MESI states
    // Invalid:     00
    // Shared:      01
    // Modified:    10
    // Exclusive:   11
    // bit 0 - stored in MESI_state_0;
    // bit 1 - stored in MESI_state_1;
    
    assign modified = MESI_state_1 && ~MESI_state_0;
    
    // Assemble the base address for evicting;
    // Address = Tag + index + Offset + 00;
    assign o_addr_evicted = { i_LRU_set_tag_info[TAG_BITS-1:0], i_addr[ADDR_WIDTH - TAG_BITS - 1: 4]};
    

    // Declaring States
    reg [2:0] state;
    
    localparam S_NORMAL = 3'b000;
    localparam S_WRITE = 3'b001;
    localparam S_READ = 3'b010;
    localparam S_UPDATING = 3'b011;
    localparam S_WAITING_FOR_MM = 3'b100;
    localparam S_DONE = 3'b101; // For Testbench only
    
    // Control signals
    reg evict_en_reg;    
    assign o_modify = ( i_wr && i_hit ) ? 1'b1 : 1'b0; // Tag already exists in the cache, update the MESI protocols only
    assign o_wetag = ( state == S_WAITING_FOR_MM && !i_hit) ? 1'b1 : 1'b0;                    //it doesnt matter if its a read or write miss, we'll be writing the tag in the cache anways
    assign o_refill_en = ( state == S_UPDATING ) ? 1'b1 : 1'b0;
    assign o_sample_addr = (state == S_WAITING_FOR_MM) ? 1'b1 : 1'b0;
    assign o_sample_data = ( state == S_WAITING_FOR_MM && ~i_hit && modified) ? 1'b1 : 1'b0;
    assign o_evict_en = evict_en_reg;
    assign o_all_done = ( state == S_DONE ) ? 1'b1 : 1'b0;
    assign o_stall = (state == S_UPDATING || state == S_WAITING_FOR_MM || (i_rd || i_wr) && !i_hit) ? 1'b1 : 1'b0;
    
    // Generate the proper LRU module 
    generate 
        
        case (CACHE_WAY) 
            8: begin
                eightway_PLRU PLRU_module(.nrst(nrst), .i_way_accessed(i_way_accessed), .i_hit(i_hit), .o_LRU(o_LRU));
            end
            
            4: begin
                fourway_LRU PLRU_module(.nrst(nrst), .i_way_accessed(i_way_accessed), .i_hit(i_hit), .o_LRU(o_LRU));
            end
            
            2: begin
                twoway_LRU PLRU_module(.nrst(nrst), .i_way_accessed(i_way_accessed), .i_hit(i_hit), .o_LRU(o_LRU));
            end
            default: begin  
                eightway_PLRU (.i_way_accessed(i_way_accessed));
            end
        endcase
        
    endgenerate
    
    initial begin
        state <= S_NORMAL;
    end
    
    
    // =========== FSM =======================//
    always @(posedge clk) begin
        if (!nrst) begin
            state <= S_NORMAL;

        end
        else begin

            case (state)
                S_NORMAL: begin
                    evict_en_reg <= 0;
                    if (i_rd) begin
                        if (i_hit) state <= S_NORMAL;
                        else state <= S_WAITING_FOR_MM;
                    end
                    
                    if (i_wr) begin
                        if (i_hit) state <= S_NORMAL;
                        else state <= S_WAITING_FOR_MM;
                    end
                end
                
                S_READ: begin
                    if (i_hit) begin
                        if (i_rd) state <= S_READ;
                        if (i_wr) state <= S_WRITE;
                    end 
                    else begin
                        state <= S_WAITING_FOR_MM;
                    end
                    evict_en_reg <= 0;
                end
                
                S_WAITING_FOR_MM: begin
                    if (i_readymm) state <= S_UPDATING;
                    
                    if (o_sample_data) evict_en_reg <= 1'b1;
                end
                
                S_WRITE: begin
                    if (i_hit) begin
                        if (i_rd) state <= S_READ;
                        if (i_wr) state <= S_WRITE;
                    end 
                    else begin
                        state <= S_WAITING_FOR_MM;
                        
                    end
                    evict_en_reg <= 0;
                end
                
                S_UPDATING: begin
                    if (i_done_mm) begin
                        state <= S_NORMAL;
                    end
                end
                
                S_DONE: begin
                    state <= S_NORMAL;
                    evict_en_reg <= 0;
                end
                
                default: state <= S_NORMAL;
            endcase
            
            

        end
        
        
        
        
    end
    
    
endmodule
