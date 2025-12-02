`timescale 1ns/1ps

module tb_tag_fifo;

    parameter DEPTH      = 64;
    parameter DATA_WIDTH = 6;

    logic clk;
    logic rst;
    logic [DATA_WIDTH-1:0] cdb_tag_tf;
    logic cdb_tag_tf_valid;
    logic ren_tf;
    logic [DATA_WIDTH-1:0] tagout_tf;
    logic ff_tf;
    logic ef_tf;

    // DUT
    tag_fifo #(DEPTH, DATA_WIDTH) dut (
        .clk(clk),
        .rst(rst),
        .cdb_tag_tf(cdb_tag_tf),
        .cdb_tag_tf_valid(cdb_tag_tf_valid),
        .ren_tf(ren_tf),
        .tagout_tf(tagout_tf),
        .ff_tf(ff_tf),
        .ef_tf(ef_tf)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Tasks compatibles con cualquier compilador
    task fifo_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge clk);
            cdb_tag_tf        = data;
            cdb_tag_tf_valid  = 1;
            @(posedge clk);
            cdb_tag_tf_valid  = 0;
        end
    endtask

    task fifo_read;
        begin
            @(posedge clk);
            ren_tf = 1;
            @(posedge clk);
            ren_tf = 0;
        end
    endtask

    integer i;

    initial begin
		  rst = 0;
		  #10;
        rst = 1;
        cdb_tag_tf = 0;
        cdb_tag_tf_valid = 0;
        ren_tf = 0;

        repeat(2.5) @(posedge clk);
        rst = 0;

        $display("==== INICIO SIM ====");

        // Lecturas
        for (i=0; i<2; i=i+1) begin
            fifo_read();
            @(posedge clk);
            $display("WR Read %0d -> %0d", i, tagout_tf);
        end
		  
		  fifo_write(1);
		  fifo_write(0);

        $stop;
    end

endmodule
