`include "params.vh"

`default_nettype none

module ImmExt(
    input wire [24:0] imm,
    input wire [1:0] imm_src,
    output wire [31:0] imm_ext
    );

    assign imm_ext = (imm_src == 2'b00) ?  {{20{imm[24]}}, imm[24:13]} :  // I形式
                     (imm_src == 2'b01) ?  {{20{imm[24]}}, imm[24:8], imm[4:0]} :  // S形式
                     (imm_src == 2'b10) ?  {{20{imm[24]}}, imm[0], imm[23:18], imm[4:1], 1'b0} :  // B形式
                     (imm_src == 2'b11) ?  {{12{imm[24]}}, imm[12:5], imm[13], imm[23:14], 1'b0}:  // J形式
                     0;

endmodule // ImmExt

`default_nettype wire