`default_nettype none

module Fadd(input wire [31:0] x1,
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

    // 大小関係を求める
    wire x1_is_bigger;
    assign x1_is_bigger = (x1[30:0] > x2[30:0]);

    wire [7:0] e_big;
    assign e_big = x1_is_bigger ? e1 : e2;
    wire [7:0] e_small;
    assign e_small = x1_is_bigger ? e2 : e1;
    wire [25:0] m_big;
    assign m_big = {2'b01, (x1_is_bigger ? m1 : m2), 1'b0};
    wire [25:0] m_small_prev;
    assign m_small_prev = {2'b01, (x1_is_bigger ? m2 : m1), 1'b0};

    // 小さいほうをビットシフト
    wire [7:0] m_small_shift;
    assign m_small_shift = e_big - e_small;

    wire [25:0] m_small;
    assign m_small = m_small_prev >> m_small_shift;

    // 加算
    wire [25:0] my1;
    assign my1 = (s1 == s2) ? m_big + m_small : m_big - m_small;

    // 最上位ビットを求める
    wire [4:0] my1_shift;
    assign my1_shift =
        my1[25] ?  0 : (
        my1[24] ?  1 : (
        my1[23] ?  2 : (
        my1[22] ?  3 : (
        my1[21] ?  4 : (
        my1[20] ?  5 : (
        my1[19] ?  6 : (
        my1[18] ?  7 : (
        my1[17] ?  8 : (
        my1[16] ?  9 : (
        my1[15] ? 10 : (
        my1[14] ? 11 : (
        my1[13] ? 12 : (
        my1[12] ? 13 : (
        my1[11] ? 14 : (
        my1[10] ? 15 : (
        my1[9]  ? 16 : (
        my1[8]  ? 17 : (
        my1[7]  ? 18 : (
        my1[6]  ? 19 : (
        my1[5]  ? 20 : (
        my1[4]  ? 21 : (
        my1[3]  ? 22 : (
        my1[2]  ? 23 : (
        my1[1]  ? 24 : (
        my1[0]  ? 25 : 26
    )))))))))))))))))))))))));

    // 仮数部をビットシフトで求める
    wire [22:0] my2;
    wire [51:0] _my2;;
    assign _my2 = (my1 << my1_shift);
    assign my2 = _my2[24:2];

    // 指数部を求める
    wire [9:0] ey1;
    assign ey1 = {2'b0, e_big} + 10'd1;

    wire [9:0] ey2;
    assign ey2 = ey1 - {5'b0, my1_shift};

    // 例外処理
    wire e_small_is_zero;
    assign e_small_is_zero = (e_small == 8'b0);
    wire underflow;
    assign underflow = (ey2[9] || (e_big == 8'b0) || (ey2 == 10'b0) || (my1_shift == 5'd26));
    wire overflow;
    assign overflow  = (ey2[8] || (e_big == 8'd255) || (ey2 == 10'd255));

    // 出力
    wire sy;
    assign sy = x1_is_bigger ? s1 : s2;
    wire [7:0] ey;
    assign ey = e_small_is_zero ? e_big : (underflow ? 8'b0 : (overflow ? 8'd255 : ey2[7:0]));
    wire [22:0] my;
    assign my = e_small_is_zero ? m_big[23:1] : (underflow ? 23'b0 : (overflow ? 23'b0 : my2));

    assign y = {sy, ey, my};

endmodule

`default_nettype wire