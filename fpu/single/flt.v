`default_nettype none

module Flt(
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y
);

    wire s1;
    wire [30:0] em1;
    assign {s1, em1} = x1;

    wire s2;
    wire [30:0] em2;
    assign {s2, em2} = x2;

    wire res;
    assign res = (s1) ? ((s2) ? (em1 > em2) : 1) : ((s2) ? 0 : (em1 < em2));

    wire is_zero;
    assign is_zero = (em1 == 0 && em2 == 0);

    assign y = is_zero ? 0 : res;

endmodule
`default_nettype wire