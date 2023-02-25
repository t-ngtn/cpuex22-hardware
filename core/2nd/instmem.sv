`include "params.vh"
`default_nettype none
module InstMem(
    input wire clk,
    input wire rstn,
    input wire [17:0] a,
    input wire [31:0] wd,
    input wire we,
    input wire stall,
    input wire flush,
    output reg [31:0] inst
);

    (* ram_style = "BLOCK" *) reg [31:0] inst_ram [30000:0];
    reg [17:0] prog_idx;

    always_ff @( posedge clk ) begin
        if (~rstn) begin
            prog_idx <= 0;
        end
        
        if (we) begin
            inst_ram[prog_idx] <= wd;
            prog_idx <= prog_idx + 1;
        end
        
        if (stall) begin
        end else if (flush) begin
            inst <= 32'b00000000000000000000000000001000;  // addi x0 x0 0
        end else begin
            inst <= inst_ram[a];
        end
    end

endmodule // InstMem
`default_nettype wire