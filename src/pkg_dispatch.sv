/*
	Description: Module to assemble the dispatcher package to the different queues
	Author: Luis Alberto Mena González
*/
`include "variables.sv"
module pkg_dispatch(
    input logic [4:0]               	rs1_decoded, rs2_decoded,
	input logic [31:0]					rs1_data, rs2_data,
	input logic 						rs1_sel_cdb_or_regfile, rs2_sel_cdb_or_regfile,
	input logic [6:0]					Opcode,
	input logic [2:0]					Func3,
	input logic [6:0]					Func7,
	input logic [31:0]					Imm,
	input logic [6:0]					rs1_valid_plus_tag, rs2_valid_plus_tag,
	input logic [5:0]					rd_tag,
	input logic [31:0]					branch_jump_address,

	output int_queue_data 				dispatcher_2_int_queue,
	output lw_sw_queue_data 			dispatcher_2_lw_sw_queue,
	output queue_data					dispatcher_2_mult_or_div,

	output logic						en_div_dispatch,
	output logic 						en_mult_dispatch,
	output logic 						en_store_load_dispatch,
	output logic 					    en_int_dispatch
);

queue_data rsv_data_all;

always_comb begin
	rsv_data_all.rs1_data = rs1_data;
    rsv_data_all.rs2_data = rs2_data;
    rsv_data_all.rs1_tag = rs1_valid_plus_tag[5:0];
    rsv_data_all.rs2_tag = rs2_valid_plus_tag[5:0];
    rsv_data_all.rd_tag = rd_tag;

	if(rs1_decoded == 'b0)
		rsv_data_all.rs1_data_valid = 1'b1;
	else if (rs1_sel_cdb_or_regfile)
		rsv_data_all.rs1_data_valid = 1'b1;
	else
		rsv_data_all.rs1_data_valid = ~rs1_valid_plus_tag[6];

	if(rs2_decoded == 'b0)
		rsv_data_all.rs2_data_valid = 1'b1;
	else if (rs1_sel_cdb_or_regfile)
		rsv_data_all.rs2_data_valid = 1'b1;
	else
		rsv_data_all.rs2_data_valid = ~rs2_valid_plus_tag[6];
		
	case(Opcode)
		R_TYPE: begin
			if(Func3 == 'h4 && Func7 == 'h1)begin 
				en_div_dispatch 		= 1'b1;
				en_mult_dispatch 		= 1'b0;	 
				en_store_load_dispatch	= 1'b0;
				en_int_dispatch			= 1'b0;	
			end
			else if(Func3 == 'h0 && Func7 == 'h1)begin 
				en_div_dispatch 		= 1'b0;
				en_mult_dispatch 		= 1'b1;	 
				en_store_load_dispatch	= 1'b0;
				en_int_dispatch			= 1'b0;	
			end
			else begin 
				en_div_dispatch 		= 1'b0;
				en_mult_dispatch 		= 1'b0;	 
				en_store_load_dispatch	= 1'b0;
				en_int_dispatch			= 1'b1;	
			end			
		end
		I_TYPE, LUI: begin
			en_div_dispatch 		= 1'b0;
			en_mult_dispatch 		= 1'b0;	 
			en_store_load_dispatch	= 1'b0;
			en_int_dispatch			= 1'b1;	
			rsv_data_all.rs2_data_valid = 1'b1;
			rsv_data_all.rs2_data = Imm;
		end
		LW: begin
			en_div_dispatch 		= 1'b0;
			en_mult_dispatch 		= 1'b0;	 
			en_store_load_dispatch	= 1'b1;
			en_int_dispatch			= 1'b0;	
			rsv_data_all.rs2_data_valid = 1'b1;
		end
		S_TYPE: begin
			en_div_dispatch 		= 1'b0;
			en_mult_dispatch 		= 1'b0;	 
			en_store_load_dispatch	= 1'b1;
			en_int_dispatch			= 1'b0;	
		end
		J_TYPE: begin
			en_div_dispatch 		= 1'b0;
			en_mult_dispatch 		= 1'b0;	 
			en_store_load_dispatch	= 1'b0;
			en_int_dispatch			= 1'b0;	
		end
		JALR, B_TYPE, U_TYPE: begin   //U_TYPE = AUIPC
			en_div_dispatch 		= 1'b0;
			en_mult_dispatch 		= 1'b0;	 
			en_store_load_dispatch	= 1'b0;
			en_int_dispatch			= 1'b1;	
		end
		default: begin   
			en_div_dispatch 		= 1'b0;
			en_mult_dispatch 		= 1'b0;	 
			en_store_load_dispatch	= 1'b0;
			en_int_dispatch			= 1'b0;	
		end
	endcase
end

//Assembling package for int queue
assign dispatcher_2_int_queue.common_data 	= rsv_data_all;
assign dispatcher_2_int_queue.opcode 		= Opcode;
assign dispatcher_2_int_queue.func3 		= Func3;
assign dispatcher_2_int_queue.func7		= Func7;

//Assembling package for load/store queue
assign dispatcher_2_lw_sw_queue.common_data = rsv_data_all;
assign dispatcher_2_lw_sw_queue.func3		 = Func3;
assign dispatcher_2_lw_sw_queue.imm		 = Imm;
//If instruction is sw this signal = 1 if it is lw this signal = 0
assign dispatcher_2_lw_sw_queue.load_or_store_signal = (Opcode == LW) ? 1'b0 : 1'b1;

//Assembling package for div or mult queue
assign dispatcher_2_mult_or_div = rsv_data_all;

endmodule