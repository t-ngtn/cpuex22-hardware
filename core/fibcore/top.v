`default_nettype none

module top(
    input wire CLK100MHZ,
    input wire CPU_RESETN,
    output wire [15:0] LED
);

reg [25:0] clk = 0;

always @(posedge CLK100MHZ) begin
    clk <= clk + 1;
end

Core core(.clk(clk[25]), .rstn(CPU_RESETN), .led(LED));

endmodule

`default_nettype wire