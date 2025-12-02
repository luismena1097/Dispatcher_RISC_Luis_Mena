/*
	Description: Branch & Jump Address Calculation for RISC-V
	Author: Luis Alberto Mena González
*/

module addr_calc(
    input logic [31:0] PC,
	input logic [6:0] Opcode,
	input logic [31:0] Imm,
	 
    output logic [31:0] Branch_jump_addr,
	output logic branch,
	output logic jump
);

localparam logic [6:0] B_TYPE = 7'b1100011;
localparam logic [6:0] J_TYPE = 7'b1101111;

always_comb begin
	case(Opcode)
		B_TYPE:
		begin
			Branch_jump_addr = PC + Imm;
			branch 			  = 1'b1;
			jump 				  = 1'b0;
		end
		J_TYPE:
		begin
			Branch_jump_addr = PC + Imm;
			branch 			  = 1'b0;
			jump 				  = 1'b1;
		end
		default:
		begin
			Branch_jump_addr = PC;
			branch 			  = 1'b0;
			jump 				  = 1'b0;
		end
	endcase
end

endmodule