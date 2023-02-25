`include "params.vh"

`default_nettype none
module DataMem(
    input wire clk,
    input wire [31:0] a,
    input wire [31:0] wd,
    input wire we,
    output wire [31:0] rd
    );

    (* ram_style = "BLOCK" *) reg [31:0] ram [4095:0];

    assign rd = ram[a];

    always_ff @( posedge clk ) begin : write
        if (we) begin
                ram[a] <= wd;
        end
    end

endmodule // DataMem
`default_nettype wire