`include "params.vh"

`default_nettype none
module ControlUnit(
    input wire [6:0] op, 
    input wire [2:0] funct3, 
    input wire funct7, 
    input wire zero, 
    output wire pc_src, 
    output wire result_src, 
    output wire mem_write, 
    output wire [2:0] alu_ctl, 
    output wire alu_src, 
    output wire [1:0] imm_src, 
    output wire reg_write
	);

	wire branch;
	wire [1:0] alu_op;
	wire op5 = op[5];

	// どの命令か
	wire addi = (op == 7'b0010011) && (funct3 == 3'b000);
	wire add  = (op == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
	wire bne  = (op == 7'b1100011) && (funct3 == 3'b001);

	MainDecoder mainDecoder(.*);

	assign pc_src = (bne) ? (branch && ~zero) : 0;

	ALUDecoder aluDecoder(.*);

endmodule // ControlUnit

module MainDecoder(
	input wire [6:0] op,
	output wire result_src, 
    output wire mem_write,  
    output wire alu_src,
	output wire [1:0] imm_src,
    output wire reg_write,
	output wire [1:0] alu_op,
	output wire branch
	);

	assign {result_src, mem_write, alu_src, imm_src, reg_write, alu_op, branch} = (
			(op == 7'b0110011) ? {1'b0, 1'b0, 1'b0, 2'b00, 1'b1, 2'b00, 1'b0} :  // add
			(op == 7'b0010011) ? {1'b0, 1'b0, 1'b1, 2'b00, 1'b1, 2'b00, 1'b0} :  // addi
			(op == 7'b1100011) ? {1'b0, 1'b0, 1'b0, 2'b10, 1'b0, 2'b01, 1'b1} :  // bne
			0);
endmodule // MainDecoder

module ALUDecoder(
	input wire [1:0] alu_op,
	input wire [2:0] funct3, 
    input wire funct7,
	input wire op5,
	output wire [2:0] alu_ctl
	);

	assign alu_ctl = (alu_op == 2'b00) ? 3'b000 : 3'b001;

endmodule // ALUDecoder

`default_nettype wire