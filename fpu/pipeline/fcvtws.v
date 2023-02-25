`default_nettype none

module Fcvtws(
    input wire [31:0] x,
    output reg [31:0] y,
    input wire clk,
    input wire rstn
);

// Stage 1
    wire s;
    wire [7:0] e;
    wire [22:0] m;
    assign {s, e, m} = x;

    wire [23:0] m1;
    assign m1 = {1'b1, m};

// Stage 2
    reg s_st2;
    reg [7:0] e_st2;
    reg [22:0] m_st2;
    reg [23:0] m1_st2;

    always @(posedge clk) begin
        s_st2 <= s;
        e_st2 <= e;
        m_st2 <= m;
        m1_st2 <= m1;
    end

    wire [32:0] y1;
    assign y1 = (e_st2 < 149) ? (m1_st2 >> (149 - e_st2)) : (m1_st2 << (e_st2 - 149));

    wire [32:0] y2;
    assign y2 = y1 + 1;

    wire [31:0] y3;
    assign y3 = y2[32:1];

    wire [31:0] _y;
    assign _y = s_st2 ? -y3 : y3;

// stage 3
    always @(posedge clk) begin
       y <= _y; 
    end
    
endmodule
`default_nettype wire