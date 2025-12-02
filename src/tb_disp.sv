`timescale 1ns/1ps
`include "variables.sv"

module tb_disp;

    // Clock & reset
    logic clk;
    logic rst;

    // IFETCH inputs
    logic [31:0] ifetch_pc_plus_four;
    logic [31:0] ifetch_instruction;
    logic        ifetch_empty_flag;

    // CDB
    logic [6:0]  cdb_tag;
    logic        cdb_valid;
    logic [31:0] cdb_data;
    logic        cdb_branch;
    logic        cdb_branch_taken;

    // Dispatcher outputs
    logic [31:0] dispatch_jmp_branch_addr;
    logic        dispatch_jump_branch;
    logic        dispatch_ren;

    logic        en_div_dispatch;
    logic        en_mult_dispatch;
    logic        en_store_load_dispatch;
    logic        en_int_dispatch;

    int_queue_data    dispatcher_2_int_queue;
    lw_sw_queue_data  dispatcher_2_lw_sw_queue;
    queue_data        dispatcher_2_mult_or_div;

    // Instantiate DUT
    dispatcher DUT(
        .clk(clk),
        .rst(rst),
        .ifetch_pc_plus_four(ifetch_pc_plus_four),
        .ifetch_instruction(ifetch_instruction),
        .ifetch_empty_flag(ifetch_empty_flag),

        .cdb_tag(cdb_tag),
        .cdb_valid(cdb_valid),
        .cdb_data(cdb_data),
        .cdb_branch(cdb_branch),
        .cdb_branch_taken(cdb_branch_taken),

        .dispatch_jmp_branch_addr(dispatch_jmp_branch_addr),
        .dispatch_jump_branch(dispatch_jump_branch),
        .dispatch_ren(dispatch_ren),

        .en_div_dispatch(en_div_dispatch),
        .en_mult_dispatch(en_mult_dispatch),
        .en_store_load_dispatch(en_store_load_dispatch),
        .en_int_dispatch(en_int_dispatch),

        .dispatcher_2_int_queue(dispatcher_2_int_queue),
        .dispatcher_2_lw_sw_queue(dispatcher_2_lw_sw_queue),
        .dispatcher_2_mult_or_div(dispatcher_2_mult_or_div)
    );

    // ********************************************************************
    // CLOCK GENERATION
    // ********************************************************************
    always #5 clk = ~clk; // 100 MHz

    // ********************************************************************
    // TASKS
    // ********************************************************************

    task apply_instruction(input [31:0] pc4, input [31:0] instr);
        begin
            ifetch_pc_plus_four = pc4;
            ifetch_instruction  = instr;
            ifetch_empty_flag   = 0;
            @(posedge clk);
        end
    endtask

    task publish_cdb(
        input logic [6:0] tag,
        input logic [31:0] data
    );
        begin
            cdb_tag   = tag;
            cdb_data  = data;
            cdb_valid = 1;
            @(posedge clk);
            cdb_valid = 0;
        end
    endtask

    // ********************************************************************
    // INITIALIZATION
    // ********************************************************************

    initial begin
        clk = 0;
        rst = 1;

        ifetch_pc_plus_four = 32'b0;
        ifetch_instruction  = 32'b0;
        ifetch_empty_flag   = 1;

        cdb_tag   = 0;
        cdb_valid = 0;
        cdb_data  = 0;
        cdb_branch = 0;
        cdb_branch_taken = 0;

        repeat(3) @(posedge clk);
        rst = 0;

        $display("==== INICIO DE PRUEBAS DEL DISPATCHER ====");

        // ****************************************************************
        // 1) INSTRUCCIÓN R-TYPE -> genera RD, RS1, RS2
        //      add x5, x1, x2   (func7=0, rs2=2, rs1=1, func3=0, rd=5, opcode=0x33)
        // ****************************************************************
        apply_instruction(
            32'h00400004,
            32'b0000000_00010_00001_000_00101_0110011
        );
        @(posedge clk);

        // ****************************************************************
        // 2) Consumir token del Tag FIFO vía CDB
        // ****************************************************************
        publish_cdb(7'd3, 32'hDEADBEEF);

        // ****************************************************************
        // 3) INSTRUCCIÓN tipo I (ADDI x8, x1, 10)
        // ****************************************************************
        apply_instruction(
            32'h00400008,
            32'b000000001010_00001_000_01000_0010011
        );
        @(posedge clk);

        // ****************************************************************
        // 4) Simular un BRANCH TAKEN reportado por CDB
        // ****************************************************************
        cdb_branch = 1;
        cdb_branch_taken = 1;
        publish_cdb(7'd4, 32'h12345678);
        cdb_branch = 0;
        cdb_branch_taken = 0;

        // Final de simulación
        repeat(10) @(posedge clk);
        $display("==== FIN DE SIMULACIÓN ====");
    end

    // ********************************************************************
    // MONITOR (muy útil al depurar)
    // ********************************************************************
    initial begin
        $monitor("[%0t] PC+4=%h | OPC=%h | RS1=%0d | RS2=%0d | RD=%0d | REN=%b | JMP=%b | TAGOUT=%0d",
            $time,
            ifetch_pc_plus_four,
            ifetch_instruction[6:0],
            DUT.instr_rs1_addr,
            DUT.instr_rs2_addr,
            DUT.instr_rd_addr,
            dispatch_ren,
            dispatch_jump_branch,
            DUT.Tagout_tf_W
        );
    end

endmodule
