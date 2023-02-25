`default_nettype none

module Fneg(
    input wire [31:0] x,
    output wire [31:0] y
);
    wire sx;
    assign sx = x[31];

    wire sy;
    assign sy = ~sx;

    assign y = {sy, x[30:0]};

endmodule
`default_nettype wire