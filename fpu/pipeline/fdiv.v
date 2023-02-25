`default_nettype none

module Fdiv (
    input wire [31:0]  x1,
    input wire [31:0] x2,
    output reg [31:0] y,
    input wire clk,
    input wire rstn
);

// stage 1
    // 入力分解
    wire s1;
    wire [7:0] e1;
    wire [22:0] m1;
    assign {s1, e1, m1} = x1;

    wire s2;
    wire [7:0] e2;
    wire [22:0] m2;
    assign {s2, e2, m2} = x2;

// stage 2, 3
// m3はstage3で使用できる
    // 1.{m3} / 2 = 1 / 1.{m2}
    wire [22:0] m3_st3;
    Finv finv(.x(m2), .y(m3_st3), .clk(clk), .rstn(rstn));

// stage 2
    reg s1_st2, s2_st2;
    reg [7:0] e1_st2, e2_st2;
    reg [22:0] m1_st2;
    always @(posedge clk) begin
        s1_st2 <= s1;
        s2_st2 <= s2;
        e1_st2 <= e1;
        e2_st2 <= e2;
        m1_st2 <= m1;
    end

// stage 3
    reg s1_st3, s2_st3;
    reg [7:0] e1_st3, e2_st3;
    reg [22:0] m1_st3;
    always @(posedge clk) begin
        s1_st3 <= s1_st2;
        s2_st3 <= s2_st2;
        e1_st3 <= e1_st2;
        e2_st3 <= e2_st2;
        m1_st3 <= m1_st2;
    end

    // 1.{m1} * 1.{m3}
    wire [25:0] my1_st4;
    Mul23 mul23(.m1(m1_st3), .m2(m3_st3), .my(my1_st4), .clk(clk), .rstn(rstn));

// stage 4
    reg s1_st4, s2_st4;
    reg [7:0] e1_st4, e2_st4;
    always @(posedge clk) begin
        s1_st4 <= s1_st3;
        s2_st4 <= s2_st3;
        e1_st4 <= e1_st3;
        e2_st4 <= e2_st3;
    end

// stage 5
    reg s1_st5, s2_st5;
    reg [7:0] e1_st5, e2_st5;
    reg [25:0] my1_st5;
    always @(posedge clk) begin
        s1_st5 <= s1_st4;
        s2_st5 <= s2_st4;
        e1_st5 <= e1_st4;
        e2_st5 <= e2_st4;
        my1_st5 <= my1_st4;
    end

    // 仮数部の計算
    wire carry;
    assign carry = my1_st5[25];
    wire [22:0] my2;
    assign my2 = carry ? my1_st5[24:2] : my1_st5[23:1];

    // 指数部の計算
    wire [9:0] ey1;
    assign ey1 = {2'b0, e1_st5} - {2'b0, e2_st5} + 10'd126;
    wire [9:0] ey2;
    assign ey2 = ey1 + 10'd1;

    wire [9:0] ey3;
    assign ey3 = carry ? ey2 : ey1;

    // 例外処理
    wire underflow;
    assign underflow = (e1_st5 == 8'b0 || e2_st5 == 8'd255 || ey3[9] || ey3 == 10'b0);
    wire overflow;
    assign overflow = (e1_st5 == 8'd255 || e2_st5 == 8'b0 || ey3[8] || ey3 == 10'd255);

    // 出力
    wire sy;
    assign sy = s1_st5 ^ s2_st5;
    wire [7:0] ey;
    assign ey = underflow ? 8'b0 : (overflow ? 8'd255 : ey3[7:0]);
    wire [22:0] my;
    assign my = underflow ? 23'b0 : (overflow ? 23'b0 : my2);

// stage 6
    always @(posedge clk) begin
        y <= {sy, ey, my};    
    end

endmodule

`default_nettype wire