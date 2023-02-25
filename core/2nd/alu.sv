`include "params.vh"
`default_nettype none
module ALU(
    input wire [2:0] alu_ctl,
    input wire [31:0] src_a,
    input wire [31:0] src_b,
    output wire [31:0] alu_result,
    output wire alu_hit
    );

    // alu_ctl
    parameter ADD = 3'b000;
    parameter SUB = 3'b001;
    parameter XOR = 3'b010;
    parameter SLL = 3'b011;
    parameter SRA = 3'b100;
    parameter BLT = 3'b101;
    parameter BNE = 3'b110;
    
    assign alu_result = (
        (alu_ctl == ADD) ? $signed(src_a) + $signed(src_b) :
        (alu_ctl == SUB) ? $signed(src_a) - $signed(src_b) :
        (alu_ctl == XOR) ? src_a ^ src_b :
        (alu_ctl == SLL) ? src_a << src_b :
        (alu_ctl == SRA) ? $signed(src_a) >>> src_b :
        (alu_ctl == BLT) ? $signed(src_a) < $signed(src_b) :
        (alu_ctl == BNE) ? src_a != src_b :
                           0  
    );

    assign alu_hit = (alu_ctl == BLT || alu_ctl == BNE) ? alu_result[0] : 0;
    
endmodule // ALU
`default_nettype wire