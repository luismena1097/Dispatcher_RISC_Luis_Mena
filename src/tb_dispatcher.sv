`timescale 1ns/1ps
`include "variables.sv"

module tb_dispatcher;

    parameter DATA_WIDTH = 32;

    logic clk;
    logic rst;
    logic [DATA_WIDTH-1:0] ifetch_pc_plus_four, ifetch_instruction;
	logic ifetch_empty_flag;
	logic dispatch_ren;
	logic [6:0]			     cdb_tag;
	logic 					 cdb_valid;
	logic [31:0] 			 cdb_data;
	logic					 cdb_branch;
	logic 					 cdb_branch_taken;
    	 //Enable to each of the Queues
	logic						en_div_dispatch;
	logic 						en_mult_dispatch;
	logic 						en_store_load_dispatch;
	logic 					    en_int_dispatch;
	 
	int_queue_data 				dispatcher_2_int_queue;
	lw_sw_queue_data 			dispatcher_2_lw_sw_queue;
	queue_data					dispatcher_2_mult_or_div;

    // DUT
    dispatcher DUT(
    .clk(clk),.rst(rst),
	.ifetch_pc_plus_four(ifetch_pc_plus_four),
	.ifetch_instruction(ifetch_instruction),
	.ifetch_empty_flag(ifetch_empty_flag),
	 
	 //CDB
	.cdb_tag(cdb_tag),
	.cdb_valid(cdb_valid),
	.cdb_data(cdb_data),
	.cdb_branch(cdb_branch),
	.cdb_branch_taken(),
	
	.dispatch_jmp_branch_addr(),
	.dispatch_jump_branch(),
	.dispatch_ren(dispatch_ren),

    .dispatcher_2_int_queue(dispatcher_2_int_queue),
	.dispatcher_2_lw_sw_queue(dispatcher_2_lw_sw_queue),
	.dispatcher_2_mult_or_div(dispatcher_2_mult_or_div),

	.en_div_dispatch(en_div_dispatch),
	.en_mult_dispatch(en_mult_dispatch),
	.en_store_load_dispatch(en_store_load_dispatch),
	.en_int_dispatch(en_int_dispatch)
);

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;

    initial begin
	    rst = 0;
        cdb_valid = 0;
        cdb_tag = 'b0;
		ifetch_empty_flag = 'b0;
		#10;
        rst = 1;
        #10;
        rst = 0;
		#5;
        ifetch_pc_plus_four = 'h400_000;
        ifetch_instruction = 'h00100513; 		//addi a0, zero, 1
		#10;
		cdb_tag = 'h0;
		cdb_valid = 'h1;
		cdb_data = 'h1;
		ifetch_pc_plus_four = 'h400_004;
		ifetch_instruction = 'h00a50533;		//add a0, a0, a0
		#10;
		cdb_valid = 'h0;
		ifetch_pc_plus_four = 'h400_008;
		ifetch_instruction = 'h00082683;		//lw a3,0(a6)
		#10;
		ifetch_pc_plus_four = 'h400_00C;
		ifetch_instruction = 'h0040006f;		//jal zero, send
		#10;
		ifetch_pc_plus_four = 'h400_010;
		ifetch_instruction = 'h02a50733;		//mul a4, a0, a0
		#10;
		ifetch_pc_plus_four = 'h400_014;
		ifetch_instruction = 'h02E747B3;		//div a5,a4,a4
		#10;
		ifetch_empty_flag = 1'b1;
    end

endmodule
