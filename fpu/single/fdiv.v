`default_nettype none

module Fdiv(input wire [31:0] x1,
            input wire [31:0] x2,
           output wire [31:0] y);

    // 入力分解
    wire s1;
    wire [7:0] e1;
    wire [22:0] m1;
    assign {s1, e1, m1} = x1;

    wire s2;
    wire [7:0] e2;
    wire [22:0] m2;
    assign {s2, e2, m2} = x2;

    // 1.{m3} / 2 = 1 / 1.{m2}
    wire [22:0] m3;
    Finv finv(.x(m2), .y(m3));

    // 1.{m1} * 1.{m3}
    wire [25:0] my1;
    Mul23 mul23(.m1(m1), .m2(m3), .my(my1));

    // 仮数部の計算
    wire carry;
    assign carry = my1[25];
    wire [22:0] my2;
    assign my2 = carry ? my1[24:2] : my1[23:1];

    // 指数部の計算
    wire [9:0] ey1;
    assign ey1 = {2'b0, e1} - {2'b0, e2} + 10'd126;
    wire [9:0] ey2;
    assign ey2 = ey1 + 10'd1;

    wire [9:0] ey3;
    assign ey3 = carry ? ey2 : ey1;

    // 例外処理
    wire underflow;
    assign underflow = (e1 == 8'b0 || e2 == 8'd255 || ey3[9] || ey3 == 10'b0);
    wire overflow;
    assign overflow = (e1 == 8'd255 || e2 == 8'b0 || ey3[8] || ey3 == 10'd255);

    // 出力
    wire sy;
    assign sy = s1 ^ s2;
    wire [7:0] ey;
    assign ey = underflow ? 8'b0 : (overflow ? 8'd255 : ey3[7:0]);
    wire [22:0] my;
    assign my = underflow ? 23'b0 : (overflow ? 23'b0 : my2);

    assign y = {sy, ey, my};

endmodule

`default_nettype wire