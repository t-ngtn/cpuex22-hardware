`default_nettype none

module Fcvtws(
    input wire [31:0] x,
    output wire [31:0] y
);

    wire s;
    wire [7:0] e;
    wire [22:0] m;
    assign {s, e, m} = x;

    wire [23:0] m1;
    assign m1 = {1'b1, m};

    wire [32:0] y1;
    assign y1 = (e < 149) ? (m1 >> (149 - e)) : (m1 << (e - 149));

    wire [32:0] y2;
    assign y2 = y1 + 1;

    wire [31:0] y3;
    assign y3 = y2[32:1];

    assign y = s ? -y3 : y3;
    
endmodule
`default_nettype wire