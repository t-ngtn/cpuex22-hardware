`default_nettype none

module Fsqrt(
    input wire [31:0] x,
    output reg [31:0] y,
    input wire clk,
    input wire rstn
);
    (* ram_style = "BLOCK" *) reg [35:0] fsqrt_ram [1023:0];

    initial begin
        $readmemb("C:/Users/tansei/Desktop/cpu/fpu/pipeline/fsqrt.dat", fsqrt_ram);
    end

// Stage 1
    // 入力分解
    wire s;
    wire [7:0] e;
    wire [22:0] m;
    assign {s, e, m} = x;

    // 指数部の計算
    wire [7:0] ey1;
    assign ey1 = {1'b0, e[7:1]} + 8'd63;

    wire [7:0] ey2;
    assign ey2 = ey1 + 8'd1;

    wire in_2_4;
    assign in_2_4 = (e[0] == 1'b0);

    wire [7:0] ey3;
    assign ey3 = in_2_4 ? ey1 : ey2;

    // 傾きaと切片bの取得
    wire [9:0] index;
    wire [13:0] d;
    assign {index, d} = {in_2_4, m};

// stage 2
    reg s_st2;
    reg [7:0] e_st2;
    reg in_2_4_st2;
    reg [36:0] ab_st2;
    wire [13:0] a_st2;
    wire [22:0] b_st2;
    reg [7:0] ey3_st2;
    reg [13:0] d_st2;
    always @(posedge clk) begin
        s_st2 <= s;
        e_st2 <= e;
        in_2_4_st2 <= in_2_4;
        ey3_st2 <= ey3;
        ab_st2 <= {1'b1, fsqrt_ram[index]};
        d_st2 <= d;
    end

    assign {a_st2, b_st2} = ab_st2;

    // 仮数部の計算
    wire [27:0] ad1;
    assign ad1 = a_st2 * d_st2;

    wire [22:0] ad2;
    assign ad2 = in_2_4_st2 ? {9'b0, ad1[27:14]} : {10'b0, ad1[27:15]};
    
    wire [22:0] my1;
    assign my1 = b_st2 + ad2;

    // 例外処理
    wire is_zero;
    assign is_zero = (e_st2 == 8'b0);
    wire is_inf;
    assign is_inf = (e_st2 == 8'd255);

    // 出力
    wire sy;
    assign sy = s_st2;
    wire [7:0] ey;
    assign ey = is_zero ? 8'b0 : (is_inf ? 8'd255 : ey3_st2);
    wire [22:0] my;
    assign my = is_zero ? 8'b0 : (is_inf ? 8'b0 : my1);

// stage 3
    always @(posedge clk) begin
        y <= {sy, ey, my};
    end

endmodule

`default_nettype wire