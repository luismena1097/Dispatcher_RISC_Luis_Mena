/*
	Description: Immediate generator for RISC-V
	Author: Luis Alberto Mena González
*/

module imm_gen (
    input  logic [31:0] Instruction_i,
    output logic [31:0] Imm_o
);

    localparam logic [6:0] I_TYPE = 7'b0010011; // immediate en bits 20-31
    localparam logic [6:0] S_TYPE = 7'b0100011; // immediate en bits 7-11 y 25-31
    localparam logic [6:0] B_TYPE = 7'b1100011; // immediate en bits 7-11 y 25-31
    localparam logic [6:0] J_TYPE = 7'b1101111; // immediate en bits 1-20
    localparam logic [6:0] U_TYPE = 7'b0010111; // immediate en bits 12-31 (AUIPC)
    localparam logic [6:0] JALR   = 7'b1100111;
    localparam logic [6:0] LW     = 7'b0000011;

    always_comb begin
        unique case (Instruction_i[6:0])
            I_TYPE: Imm_o = {{20{Instruction_i[31]}}, Instruction_i[31:20]};
            B_TYPE: Imm_o = {{20{Instruction_i[31]}}, Instruction_i[7], Instruction_i[30:25], Instruction_i[11:8], 1'b0};
            S_TYPE: Imm_o = {{21{Instruction_i[31]}}, Instruction_i[30:25], Instruction_i[11:7]};
            J_TYPE: Imm_o = {{12{Instruction_i[31]}}, Instruction_i[19:12], Instruction_i[20], Instruction_i[30:21], 1'b0};
            U_TYPE: Imm_o = {Instruction_i[31:12], 12'b0};
            JALR :  Imm_o = {{20{Instruction_i[31]}}, Instruction_i[31:20]};
            LW   :  Imm_o = {{20{Instruction_i[31]}}, Instruction_i[31:20]};
            default: Imm_o = 32'h0;
        endcase
    end

endmodule