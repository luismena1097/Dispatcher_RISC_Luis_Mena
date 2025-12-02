/*
	Description: Register file with 32 registers of 32 bits with synchronous writing and asynchronous reading 
	Author: Luis Alberto Mena González
*/

module register_file #(
    parameter int ADDR  = 5,
    parameter int WIDTH = 32
)(
    input  logic                clk,
    input  logic                rst,
    input  logic                reg_write,
    input  logic [ADDR-1:0]     Read_reg1,
    input  logic [ADDR-1:0]     Read_reg2,
    input  logic [ADDR-1:0]     Write_reg,
    input  logic [WIDTH-1:0]    Write_Data,
    output logic [WIDTH-1:0]    Read_data1,
    output logic [WIDTH-1:0]    Read_data2
);

    // Register file
    logic [WIDTH-1:0] registers_out [0:(2**ADDR)-1];

    // Reset + Write
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for (i = 0; i < (2**ADDR); i++) begin
                registers_out[i] <= '0;
            end
            registers_out[2] <= 32'h7fffeffc; // stack pointer
        end
        else if (reg_write && (Write_reg != 5'h0)) begin
            registers_out[Write_reg] <= Write_Data;
        end
    end

    // Asynchronous read
    assign Read_data1 = registers_out[Read_reg1];
    assign Read_data2 = registers_out[Read_reg2];

endmodule
