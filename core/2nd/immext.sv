`include "params.vh"
`default_nettype none
module ImmExt(
    input wire [24:0] imm,
    input wire [2:0] imm_src,
    output wire [31:0] imm_ext,
    output wire [31:0] imm_ext2
);

    assign imm_ext = (
        (imm_src == 3'b000) ? {{19{imm[24]}}, imm[24:12]} :
        (imm_src == 3'b001) ? {imm[24:6], 13'b0} :
        (imm_src == 3'b010) ? {{20{imm[24]}}, imm[24:18], imm[5:0]} :
        (imm_src == 3'b011) ? {{26{imm[17]}}, imm[17:12]} :
        (imm_src == 3'b100) ? {{13{imm[24]}}, imm[24:6]} :
                              32'd0
    );

    assign imm_ext2 = (imm_src == 3'b011) ? {{20{imm[24]}}, imm[24:18], imm[5:0]} : 32'b0;

endmodule
`default_nettype wire