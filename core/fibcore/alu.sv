`include "params.vh"

`default_nettype none

module ALU(
    input wire [2:0] alu_ctl,
    input wire [31:0] src_a,
    input wire [31:0] src_b,
    output wire [31:0] alu_result,
    output wire zero
    );

    assign zero = (alu_result == 0);

    assign alu_result = (alu_ctl == 3'b000) ? $signed(src_a) + $signed(src_b) :
                        (alu_ctl == 3'b001) ? $signed(src_a) - $signed(src_b) :
                        0;

endmodule // ALU

`default_nettype wire