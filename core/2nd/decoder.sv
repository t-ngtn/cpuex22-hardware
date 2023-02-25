`include "params.vh"
`default_nettype none
module Decoder(
    input wire [3:0] op,
    input wire [2:0] funct3,

    output wire [2:0] result_src,
    output wire mem_write,
    output wire alu_src,
    output wire [2:0] imm_src,
    output wire reg_write,
    output wire branch,
    output wire jump,

    output wire [2:0] alu_ctl,
    output wire [4:0] fpu_ctl,
    output wire is_fpu,

    output wire is_jalr,
    output wire is_load,
    output wire is_in,
    output wire is_out
);

    // op type
    localparam LW_TYPE    = 4'b0000;  // lw
    localparam I_TYPE     = 4'b0001;  // addi, slli, xori, srai
    localparam JALR_TYPE  = 4'b0010;  // jalr
    localparam LUI_TYPE   = 4'b0011;  // lui
    localparam AUIPC_TYPE = 4'b0100;  // auipc
    localparam S_TYPE     = 4'b0101;  // sw
    localparam R_TYPE     = 4'b0110;  // add, sub, xor
    localparam RF_TYPE    = 4'b1100;  // fadd, fsub, fmul, fdiv, faddabs
    localparam C_TYPE     = 4'b1101;  // fsqrt, fcvtws, fcvtsw, fneg, fabs
    localparam BI_TYPE    = 4'b0111;  // bnei, blti
    localparam B_TYPE     = 4'b1000;  // bne, blt
    localparam BF_TYPE    = 4'b1110;  // feq, fle
    localparam JAL_TYPE   = 4'b1001;  // jal
    localparam IN_TYPE    = 4'b1010;  // in
    localparam OUT_TYPE   = 4'b1011;  // out

    // main decoder
    assign result_src = (
        (op == I_TYPE || op == S_TYPE || op == R_TYPE || op == RF_TYPE || 
         op == C_TYPE || op == BI_TYPE || op == B_TYPE || op == BF_TYPE || op == OUT_TYPE) ? 3'b000 :
        (op == LW_TYPE || op == IN_TYPE)                                                   ? 3'b001 :
        (op == JALR_TYPE || op == JAL_TYPE)                                                ? 3'b010 :
        (op == LUI_TYPE)                                                                   ? 3'b011 :
        (op == AUIPC_TYPE)                                                                 ? 3'b100 :
                                                                                             3'b111
    );
    assign mem_write = (op == S_TYPE) ? 1'b1 :1'b0;
    assign alu_src = (op == LW_TYPE || op == I_TYPE || op == JALR_TYPE || op == S_TYPE || op == BI_TYPE) ? 1'b1 : 1'b0;
    assign imm_src = (
        (op == LW_TYPE || op == I_TYPE || op == JALR_TYPE) ? 3'b000 :
        (op == LUI_TYPE || op == AUIPC_TYPE)               ? 3'b001 :
        (op == S_TYPE || op == B_TYPE || op == BF_TYPE)    ? 3'b010 :
        (op == BI_TYPE)                                    ? 3'b011 :
        (op == JAL_TYPE)                                   ? 3'b100 :
                                                             3'b111
    );
    assign reg_write = (
        (op == LW_TYPE || op == I_TYPE || op == JALR_TYPE || op == LUI_TYPE || 
         op == AUIPC_TYPE || op == R_TYPE || op == RF_TYPE || op == C_TYPE || op == JAL_TYPE || op == IN_TYPE) ? 1'b1 : 1'b0
    );
    assign branch = (op == BI_TYPE || op == B_TYPE || op == BF_TYPE) ? 1'b1 : 1'b0;
    assign jump = (op == JALR_TYPE || op == JAL_TYPE) ? 1'b1 : 1'b0;

    // alu controller
    assign alu_ctl = funct3;

    // fpu controller
    assign is_fpu = (op[3:2] == 2'b11) ? 1 : 0;
    assign fpu_ctl = (is_fpu) ? {op[1:0], funct3} : 5'b11111;

    assign is_jalr = (op == JALR_TYPE) ? 1'b1 : 1'b0;
    assign is_load = (op == LW_TYPE) ? 1'b1 : 1'b0;
    assign is_in = (op == IN_TYPE) ? 1'b1 : 1'b0;
    assign is_out = (op == OUT_TYPE) ? 1'b1 : 1'b0;


endmodule // Decoder
`default_nettype wire