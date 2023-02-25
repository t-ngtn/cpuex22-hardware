`include "params.vh"

`default_nettype none
module RegFile(
    input wire clk,
    input wire [4:0] a1,
    input wire [4:0] a2,
    input wire [4:0] a3,
    input wire [31:0] wd3,
    input wire we3,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    output wire [15:0] led
    );

    reg [31:0] rf [31:0];

    assign rd1 = (a1 != 0) ? rf[a1] : 0;
    assign rd2 = (a2 != 0) ? rf[a2] : 0;

    assign led = rf[2][15:0];

    always_ff @( posedge clk ) begin : write
        rf[0] <= 0;
        if (we3) begin
            if (a3 != 0) begin
                rf[a3] <= wd3;
            end
        end
    end

endmodule // RegFile

`default_nettype wire