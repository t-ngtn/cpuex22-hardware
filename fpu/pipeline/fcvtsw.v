`default_nettype none

module Fcvtsw(
    input wire [31:0] x,
    output reg [31:0] y,
    input wire clk,
    input wire rstn
);

// Stage 1
    wire is_zero;
    assign is_zero = (x == 0);

    wire s;
    assign s = x[31];

    wire [31:0] m1;
    assign m1 = s ? -x : x;

    wire [4:0] shifts;
    assign shifts = (
        m1[31] ? 0  :
        m1[30] ? 1  :
        m1[29] ? 2  :
        m1[28] ? 3  :
        m1[27] ? 4  :
        m1[26] ? 5  :
        m1[25] ? 6  :
        m1[24] ? 7  :
        m1[23] ? 8  :
        m1[22] ? 9  :
        m1[21] ? 10 :
        m1[20] ? 11 :
        m1[19] ? 12 :
        m1[18] ? 13 :
        m1[17] ? 14 :
        m1[16] ? 15 :
        m1[15] ? 16 :
        m1[14] ? 17 :
        m1[13] ? 18 :
        m1[12] ? 19 :
        m1[11] ? 20 :
        m1[10] ? 21 :
        m1[ 9] ? 22 :
        m1[ 8] ? 23 :
        m1[ 7] ? 24 :
        m1[ 6] ? 25 :
        m1[ 5] ? 26 :
        m1[ 4] ? 27 :
        m1[ 3] ? 28 :
        m1[ 2] ? 29 :
        m1[ 1] ? 30 :
        31
    );

// Stage 2
    reg is_zero_st2;
    reg s_st2;
    reg [31:0] m1_st2;
    reg [4:0] shifts_st2;

    always @(posedge clk) begin
        is_zero_st2 <= is_zero;
        s_st2 <= s;
        m1_st2 <= m1;
        shifts_st2 <= shifts;
    end

    wire [31:0] m2;
    assign m2 = m1_st2 << shifts_st2;
    wire [31:0] m3;
    assign m3 = m2 + {24'b0, 8'b1000000};
    wire [22:0] m;
    assign m = is_zero_st2 ? 0 : m3[30:8];

    wire [7:0] e;
    assign e = is_zero_st2 ? 0 : (m3[31] ? 158 - shifts_st2 : 159 - shifts_st2);

// stage 3
    always @(posedge clk) begin
       y <= {s_st2, e, m}; 
    end

endmodule

`default_nettype wire