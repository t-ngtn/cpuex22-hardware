`default_nettype none

module Fsqrt(input wire [31:0] x,
            output wire [31:0] y);

    (* ram_style = "BLOCK" *) reg [35:0] ram [1023:0];

    initial begin
        $readmemb("C:/Users/tansei/Desktop/cpu/fpu/single/fsqrt.dat", ram);
    end

    // 入力分解
    wire s;
    wire [7:0] e;
    wire [22:0] m;
    assign {s, e, m} = x;

    // 傾きaと切片bの取得
    wire in_2_4;
    assign in_2_4 = (e[0] == 1'b0);

    wire [9:0] index;
    wire [13:0] d;
    assign {index, d} = {in_2_4, m};

    wire [13:0] a;
    wire [22:0] b;
    assign {a, b} = {1'b1, ram[index]};

    // 仮数部の計算
    wire [27:0] ad1;
    assign ad1 = a * d;

    wire [22:0] ad2;
    assign ad2 = in_2_4 ? {9'b0, ad1[27:14]} : {10'b0, ad1[27:15]};
    
    wire [22:0] my1;
    assign my1 = b + ad2;

    // 指数部の計算
    wire [7:0] ey1;
    assign ey1 = {1'b0, e[7:1]} + 8'd63;

    wire [7:0] ey2;
    assign ey2 = ey1 + 8'd1;

    wire [7:0] ey3;
    assign ey3 = in_2_4 ? ey1 : ey2;

    // 例外処理
    wire is_zero;
    assign is_zero = (e == 8'b0);
    wire is_inf;
    assign is_inf = (e == 8'd255);

    // 出力
    wire sy;
    assign sy = s;
    wire [7:0] ey;
    assign ey = is_zero ? 8'b0 : (is_inf ? 8'd255 : ey3);
    wire [22:0] my;
    assign my = is_zero ? 8'b0 : (is_inf ? 8'b0 : my1);

    assign y = {sy, ey, my};

endmodule

`default_nettype wire