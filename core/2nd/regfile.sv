`include "params.vh"
`default_nettype none
module RegFile(
    input wire clk,
    input wire rstn,
    input wire [5:0] a1,
    input wire [5:0] a2,
    input wire [5:0] a3,
    input wire [31:0] wd,
    input wire we,
    input wire stall,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] rf [63:0];
    integer i;
    initial begin
        for (int i=0; i<64; i = i+1) begin
            rf[i] = 0;
        end
    end

    assign rd1 = (we && a1 == a3 && a1 != 0) ? wd : rf[a1];
    assign rd2 = (we && a2 == a3 && a2 != 0) ? wd : rf[a2];

    initial begin
        rf[0] = 0;
    end

    always_ff @( posedge clk ) begin
        if (we && a3 != 0 && ~stall) begin
            rf[a3] <= wd;
        end
    end

endmodule // RegFile
`default_nettype wire