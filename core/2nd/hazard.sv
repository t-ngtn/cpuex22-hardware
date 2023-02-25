`include "params.vh"
`default_nettype none
module Hazard(
    input wire [5:0] rs1D,
    input wire [5:0] rs2D,
    input wire [5:0] rs1E,
    input wire [5:0] rs2E,
    input wire [5:0] rdE,
    input wire [5:0] rdM,
    input wire [5:0] rdW,
    input wire is_lwE,
    input wire is_extM,
    input wire pc_srcE,
    input wire reg_writeM,
    input wire reg_writeW,
    output wire stallF,
    output wire stallD,
    output wire flushD,
    output wire flushE,
    output wire [1:0] forwardAE,
    output wire [1:0] forwardBE
);

    assign forwardAE = (
        ((rs1E == rdM && reg_writeM) && (rs1E != 0)) ? ((is_extM) ? 2'b11 : 2'b10) :
        ((rs1E == rdW && reg_writeW) && (rs1E != 0)) ? 2'b01 :
        2'b00
    );

    assign forwardBE = (
        ((rs2E == rdM && reg_writeM) && (rs2E != 0)) ? ((is_extM) ? 2'b11 : 2'b10) :
        ((rs2E == rdW && reg_writeW) && (rs2E != 0)) ? 2'b01 :
        2'b00
    );

    wire lw_stall;
    assign lw_stall = is_lwE && (rs1D == rdE || rs2D == rdE);
    assign stallF = lw_stall;
    assign stallD = lw_stall;
    assign flushD = pc_srcE;
    assign flushE = lw_stall || pc_srcE;

endmodule
`default_nettype wire