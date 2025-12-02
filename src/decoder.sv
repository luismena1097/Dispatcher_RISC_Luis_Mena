/*
	Description: Instruction decoder for RISC-V
	Author: Luis Alberto Mena González
*/

module decoder(
    input logic [31:0] Instruction,
    output logic [4:0] RS1,
    output logic [4:0] RS2,
    output logic [4:0] RD,
    output logic [6:0] Opcode,
    output logic [2:0] Func3,
    output logic [6:0] Func7,
	 output logic rd_en
);

localparam logic [6:0] R_TYPE = 7'b0110011; 
localparam logic [6:0] I_TYPE = 7'b0010011; 
localparam logic [6:0] S_TYPE = 7'b0100011;
localparam logic [6:0] B_TYPE = 7'b1100011; 
localparam logic [6:0] J_TYPE = 7'b1101111; 
localparam logic [6:0] U_TYPE = 7'b0010111; 
localparam logic [6:0] JALR   = 7'b1100111;
localparam logic [6:0] LW     = 7'b0000011;

assign Opcode = Instruction[6:0];
assign RD = Instruction[11:7];
assign Func3 = Instruction[14:12];
assign RS1 = Instruction[19:15];
assign RS2 = Instruction[24:20];
assign Func7 = Instruction[31:25];

always_comb begin
	case(Opcode)
		R_TYPE, I_TYPE, U_TYPE, J_TYPE: rd_en = (RD != 0) ? 1'b1:1'b0;
		default : rd_en = 1'b0;
	endcase
end

endmodule