/*
	Description: Register Status Table to rename all RD 
	Author: Luis Alberto Mena González
*/

`include "variables.sv"

module dispatcher(
    input logic                		clk,
	 input logic 					rst,
	 input logic [31:0]			 	ifetch_pc_plus_four,
	 input logic [31:0]			 	ifetch_instruction,
	 input logic 					ifetch_empty_flag,
	 
	 //CDB
	 input logic [6:0]			    cdb_tag,
	 input logic 					cdb_valid,
	 input logic [31:0] 			cdb_data,
	 input logic 					cdb_branch,
	 input logic					cdb_branch_taken, //1 = taken / 0 = not taken
	
	 output logic [31:0]			dispatch_jmp_branch_addr,
	 output logic 					dispatch_jump_branch,
	 output logic					dispatch_ren,	//Goes to the IFQ and stall the fetch in case there is a branch
	 
	 //Enable to each of the Queues
	 output logic					en_div_dispatch,
	 output logic 					en_mult_dispatch,
	 output logic 					en_store_load_dispatch,
	 output logic 					en_int_dispatch,
	 
	 output int_queue_data 			dispatcher_2_int_queue,
	 output lw_sw_queue_data 		dispatcher_2_lw_sw_queue,
	 output queue_data				dispatcher_2_mult_or_div
);

//Wire for decoding the instruction
logic [4:0]  instr_rs1_addr, instr_rs2_addr, instr_rd_addr;
logic [6:0]  instr_opcode;
logic [2:0]  instr_func3;
logic [6:0]  instr_func7;
logic 		 read_enable_w;		//Wire to enable token fifo reading tag
logic [31:0] Instruction_2_decode; 

//Wire for RST
logic [5:0]			rs1_tag_W;
logic 				rs1_valid_w;
logic [5:0]			rs2_tag_W;
logic 				rs2_valid_w;
logic [4:0]			rd_regfile_rst_w;
logic   			write_en_regfile_w;

//Wire for Imm
logic [31:0] Imm_o_w;

//Wire branch/jump calculation
logic [31:0] Branch_jump_addr_w;
logic branch_signal_W, jump_signal_w;

//Wire TAG FIFO
logic [5:0] Tagout_tf_W;
logic ff_tf_w, et_tf_w;

//Dispatcher to reservation station
logic sel_data_rs1, sel_data_rs2;
logic [31:0] rs1_data_dispatcher, rs2_data_dispatcher;
logic [31:0] RS1_regfile, RS2_regfile;

assign Instruction_2_decode = ifetch_empty_flag ? 32'b0 : ifetch_instruction;

//Decode the instruction
decoder instruction_decode(
.Instruction(Instruction_2_decode),
.RS1(instr_rs1_addr), .RS2(instr_rs2_addr), .RD(instr_rd_addr),
.Opcode(instr_opcode), .Func3(instr_func3), .Func7(instr_func7),
.rd_en(read_enable_w)
);

//Imm gen
imm_gen imm_gen_module (.Instruction_i(Instruction_2_decode), .Imm_o(Imm_o_w));

//Jump/Branch calculation
addr_calc jump_branch_calc(
.PC(ifetch_pc_plus_four), .Opcode(instr_opcode), .Imm(Imm_o_w),
.Branch_jump_addr(Branch_jump_addr_w), .branch(branch_signal_W), .jump(jump_signal_w) 
);

//Tag FIFO for register renaming
tag_fifo #(.DEPTH(64), .DATA_WIDTH(6))tag_fifo_module(
.clk(clk), .rst(rst),
.cdb_tag_tf(cdb_tag), .cdb_tag_tf_valid(cdb_valid),
.ren_tf(read_enable_w),
.tagout_tf(Tagout_tf_W),
.ff_tf(ff_tf_w), .ef_tf(et_tf_w)				
);

//Register Status Table - RST
rst rst_module(
.clk(clk),
.rst(rst),
//Write Port 0
.wdata0_rst({1'b1,Tagout_tf_W}), //1 bit valid + 6 bits of the token from the TAG FIFO
.waddr0_rst(instr_rd_addr),		//Addr from RD before the renaming
.wen0_rst(read_enable_w),
//Write Port 1
.wdata1_rst('b0),
.wen1_rst('b0),
//RS - RS1 Port
.rsaddr_rst(instr_rs1_addr),		//Register RS1 from the instruction
.rstag_rst(rs1_tag_W),
.rsvalid_rst(rs1_valid_w),
//RT - RS2 Port
.rtaddr_rst(instr_rs2_addr),		//Register RS2 from the instruction
.rttag_rst(rs2_tag_W),
.rtvalid_rst(rs2_valid_w),
//CDB
.cdb_valid(cdb_valid),
.cdb_tag_rst(cdb_tag),
.rd_regfile_rst(rd_regfile_rst_w),
.write_en_regfile(write_en_regfile_w)
);

//Register File
register_file #(.ADDR(5), .WIDTH(32))RegFile_module(
.clk(clk),
.rst(rst),
.reg_write(write_en_regfile_w),
.Read_reg1(instr_rs1_addr),
.Read_reg2(instr_rs2_addr),
.Write_reg(rd_regfile_rst_w),
.Write_Data(cdb_data),
.Read_data1(RS1_regfile),
.Read_data2(RS2_regfile)
);

/* Dispatcher to reservation stations*/
//Mux for RS1 from RegFile or from CDB
assign sel_data_rs1 = cdb_valid && ({1'b1,cdb_tag} == {rs1_valid_w,rs1_tag_W});
assign rs1_data_dispatcher = sel_data_rs1 ? cdb_data : RS1_regfile;

//Mux for RS2 from RegFile or from CDB
assign sel_data_rs2 = cdb_valid && ({1'b1,cdb_tag} == {rs2_valid_w,rs2_tag_W});
assign rs2_data_dispatcher = sel_data_rs2 ? cdb_data : RS2_regfile;

//Module to create the package for the queues
pkg_dispatch pkg_dispatch_module(
	.rs1_decoded(instr_rs1_addr), .rs2_decoded(instr_rs2_addr),
	.rs1_data(rs1_data_dispatcher), .rs2_data(rs2_data_dispatcher),
	.rs1_sel_cdb_or_regfile(sel_data_rs1), .rs2_sel_cdb_or_regfile(sel_data_rs2),
	.Opcode(instr_opcode), .Func3(instr_func3), .Func7(instr_func7), .Imm(Imm_o_w),
	.rs1_valid_plus_tag({rs1_valid_w,rs1_tag_W}), .rs2_valid_plus_tag({rs2_valid_w,rs2_tag_W}),
	.rd_tag(Tagout_tf_W),
	.branch_jump_address(Branch_jump_addr_w),

	.dispatcher_2_int_queue(dispatcher_2_int_queue),
	.dispatcher_2_lw_sw_queue(dispatcher_2_lw_sw_queue),
	.dispatcher_2_mult_or_div(dispatcher_2_mult_or_div),

	.en_div_dispatch(en_div_dispatch),
	.en_mult_dispatch(en_mult_dispatch),
	.en_store_load_dispatch(en_store_load_dispatch),
	.en_int_dispatch(en_int_dispatch)
);

assign dispatch_ren = branch_signal_W ? 1'b0 : 1'b1;
assign dispatch_jump_branch = jump_signal_w | cdb_branch_taken;
assign dispatch_jmp_branch_addr = Branch_jump_addr_w;

endmodule