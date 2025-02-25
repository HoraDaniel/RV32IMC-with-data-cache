// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.1 (win64) Build 5076996 Wed May 22 18:37:14 MDT 2024
// Date        : Sat Nov  9 20:43:03 2024
// Host        : DESKTOP-9IG3UKH running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub f:/pipelined-RV32IMC/vivado-ip-src/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35ticsg324-1L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clkfb_in, clk_out1, clkfb_out, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clkfb_out,locked,clk_in1" */
/* synthesis syn_force_seq_prim="clkfb_in" */;
  input clkfb_in /* synthesis syn_isclock = 1 */;
  output clk_out1;
  output clkfb_out;
  output locked;
  input clk_in1;
endmodule
