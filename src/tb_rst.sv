`timescale 1ns/1ps

module tb_rst;

    // =======================
    // Señales del DUT
    // =======================
    logic clk;
    logic rst;

    // Write Port 0
    logic [6:0]  wdata0_rst;
    logic [4:0]  waddr0_rst;
    logic        wen0_rst;

    // Write Port 1 (CDB clear)
    logic [6:0]  wdata1_rst;     // normalment 0000000
    logic [31:0] wen1_rst;       // 32-bit one-hot

    // Read Ports
    logic [4:0]  rsaddr_rst;
    logic [5:0]  rstag_rst;
    logic        rsvalid_rst;

    logic [4:0]  rtaddr_rst;
    logic [5:0]  rttag_rst;
    logic        rtvalid_rst;

    // CDB
    logic        cdb_valid;
    logic [5:0]  cdb_tag_rst;
    logic [4:0]  rd_regfile_rst;
    logic        write_en_regfile;

    // =======================
    // Instanciar DUT
    // =======================
    rst dut (
        .clk(clk),
        .rst(rst),
        .wdata0_rst(wdata0_rst),
        .waddr0_rst(waddr0_rst),
        .wen0_rst(wen0_rst),
        .wdata1_rst(wdata1_rst),
        .wen1_rst(wen1_rst),
        .rsaddr_rst(rsaddr_rst),
        .rstag_rst(rstag_rst),
        .rsvalid_rst(rsvalid_rst),
        .rtaddr_rst(rtaddr_rst),
        .rttag_rst(rttag_rst),
        .rtvalid_rst(rtvalid_rst),
        .cdb_valid(cdb_valid),
        .cdb_tag_rst(cdb_tag_rst),
        .rd_regfile_rst(rd_regfile_rst),
        .write_en_regfile(write_en_regfile)
    );

    // =======================
    // Generador de clock
    // =======================
    always #5 clk = ~clk;


    // =======================
    // TEST
    // =======================
    initial begin
        $display("\n===== INICIANDO TEST RST =====");

        // Inicializar señales
        clk = 0;
        rst = 1;

        wdata0_rst = 7'd0;
        waddr0_rst = 5'd0;
        wen0_rst   = 0;

        wdata1_rst = 7'd0;
        wen1_rst   = 32'd0;

        rsaddr_rst = 5'd0;
        rtaddr_rst = 5'd0;

        cdb_valid  = 0;
        cdb_tag_rst = 6'd0;

        // Reset
        repeat (3) @(posedge clk);
        rst = 0;

        // =======================================================
        // 1. ESCRIBIR TAG EN UN REGISTRO (WRITE PORT 0)
        // =======================================================
        $display("\n-- Escribiendo TAG 0b1_000101 (bit válido + TAG=5) en R3");

        waddr0_rst = 5'd4;
        wdata0_rst = {1'b1, 6'd0};   // valido=1, tag=5
        wen0_rst   = 1;

        @(posedge clk);
        wen0_rst = 0;

        // =======================================================
        // 2. LEER RS Y RT
        // =======================================================
        $display("\n-- Leyendo RS=3 y RT=3");

        rsaddr_rst = 5'd0;
        rtaddr_rst = 5'd3;

        @(posedge clk);

        $display("   RS: valid=%0d tag=%0d", rsvalid_rst, rstag_rst);
        $display("   RT: valid=%0d tag=%0d", rtvalid_rst, rttag_rst);

        // =======================================================
        // 3. ACTIVAR CDB PARA LIBERAR EL TAG
        // =======================================================
        $display("\n-- Publicando CDB con TAG=5");

        cdb_tag_rst = 6'd0;
        cdb_valid   = 1;

        @(posedge clk);
        cdb_valid = 0;

        $display("   CDB limpia R%0d  write_en_regfile=%0d",
                  rd_regfile_rst, write_en_regfile);

        @(posedge clk);

        // =======================================================
        // 4. Verificar que el registro fue limpiado
        // =======================================================
        $display("\n-- Leyendo nuevamente RS=3 (debe estar invalidado)");
        rsaddr_rst = 5'd3;
        @(posedge clk);

        $display("   RS: valid=%0d tag=%0d", rsvalid_rst, rstag_rst);

        $display("\n===== FIN DEL TEST =====\n");
        $finish;
    end

endmodule
