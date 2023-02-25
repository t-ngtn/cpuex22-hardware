`default_nettype none
module DataMem(
    input wire clk,
    input wire rstn,
    input wire [31:0] a,
    input wire req,
    input wire [31:0] wd,
    input wire we,
    output wire [31:0] rd,
    output reg ready
    );
    `include "params.vh"

    (* ram_style = "BLOCK" *) reg [31:0] ram [10000000:0];

    reg [31:0] _rd;
    integer i;
    initial begin
        for (int i=0; i<81251; i = i+1) begin
            ram[i] = 0;
        end
    end

    assign rd = {_rd[7:0], _rd[15:8], _rd[23:16], _rd[31:24]};
 
    always_ff @( posedge clk ) begin
        if (~rstn) begin
            ready <= 0;
        end

        if (req ) begin
            if (we) begin
                ram[{2'b0, a[31:2]}] <= {wd[7:0], wd[15:8], wd[23:16], wd[31:24]};
            end else begin
                _rd <= ram[{2'b0, a[31:2]}];
            end
            ready <= 1;
        end 

        if (ready) begin
            ready <= 0;
            _rd <= 32'b11111111111111111111111111111111;
        end
    end

endmodule // DataMem
`default_nettype wire