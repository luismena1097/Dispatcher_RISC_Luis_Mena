/*
	Description: Register Status Table to rename all RD 
	Author: Luis Alberto Mena González
*/

module rst(
    input  logic                clk,
    input  logic                rst,
	 //Write Port 0
	 input logic [6:0]			  wdata0_rst,
    input logic [4:0]			  waddr0_rst,
	 input logic 				     wen0_rst,
	 //Write Port 1
	 input logic [6:0]			  wdata1_rst,
	 input logic [31:0] 			  wen1_rst,
	 //RS - RS1 Port
	 input logic [4:0]			  rsaddr_rst,
	 output logic [5:0]			  rstag_rst,
	 output logic 					  rsvalid_rst,
	 //RT - RS2 Port
	 input logic [4:0]			  rtaddr_rst,
	 output logic [5:0]			  rttag_rst,
	 output logic 					  rtvalid_rst,
	 //CDB
	 input logic					  cdb_valid,
	 input logic [5:0] 			  cdb_tag_rst,
	 output logic [4:0] 		  	  rd_regfile_rst,
	 output logic 					  write_en_regfile
);
//RST
reg [6:0] registers [0:31];
reg [4:0] cdb_clear_addr;

//Syncronus write to registers
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
	for (int i = 0; i < 32; i++)
		registers[i] = 7'h0;
	end
	if(wen0_rst) 
		registers[waddr0_rst] <= wdata0_rst;
	else if(cdb_clear_addr != waddr0_rst)
		registers[cdb_clear_addr] <= 7'h0;
end

always_comb begin
  rd_regfile_rst = 5'd0;
  cdb_clear_addr  = 5'd0;
  write_en_regfile = 1'b0;	
  
  if (cdb_valid) begin
		for (int i = 0; i < 32; i++) begin
			 if (registers[i] == {1'b1, cdb_tag_rst}) begin
				  rd_regfile_rst = i[4:0];
				  write_en_regfile = 1'b1;
				  // Evitar borrar si justo se está escribiendo ese registro
				  if (!((waddr0_rst == i[4:0]) && wen0_rst))
						cdb_clear_addr = i[4:0];
			 end
		end
  end
end

//Asyncronus read to registers
assign rstag_rst = registers[rsaddr_rst][5:0];
assign rsvalid_rst = registers[rsaddr_rst][6];

assign rttag_rst = registers[rtaddr_rst][5:0];
assign rtvalid_rst = registers[rtaddr_rst][6];

endmodule