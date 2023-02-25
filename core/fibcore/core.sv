`include "params.vh"

`default_nettype none

module Core(
    input wire clk,
    input wire rstn,
    output wire [15:0] led
    );

    reg [11:0] pc;
    wire [11:0] pc_plus4;
    wire [11:0] pc_next;
    wire [11:0] pc_target;
    assign pc_plus4 = pc + 4;
    wire [31:0] inst;

    wire pc_src; 
    wire result_src; 
    wire mem_write; 
    wire [2:0] alu_ctl; 
    wire alu_src; 
    wire [1:0] imm_src; 
    wire reg_write;

    wire [31:0] imm_ext;

    wire [31:0] src_a;
    wire [31:0] src_b;
    wire [31:0] _src_b;
    wire [31:0] alu_result;
    wire zero;

    wire [31:0] read_data;
    wire [31:0] result;

    InstMem instMem(
        .addr(pc),
        .inst(inst)
    );

    ControlUnit controlUnit(
        .op(inst[6:0]),
        .funct3(inst[14:12]),
        .funct7(inst[30]),
        .zero(zero),
        .pc_src(pc_src), 
        .result_src(result_src), 
        .mem_write(mem_write), 
        .alu_ctl(alu_ctl), 
        .alu_src(alu_src), 
        .imm_src(imm_src), 
        .reg_write(reg_write)
    );

    RegFile regFile(
        .clk(clk),
        .a1(inst[19:15]),
        .a2(inst[24:20]),
        .a3(inst[11:7]),
        .wd3(result),
        .we3(reg_write),
        .rd1(src_a),
        .rd2(_src_b),
        .led(led)
    );

    ImmExt immExt(
        .imm(inst[31:7]),
        .imm_src(imm_src),
        .imm_ext(imm_ext)
    );

    assign src_b = (alu_src) ? imm_ext : _src_b;
    assign pc_target = pc + imm_ext;

    ALU alu(
        .alu_ctl(alu_ctl),
        .src_a(src_a),
        .src_b(src_b),
        .alu_result(alu_result),
        .zero(zero)
    );

    DataMem dataMem(
        .clk(clk),
        .a(alu_result),
        .wd(_src_b),
        .we(mem_write),
        .rd(read_data)
    );

    assign pc_next = (pc_src) ? pc_target : pc_plus4;

    assign result = (result_src == 'b00) ? alu_result :
                    (result_src == 'b01) ? read_data  :
                    pc_plus4;

    always_ff @( posedge clk ) begin : pc_up
        if(~rstn) begin
            pc <= 0;
        end
        else begin
            pc <= pc_next;
        end
    end

endmodule

`default_nettype wire