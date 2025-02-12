//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// pipereg_exe_mem.v -- EXE/MEM Pipeline register module
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Author: Microlab 198 Pipelined RISC-V Group (2SAY1920)
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// Module Name: pipereg_exe_mem.v
// Description:
//
// Revisions:
// Revision 0.01 - File Created
// Additional Comments:
// 
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


`timescale 1ns / 1ps
`include "constants.vh"

module pipereg_exe_mem(
	input clk,
	input nrst,
	
	input flush,

	input [`PC_ADDR_BITS-1:0] exe_pc4,
	output reg [`PC_ADDR_BITS-1:0] mem_pc4,

	input [`WORD_WIDTH-1:0] exe_ALUout,
	output reg [`WORD_WIDTH-1:0] mem_ALUout,

	input [`WORD_WIDTH-1:0] exe_DIVout,
	output reg [`WORD_WIDTH-1:0] mem_DIVout,

	input [`WORD_WIDTH-1:0] exe_storedata,
	output reg [`WORD_WIDTH-1:0] mem_storedata,

	input [`WORD_WIDTH-1:0] exe_imm,
	output reg [`WORD_WIDTH-1:0] mem_imm,

	input [`REGFILE_BITS-1:0] exe_rd,
	output reg [`REGFILE_BITS-1:0] mem_rd,

	// Control signals
	input [3:0] exe_dm_write,
	output reg [3:0] mem_dm_write,

	input exe_wr_en,
	output reg mem_wr_en,

	input [2:0] exe_dm_select,
	output reg [2:0] mem_dm_select,

	input [2:0] exe_sel_data,
	output reg [2:0] mem_sel_data,
	
	input exe_to_OCM,
	output reg mem_to_OCM,
	
	input exe_is_atomic,
	output reg mem_is_atomic,
	
	input exe_is_stype,
	output reg mem_is_stype,
	
	input exe_is_ltype,
	output reg mem_is_ltype,
	
	input [31:0] exe_opB, // For ATOMICs
	output reg [31:0] mem_opB,
	
	input [3:0] exe_atomic_op,
	output reg [3:0] mem_atomic_op
);
	
	initial begin
			mem_pc4 <= 0;	
			mem_ALUout <= 0;
			mem_DIVout <= 0;
			mem_storedata <= 0;
			mem_imm <= 0;
			mem_rd <= 0;
			mem_opB <= 0;
			mem_is_ltype <= 0;
			mem_is_stype <= 0;
			mem_to_OCM <= 0;
			mem_is_atomic <= 0;

			// Control signals
			mem_dm_write <= 0;
			mem_wr_en <= 0;
			mem_dm_select <= 0;
			mem_sel_data <= 0;
	end
	
	always@(posedge clk) begin
		if(!nrst || flush) begin
			mem_pc4 <= 0;	
			mem_ALUout <= 0;
			mem_DIVout <= 0;
			mem_storedata <= 0;
			mem_imm <= 0;
			mem_rd <= 0;
			mem_opB <= 0;
			mem_is_ltype <= 0;
			mem_is_stype <= 0;
			mem_to_OCM <= 0;
			mem_is_atomic <= 0;
			mem_atomic_op <= 0;

			// Control signals
			mem_dm_write <= 0;
			mem_wr_en <= 0;
			mem_dm_select <= 0;
			mem_sel_data <= 0;
		end
		else begin
			mem_pc4 <= exe_pc4;
			mem_ALUout <= exe_ALUout;
			mem_DIVout <= exe_DIVout;
			mem_storedata <= exe_storedata;
			mem_imm <= exe_imm;
			mem_rd <= exe_rd;
			

			// Control signals
			mem_dm_write <= exe_dm_write;
			mem_wr_en <= exe_wr_en;
			mem_dm_select <= exe_dm_select;
			mem_sel_data <= exe_sel_data;
			mem_to_OCM <= exe_to_OCM;
			mem_is_atomic <= exe_is_atomic;
			mem_is_ltype <= exe_is_ltype;
			mem_is_stype <= exe_is_stype;
			mem_opB <= exe_opB;
			mem_atomic_op <= exe_atomic_op;
		end
	end

endmodule