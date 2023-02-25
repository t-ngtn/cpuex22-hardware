`include "params.vh"
`default_nettype none
(* use_dsp = "yes" *) module Core(
    input wire clk,
    input wire rstn,
    input wire io_stall,
    output wire inst_stall,
    output wire flush,
    
    // InstMem
    output reg [17:0] pcF,
    input wire [31:0] instD,

    // Memory
    input wire [31:0] read_dataM,
    input wire data_ready,
    output reg [31:0] calc_resultM,
    output reg [31:0] write_dataM,
    output reg mem_writeM,
    
    output reg is_loadM,
    output reg is_inM, 
    output reg is_outM
);

// wire & reg definition
    // program counter
    logic [17:0] pcD, pcE;
    logic [17:0] pc_plus1F, pc_plus1D, pc_plus1E, pc_plus1M, pc_plus1W;
    logic [17:0] pc_nextF, pc_targetE, pc_targetM, pc_targetW;

    // decoded
    logic [2:0] result_srcD, result_srcE, result_srcM, result_srcW;
    logic mem_writeD, mem_writeE;
    logic alu_srcD, alu_srcE;
    logic [2:0] imm_srcD, imm_srcE;
    logic reg_writeD, reg_writeE, reg_writeM, reg_writeW;
    logic branchD, branchE;
    logic jumpD, jumpE;
    logic [2:0] alu_ctlD, alu_ctlE;
    logic [4:0] fpu_ctlD, fpu_ctlE;
    logic is_jalrD, is_jalrE, is_loadD, is_loadE;
    logic is_fpuD, is_fpuE, is_inD, is_inE, is_outD, is_outE;

    logic [5:0] rs1E, rs2E, rdD, rdE, rdM, rdW;

    // register file
    logic [31:0] reg1D, reg2D, reg1E, reg2E;

    // immediate
    logic [31:0] imm_extD, imm_extE, imm_extM, imm_extW, imm_ext2D, imm_ext2E;

    // excution
    logic [31:0] src_aE, src_bE, _src_bE;
    logic [31:0] alu_resultE, fpu_resultE, calc_resultE, calc_resultW;
    logic alu_hitE, fpu_hitE;
    logic fpu_stall;
    logic pc_srcE;

    // memory access
    logic mem_stall;

    // write back
    logic [31:0] resultW, read_dataW;

    // hazard 
    logic stall, stallF, stallD, flushD, flushE;
    logic [1:0] forwardAE, forwardBE;



// data path
    assign stall = io_stall || mem_stall || fpu_stall;
    assign inst_stall = mem_stall || fpu_stall || stallD;
    assign flush = flushD;

    // Inst Fetch
    assign pc_plus1F = pcF + 1;
    assign pc_nextF = (pc_srcE) ? ((is_jalrE) ? alu_resultE : pc_targetE) : pc_plus1F;

    always_ff @( posedge clk ) begin
        if (~rstn) begin
            pcF <= 0;
        end else if (stallF || stall) begin
        end else begin
            pcF <= pc_nextF;
        end
    end

    // Decode & Reg
    always_ff @( posedge clk ) begin
        if (~rstn) begin
            pcD <= 0; pc_plus1D <= 0;
        end else if (stallD || stall) begin
        end else if (flushD) begin
            pcD <= 0; pc_plus1D <= 0;
        end else begin
            pcD <= pcF; pc_plus1D <= pc_plus1F;
        end
    end

    assign rdD = instD[12:7];

    Decoder decoder(
        .op(instD[6:3]),
        .funct3(instD[2:0]),
        .result_src(result_srcD),
        .mem_write(mem_writeD),
        .alu_src(alu_srcD),
        .imm_src(imm_srcD),
        .reg_write(reg_writeD),
        .branch(branchD),
        .jump(jumpD),
        .alu_ctl(alu_ctlD),
        .fpu_ctl(fpu_ctlD),
        .is_fpu(is_fpuD),
        .is_jalr(is_jalrD),
        .is_load(is_loadD),
        .is_in(is_inD),
        .is_out(is_outD)
    );

    RegFile regfile(
        .clk(clk),
        .rstn(rstn),
        .a1(instD[18:13]),
        .a2(instD[24:19]),
        .a3(rdW),
        .wd(resultW),
        .we(reg_writeW),
        .stall(stall),
        .rd1(reg1D),
        .rd2(reg2D)
    );

    ImmExt immext(
        .imm(instD[31:7]),
        .imm_src(imm_srcD),
        .imm_ext(imm_extD),
        .imm_ext2(imm_ext2D)
    );

    // Excute
    always_ff @( posedge clk ) begin
        if (~rstn) begin
            pcE <= 0; pc_plus1E <= 0; imm_extE <= 0; imm_ext2E <= 0;
            result_srcE <= 0; mem_writeE <= 0; alu_srcE <= 0; reg_writeE <= 0; imm_srcE <= 0;
            branchE <= 0; jumpE <= 0; alu_ctlE <= 0; fpu_ctlE <= 5'b11111; is_jalrE <= 0; is_loadE <= 0;     
            is_fpuE <= 0; is_inE <= 0; is_outE <= 0; rs1E <= 0; rs2E <= 0; rdE <= 0;
            reg1E <= 0; reg2E <= 0;
        end else if (stall) begin
        end else if (flushE) begin
            pcE <= 0; pc_plus1E <= 0; imm_extE <= 0; imm_ext2E <= 0; 
            result_srcE <= 0; mem_writeE <= 0; alu_srcE <= 0; reg_writeE <= 0; imm_srcE <= 0; 
            branchE <= 0; jumpE <= 0; alu_ctlE <= 0; fpu_ctlE <= 5'b11111; is_jalrE <= 0; is_loadE <= 0;     
            is_fpuE <= 0; is_inE <= 0; is_outE <= 0; rs1E <= 0; rs2E <= 0; rdE <= 0;
            reg1E <= 0; reg2E <= 0;
        end else begin
            pcE <= pcD; pc_plus1E <= pc_plus1D; imm_extE <= imm_extD; imm_ext2E <= imm_ext2D; imm_srcE <= imm_srcD;
            result_srcE <= result_srcD; mem_writeE <= mem_writeD; alu_srcE <= alu_srcD; reg_writeE <= reg_writeD;  
            branchE <= branchD; jumpE <= jumpD; alu_ctlE <= alu_ctlD; fpu_ctlE <= fpu_ctlD; is_jalrE <= is_jalrD; 
            is_loadE <= is_loadD; is_fpuE <= is_fpuD; is_inE <= is_inD; is_outE <= is_outD; rs1E <= instD[18:13]; 
            rs2E <= instD[24:19]; rdE <= rdD; reg1E <= reg1D; reg2E <= reg2D;
        end
    end

    assign src_aE = (
        (forwardAE == 2'b00) ? reg1E :
        (forwardAE == 2'b01) ? resultW :
        (forwardAE == 2'b10) ? calc_resultM :
        imm_extM
    );

    assign _src_bE = (
        (forwardBE == 2'b00) ? reg2E :
        (forwardBE == 2'b01) ? resultW :
        (forwardBE == 2'b10) ? calc_resultM :
        imm_extM
    );

    assign src_bE = (alu_srcE) ? imm_extE : _src_bE;

    ALU alu(
        .alu_ctl(alu_ctlE),
        .src_a(src_aE),
        .src_b(src_bE),
        .alu_result(alu_resultE),
        .alu_hit(alu_hitE)
    );

    FPU fpu(
        .clk(clk),
        .rstn(rstn),
        .src_a(src_aE),
        .src_b(src_bE),
        .fpu_ctl(fpu_ctlE),
        .core_stall(io_stall || mem_stall),
        .fpu_result(fpu_resultE),
        .fpu_stall(fpu_stall),
        .fpu_hit(fpu_hitE)
    );

    assign pc_targetE = (imm_srcE == 3'b011) ? pcE + imm_ext2E : pcE + imm_extE;
    assign pc_srcE = (jumpE || (branchE && (alu_hitE || fpu_hitE)));
    assign calc_resultE = (is_fpuE) ? fpu_resultE : alu_resultE;

    // Memory Accsess
    always_ff @( posedge clk ) begin
        if (~rstn) begin
            pc_targetM <= 0; pc_plus1M <= 0; result_srcM <= 0; mem_writeM <= 0; reg_writeM <= 0;
            calc_resultM <= 0; write_dataM <= 0; rdM <= 0; imm_extM <= 0; is_loadM <= 0; 
            is_inM <= 0; is_outM <= 0;
        end else if (stall) begin
        end else begin
            pc_targetM <= pc_targetE; pc_plus1M <= pc_plus1E; result_srcM <= result_srcE; 
            mem_writeM <= mem_writeE; reg_writeM <= reg_writeE; calc_resultM <= calc_resultE; 
            rdM <= rdE; imm_extM <= imm_extE; is_loadM <= is_loadE; is_inM <= is_inE; is_outM <= is_outE;
            if (is_outE) begin
                write_dataM <= src_aE;
            end else begin
                write_dataM <= _src_bE;
            end 
        end
    end

    assign mem_stall = ((is_loadM || mem_writeM || is_inM) && ~data_ready) ? 1 : 0;

    // Write back
    always_ff @( posedge clk ) begin
        if (~rstn) begin
            pc_targetW <= 0; pc_plus1W <= 0; result_srcW <= 0; reg_writeW <= 0; 
            calc_resultW <= 0; read_dataW <= 0; rdW <= 0; imm_extW <= 0;
        end else if (stall) begin 
        end else begin
            pc_targetW <= pc_targetM; pc_plus1W <= pc_plus1M; result_srcW <= result_srcM; 
            reg_writeW <= reg_writeM; calc_resultW <= calc_resultM; read_dataW <= read_dataM; 
            rdW <= rdM; imm_extW <= imm_extM;
        end
    end

    assign resultW = (
        (result_srcW == 3'b000) ? calc_resultW :
        (result_srcW == 3'b001) ? read_dataW   : 
        (result_srcW == 3'b010) ? pc_plus1W    : 
        (result_srcW == 3'b011) ? imm_extW     : 
        (result_srcW == 3'b100) ? pc_targetW   : 
                                  32'b0
    );

    Hazard hazard(
        .rs1D(instD[18:13]),
        .rs2D(instD[24:19]),
        .rs1E(rs1E),
        .rs2E(rs2E),
        .rdE(rdE),
        .rdM(rdM),
        .rdW(rdW),
        .is_lwE(is_loadE || is_inE),
        .is_extM(result_srcM == 3'b011 || result_srcM == 3'b100),
        .pc_srcE(pc_srcE),
        .reg_writeM(reg_writeM),
        .reg_writeW(reg_writeW),
        .stallF(stallF),
        .stallD(stallD),
        .flushD(flushD),
        .flushE(flushE),
        .forwardAE(forwardAE),
        .forwardBE(forwardBE)
    );

endmodule // Core
`default_nettype wire