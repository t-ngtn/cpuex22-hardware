`include "params.vh"
`default_nettype none
module FPU(
    input wire clk,
    input wire rstn,
    input wire [31:0] src_a,
    input wire [31:0] src_b,
    input wire [4:0] fpu_ctl,
    input wire core_stall,
    output wire [31:0] fpu_result,
    output wire fpu_stall,
    output wire fpu_hit
);

    // fpu_ctl
    localparam FADD    = 5'b00000;  // 4 stall
    localparam FSUB    = 5'b00001;  // 4 stall
    localparam FMUL    = 5'b00010;  // 3 stall
    localparam FDIV    = 5'b00011;  // 5 stall
    localparam FADDABS = 5'b00100;  // 4 stall
    localparam FSQRT   = 5'b01000;  // 2 stall
    localparam FCVTWS  = 5'b01001;  // 2 stall
    localparam FCVTSW  = 5'b01010;  // 2 stall
    localparam FNEG    = 5'b01011;  // 0 stall
    localparam FABS    = 5'b01100;  // 0 stall
    localparam FEQ     = 5'b10000;  // 0 stall
    localparam FLE     = 5'b10001;  // 0 stall

    reg stall_reg;
    initial begin
        stall_reg <= 1;
        status <= 0;
    end

    assign fpu_stall = (fpu_ctl == FADD || fpu_ctl == FSUB || fpu_ctl == FMUL || fpu_ctl == FDIV || fpu_ctl == FADDABS || fpu_ctl == FSQRT || fpu_ctl == FCVTWS || fpu_ctl == FCVTSW) ? stall_reg : 0;

    reg [2:0] status;
    always @(posedge clk) begin

        if (status == 0 && fpu_ctl != 5'b11111) begin
            // if (fpu_ctl == FCVTWS ||  fpu_ctl == FCVTSW) begin
            //     stall_reg <= 0;
            //     status <= 5;
            // end else 
            if (fpu_ctl == FADD || fpu_ctl == FSUB || fpu_ctl == FMUL || fpu_ctl == FDIV || fpu_ctl == FADDABS || fpu_ctl == FSQRT || fpu_ctl == FCVTWS ||  fpu_ctl == FCVTSW)begin
                status <= 1;
            end
        end 
        else if (status == 1) begin
            if (fpu_ctl == FSQRT || fpu_ctl == FCVTWS ||  fpu_ctl == FCVTSW) begin
                stall_reg <= 0;
                status <= 5;
            end else begin
                status <= 2;
            end
        end
        else if (status == 2) begin
            if (fpu_ctl == FMUL) begin
                stall_reg <= 0;
                status <= 5;
            end else begin
                status <= 3;
            end
        end 
        else if (status == 3) begin
            if (fpu_ctl == FADD || fpu_ctl == FSUB || fpu_ctl == FADDABS) begin
                stall_reg <= 0;
                status <= 5;
            end else begin
                status <= 4;
            end
        end
        else if (status == 4) begin
            if (fpu_ctl == FDIV) begin
                stall_reg <= 0;
                status <= 5;
            end
        end
        else if (status == 5) begin
            if (~core_stall) begin
                stall_reg <= 1;
                status <= 0;
            end
        end
    end
    
    wire [31:0] y_fadd;
    Fadd fadd(src_a, src_b, y_fadd, clk, rstn);
    wire [31:0] y_fsub;
    Fsub fsub(src_a, src_b, y_fsub, clk, rstn);
    wire [31:0] y_fmul;
    Fmul fmul(src_a, src_b, y_fmul, clk, rstn);
    wire [31:0] y_fdiv;
    Fdiv fdiv(src_a, src_b ,y_fdiv, clk, rstn);
    wire [31:0] y_fsqrt;
    Fsqrt fsqrt(src_a, y_fsqrt, clk, rstn);
    wire [31:0] y_fcvtws;
    Fcvtws fcvtws(src_a, y_fcvtws, clk, rstn);
    wire [31:0] y_fcvtsw;
    Fcvtsw fcvtsw(src_a, y_fcvtsw, clk, rstn);
    wire [31:0] y_fneg;
    Fneg fneg(src_a, y_fneg);
    wire [31:0] y_fabs;
    Fabs fabs(src_a, y_fabs);
    wire [31:0] y_feq;
    Feq feq(src_a, src_b, y_feq);
    wire [31:0] y_fle;
    Fle fle(src_a, src_b, y_fle);

    assign fpu_result = (
        (fpu_ctl == FADD)    ? y_fadd               : 
        (fpu_ctl == FSUB)    ? y_fsub               :
        (fpu_ctl == FMUL)    ? y_fmul               :
        (fpu_ctl == FDIV)    ? y_fdiv               :
        (fpu_ctl == FADDABS) ? {1'b0, y_fadd[30:0]} :
        (fpu_ctl == FSQRT)   ? y_fsqrt              :
        (fpu_ctl == FCVTWS)  ? y_fcvtws             :
        (fpu_ctl == FCVTSW)  ? y_fcvtsw             :
        (fpu_ctl == FNEG)    ? y_fneg               :
        (fpu_ctl == FABS)    ? y_fabs               :
        (fpu_ctl == FEQ)     ? y_feq                :
        (fpu_ctl == FLE)     ? y_fle                :
        32'b0
    );

    assign fpu_hit = (fpu_ctl == FEQ || fpu_ctl == FLE) ? fpu_result[0] : 0;


endmodule // FPU
`default_nettype wire