/*
	Description: FIFO for the TAGs for dispatcher
	Author: Luis Alberto Mena González
*/

module tag_fifo #(parameter DEPTH=64, DATA_WIDTH=6)(
    input logic 								clk,
    input logic 								rst,
    input logic [DATA_WIDTH-1:0] 		cdb_tag_tf,
    input logic 								cdb_tag_tf_valid,
    input logic 								ren_tf,
    output logic [DATA_WIDTH-1:0] 		tagout_tf,
    output logic 								ff_tf,				//FIFO full
    output logic 								ef_tf					//Empty FIFO
);

logic [DATA_WIDTH-1:0] fifo[DEPTH];
logic [6:0] rp;
logic [6:0] wp;

// FIFO Init
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        rp <= 7'b0000000;
        wp <= 7'b1000000;
		  //tagout_tf <= 'b0;
        // inicializar FIFO (EN EL MISMO always_ff)
        for (int i = 0; i < DEPTH; i++) begin
            fifo[i] <= i;
        end
    end
    else begin
        // WRITES
        if (!ff_tf & cdb_tag_tf_valid) begin
            fifo[wp[5:0]] <= cdb_tag_tf;
            wp <= wp + 1'b1;
        end

        // READ
        if (ren_tf) begin
            rp <= rp + 1'b1;
				//tagout_tf <= fifo[rp[5:0]];
				fifo[rp[5:0]] <= 'b0;
        end
    end
end

assign ef_tf = (wp == rp);
assign ff_tf = ((wp[5:0] == rp[5:0]) & (wp[6] != rp[6]));
assign tagout_tf = rst ? 'b0 : fifo[rp[5:0]];

endmodule