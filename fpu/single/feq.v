`default_nettype none

module Feq(
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y
);

    wire is_zero1;
    assign is_zero1 = (x1[30:0] == 'd0);
    wire is_zero2;
    assign is_zero2 = (x2[30:0] == 'd0);

    assign y = (is_zero1 && is_zero2) ? 1 : (x1 == x2);

endmodule
`default_nettype wire